//
//  StationsStoreTests.swift
//  SwiftRadioCoreTests
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import Foundation
import Observation
import Testing
@testable import SwiftRadioCore

/// Covers loading, unchanged-list suppression, selection, search, and refresh removal.
@MainActor struct StationsStoreTests {
    @Test func loadAndSearch() async throws {
        let stations = try RadioStationTests.fixtures()
        let loader = FakeStationsLoader(stations: stations)
        let store = StationsStore(loader: loader, player: PlayerServiceTests.service())
        #expect(store.loadState == .idle)
        await store.load()
        #expect(store.loadState == .loaded)
        #expect(store.stations == stations)
        store.searchText = "rOcK"
        #expect(store.filteredStations.count == 3)
        store.searchText = " \n "
        #expect(store.filteredStations.count == 6)
        let before = store.stations
        let changes = ObservationCounter()
        withObservationTracking { _ = store.stations } onChange: { changes.increment() }
        await store.load()
        #expect(store.stations == before)
        #expect(changes.value == 0)
        #expect(await loader.loadCount == 2)
    }

    @Test func circularSelectionAndRemovalStopsAudio() async throws {
        let stations = try RadioStationTests.fixtures()
        let loader = FakeStationsLoader(stations: stations)
        let engine = FakeRadioPlayer()
        let player = PlayerServiceTests.service(engine)
        let store = StationsStore(loader: loader, player: player)
        await store.load()
        store.select(stations[5])
        store.selectNext()
        #expect(store.currentStation == stations[0])
        #expect(engine.radioURL == URL(string: stations[0].streamURL))
        store.selectPrevious()
        #expect(store.currentStation == stations[5])
        await loader.replace(with: Array(stations.dropLast()))
        await store.refresh()
        #expect(store.currentStation == nil)
        #expect(engine.calls.last == "stop")
        // Stopping alone leaves the removed stream loaded; a late remote Play would resume it.
        #expect(engine.radioURL == nil)
        let callsAfterRemoval = engine.calls.count
        player.play()
        #expect(engine.calls.count == callsAfterRemoval)
        #expect(player.state == .stopped)
    }

    @Test func bundleLoaderUsesFixtureBundle() async throws {
        let loader = BundleStationsLoader(fileName: "Fixtures/stations", bundle: .module)
        #expect(try await loader.load().count == 6)
    }

    @Test func emptyListSelectionIsSafe() async {
        let store = StationsStore(loader: FakeStationsLoader(stations: []), player: PlayerServiceTests.service())
        await store.load()
        store.selectNext()
        store.selectPrevious()
        #expect(store.currentStation == nil)
    }
}
