//
//  ArtworkLoader.swift
//  SwiftRadioCore
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import Foundation
import UIKit

/// Resolves station and track images with bounded decoded caching over URLSession's HTTP cache.
public actor ArtworkLoader {
    private let session: URLSession
    private let placeholderName: String
    private let bundle: Bundle
    private let cache = NSCache<NSString, UIImage>()
    /// One download per URL while it runs. The lock screen, backdrop and foreground artwork ask
    /// for the same track at once; sharing the request keeps them from resolving differently.
    /// Each download counts its callers, and the last one to cancel cancels it.
    private var inFlight: [String: Download] = [:]
    private var nextDownloadID = 0

    private struct Download {
        let id: Int
        let task: Task<UIImage?, Never>
        var waiters: Int
    }

    public init(session: URLSession = .shared, placeholderName: String = "stationImage", bundle: Bundle = .main) {
        self.session = session
        self.placeholderName = placeholderName
        self.bundle = bundle
        cache.countLimit = 100
        cache.totalCostLimit = 32 * 1_024 * 1_024
    }

    /// Callers must compare station.id with their current selection after awaiting the result.
    public func image(for station: RadioStation) async -> UIImage {
        switch station.artworkSource {
        case .asset(let name): return asset(named: name) ?? placeholder()
        case .remote(let url): return await trackArtwork(at: url) ?? placeholder()
        case .placeholder: return placeholder()
        }
    }

    /// The URL is the request identity; a caller must discard results for obsolete metadata URLs.
    /// Cancelling one caller leaves a shared download running for the others; cancelling the last
    /// one cancels the download, so abandoned artwork does not keep loading until it times out.
    public func trackArtwork(at url: URL) async -> UIImage? {
        let key = "remote:\(url.absoluteString)"
        if let image = cache.object(forKey: key as NSString) { return image }
        let task: Task<UIImage?, Never>
        let id: Int
        if let pending = inFlight[key] {
            (task, id) = (pending.task, pending.id)
            inFlight[key]?.waiters += 1
        } else {
            nextDownloadID += 1
            let newID = nextDownloadID
            task = Task { [session] in
                let image = await Self.download(url, session: session)
                // Runs on the actor: a failure is not cached, so a later request retries.
                if inFlight[key]?.id == newID { inFlight[key] = nil }
                if let image { insert(image, for: key as NSString) }
                return image
            }
            id = newID
            inFlight[key] = Download(id: id, task: task, waiters: 1)
        }
        return await withTaskCancellationHandler {
            await task.value
        } onCancel: {
            Task { await self.waiterCancelled(key: key, id: id) }
        }
    }

    private func waiterCancelled(key: String, id: Int) {
        guard var download = inFlight[key], download.id == id else { return }
        download.waiters -= 1
        if download.waiters > 0 {
            inFlight[key] = download
        } else {
            inFlight[key] = nil
            download.task.cancel()
        }
    }

    private static func download(_ url: URL, session: URLSession) async -> UIImage? {
        guard let (data, response) = try? await session.data(from: url) else { return nil }
        if let response = response as? HTTPURLResponse, !(200..<300).contains(response.statusCode) { return nil }
        return UIImage(data: data)
    }

    private func asset(named name: String) -> UIImage? {
        let key = "asset:\(name)" as NSString
        if let image = cache.object(forKey: key) { return image }
        guard let image = UIImage(named: name, in: bundle, compatibleWith: nil) else { return nil }
        insert(image, for: key)
        return image
    }

    private func placeholder() -> UIImage {
        asset(named: placeholderName) ?? UIImage(systemName: "radio") ?? UIImage()
    }

    private func insert(_ image: UIImage, for key: NSString) {
        let cost = image.cgImage.map { $0.bytesPerRow * $0.height } ?? 0
        cache.setObject(image, forKey: key, cost: cost)
    }
}
