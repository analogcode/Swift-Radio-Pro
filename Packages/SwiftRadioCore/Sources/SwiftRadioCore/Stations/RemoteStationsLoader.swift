//
//  RemoteStationsLoader.swift
//  SwiftRadioCore
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import Foundation

/// Fetches fresh station JSON, bypassing the local HTTP cache on each refresh.
public struct RemoteStationsLoader: StationsLoader {
    public var url: URL
    public var session: URLSession
    public init(url: URL, session: URLSession = .shared) {
        self.url = url
        self.session = session
    }

    public func load() async throws -> [RadioStation] {
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        let (data, response) = try await session.data(for: request)
        if let response = response as? HTTPURLResponse, !(200..<300).contains(response.statusCode) {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(StationsResponse.self, from: data).station
    }
}
