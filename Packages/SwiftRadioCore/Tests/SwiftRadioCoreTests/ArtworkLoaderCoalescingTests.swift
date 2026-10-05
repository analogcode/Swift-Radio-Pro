//
//  ArtworkLoaderCoalescingTests.swift
//  SwiftRadioCoreTests
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import Foundation
import os
import Testing
import UIKit
@testable import SwiftRadioCore

/// Concurrent requests for one artwork URL share a single download, so the lock screen,
/// the backdrop and the foreground artwork cannot resolve differently for the same track.
struct ArtworkLoaderCoalescingTests {
    @Test func concurrentRequestsForOneURLShareOneDownload() async throws {
        let url = CountingURLProtocol.url()
        let loader = ArtworkLoader(session: CountingURLProtocol.session())
        async let first = loader.trackArtwork(at: url)
        async let second = loader.trackArtwork(at: url)
        async let third = loader.trackArtwork(at: url)
        let images = await [first, second, third]
        let image = try #require(images[0])
        #expect(images.allSatisfy { $0 === image })
        #expect(CountingURLProtocol.requestCount(for: url) == 1)
    }

    @Test func failedDownloadIsNotSharedWithLaterRequests() async {
        let url = CountingURLProtocol.url(failing: true)
        let loader = ArtworkLoader(session: CountingURLProtocol.session())
        #expect(await loader.trackArtwork(at: url) == nil)
        #expect(await loader.trackArtwork(at: url) == nil)
        #expect(CountingURLProtocol.requestCount(for: url) == 2)
    }

    /// Rapid station changes and CarPlay disconnects cancel their artwork tasks. A shared
    /// download must keep running while anyone still waits, and stop once nobody does.
    @Test func lastCancelledWaiterCancelsTheSharedDownload() async throws {
        let url = BlockingURLProtocol.url()
        let loader = ArtworkLoader(session: BlockingURLProtocol.session())
        let first = Task { await loader.trackArtwork(at: url) }
        let second = Task { await loader.trackArtwork(at: url) }
        try await BlockingURLProtocol.wait { $0.started(url) == 1 }
        first.cancel()
        try await Task.sleep(for: .milliseconds(200))
        #expect(BlockingURLProtocol.stopped(url) == 0)
        BlockingURLProtocol.respond(url)
        #expect(await second.value != nil) // The remaining waiter still gets the image.
        _ = await first.value

        let abandoned = BlockingURLProtocol.url()
        let third = Task { await loader.trackArtwork(at: abandoned) }
        let fourth = Task { await loader.trackArtwork(at: abandoned) }
        try await BlockingURLProtocol.wait { $0.started(abandoned) == 1 }
        third.cancel()
        fourth.cancel()
        try await BlockingURLProtocol.wait { $0.stopped(abandoned) == 1 }
        #expect(await third.value == nil)
        #expect(await fourth.value == nil)
        let retry = Task { await loader.trackArtwork(at: abandoned) } // A later request starts over.
        try await BlockingURLProtocol.wait { $0.started(abandoned) == 2 }
        retry.cancel()
        _ = await retry.value
    }
}

/// Holds every request until the test responds, and records starts and stops per URL.
private final class BlockingURLProtocol: URLProtocol, @unchecked Sendable {
    struct Log {
        var startCounts: [URL: Int] = [:]
        var stopCounts: [URL: Int] = [:]
        var open: [URL: [BlockingURLProtocol]] = [:]
        func started(_ url: URL) -> Int { startCounts[url, default: 0] }
        func stopped(_ url: URL) -> Int { stopCounts[url, default: 0] }
    }
    private static let log = OSAllocatedUnfairLock(initialState: Log())

    static func url() -> URL { URL(string: "https://example.com/blocking/\(UUID().uuidString)")! }
    static func started(_ url: URL) -> Int { log.withLock { $0.started(url) } }
    static func stopped(_ url: URL) -> Int { log.withLock { $0.stopped(url) } }

    static func session() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [Self.self]
        configuration.urlCache = nil
        return URLSession(configuration: configuration)
    }

    /// Polls for up to two seconds; cancellation reaches the protocol on URLSession's own queue.
    static func wait(until condition: @Sendable (Log) -> Bool,
                     sourceLocation: SourceLocation = #_sourceLocation) async throws {
        for _ in 0..<200 {
            if log.withLock({ condition($0) }) { return }
            try await Task.sleep(for: .milliseconds(10))
        }
        Issue.record("Timed out waiting for the URL protocol", sourceLocation: sourceLocation)
    }

    static func respond(_ url: URL) {
        let requests = log.withLock { $0.open.removeValue(forKey: url) ?? [] }
        let data = try! Data(contentsOf: Bundle.module.url(forResource: "station", withExtension: "png",
                                                           subdirectory: "Fixtures")!)
        for request in requests {
            request.client?.urlProtocol(request, didReceive: HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil,
                                                                             headerFields: nil)!,
                                        cacheStoragePolicy: .notAllowed)
            request.client?.urlProtocol(request, didLoad: data)
            request.client?.urlProtocolDidFinishLoading(request)
        }
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url else { return }
        Self.log.withLock {
            $0.startCounts[url, default: 0] += 1
            $0.open[url, default: []].append(self)
        }
    }

    override func stopLoading() {
        guard let url = request.url else { return }
        Self.log.withLock {
            $0.stopCounts[url, default: 0] += 1
            $0.open[url]?.removeAll { $0 === self }
        }
    }
}

/// Answers after a short delay so concurrent callers overlap, and counts requests per URL.
/// Each test uses its own URL, so parallel tests do not share counts.
private final class CountingURLProtocol: URLProtocol, @unchecked Sendable {
    private static let counts = OSAllocatedUnfairLock(initialState: [URL: Int]())

    static func url(failing: Bool = false) -> URL {
        URL(string: "https://example.com/\(failing ? "missing" : "image")/\(UUID().uuidString)")!
    }

    static func requestCount(for url: URL) -> Int { counts.withLock { $0[url, default: 0] } }

    static func session() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [Self.self]
        configuration.urlCache = nil
        return URLSession(configuration: configuration)
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url else { return }
        Self.counts.withLock { $0[url, default: 0] += 1 }
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.3) { [self] in
            let status = url.pathComponents.contains("missing") ? 404 : 200
            let data = try! Data(contentsOf: Bundle.module.url(forResource: "station", withExtension: "png",
                                                               subdirectory: "Fixtures")!)
            client?.urlProtocol(self, didReceive: HTTPURLResponse(url: url, statusCode: status, httpVersion: nil,
                                                                  headerFields: nil)!,
                                cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        }
    }

    override func stopLoading() {}
}
