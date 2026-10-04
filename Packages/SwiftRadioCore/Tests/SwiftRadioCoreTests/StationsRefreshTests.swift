//
//  StationsRefreshTests.swift
//  SwiftRadioCoreTests
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import Testing
@testable import SwiftRadioCore

/// Verifies late or cancelled requests cannot overwrite the latest catalog state.
@MainActor struct StationsRefreshTests {
    @Test func latestRequestWins() async throws {
        let loader = ControlledStationsLoader()
        let store = StationsStore(loader: loader, player: PlayerServiceTests.service())
        let stations = try RadioStationTests.fixtures()
        let first = Task { await store.load() }
        await loader.waitForRequests(1)
        let second = Task { await store.refresh() }
        await loader.waitForRequests(2)
        await loader.finish(1, with: Array(stations.prefix(1)))
        await second.value
        await loader.finish(0, with: stations)
        await first.value
        #expect(store.stations == Array(stations.prefix(1)))
        #expect(store.loadState == .loaded)
    }

    @Test func cancellationRestoresIdle() async throws {
        let loader = ControlledStationsLoader()
        let store = StationsStore(loader: loader, player: PlayerServiceTests.service())
        let request = Task { await store.load() }
        await loader.waitForRequests(1)
        request.cancel()
        await loader.finish(0, with: try RadioStationTests.fixtures())
        await request.value
        #expect(store.loadState == .idle)
        #expect(store.stations.isEmpty)
    }
}
