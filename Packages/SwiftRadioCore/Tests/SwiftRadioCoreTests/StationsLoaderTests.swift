//
//  StationsLoaderTests.swift
//  SwiftRadioCoreTests
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import Foundation
import Testing
@testable import SwiftRadioCore

/// Checks remote cache policy, decoding failures, HTTP errors, and store error propagation.
@MainActor struct StationsLoaderTests {
    @Test func remoteBypassesCache() async throws {
        let loader = RemoteStationsLoader(url: URL(string: "https://example.com/policy")!, session: StubURLProtocol.session())
        #expect(try await loader.load().count == 6)
    }

    @Test(arguments: ["offline", "invalid", "missing"])
    func failuresReachStore(path: String) async {
        let loader = RemoteStationsLoader(url: URL(string: "https://example.com/\(path)")!, session: StubURLProtocol.session())
        let store = StationsStore(loader: loader, player: PlayerServiceTests.service())
        await store.load()
        guard case .failed = store.loadState else {
            Issue.record("Expected failed load state")
            return
        }
        #expect(store.stations.isEmpty)
    }
}
