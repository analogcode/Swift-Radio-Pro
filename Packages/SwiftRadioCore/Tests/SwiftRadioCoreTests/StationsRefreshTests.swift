//
//  StationsRefreshTests.swift
//  SwiftRadioCoreTests
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import MediaPlayer
import Observation
import Testing
import UIKit
@testable import SwiftRadioCore

/// Verifies late or cancelled requests cannot overwrite the latest catalog state.
@MainActor struct StationsRefreshTests {
    @Test(arguments: ["description", "artwork", "website"], [false, true])
    func selectedMetadataRefreshPreservesPlayback(field: String, paused: Bool) async throws {
        let stations = try RadioStationTests.fixtures()
        let loader = FakeStationsLoader(stations: stations)
        let engine = FakeRadioPlayer(fidelity: .vendor)
        var info: [String: Any]?
        var publications = 0
        let player = PlayerService(player: engine,
                                   nowPlaying: NowPlayingInfoPublisher(publish: { info = $0; publications += 1 }),
                                   remoteCommands: RemoteCommandsController(handler: FakeRemoteCommandHandler()),
                                   activateAudioSession: nil)
        let store = StationsStore(loader: loader, player: player)
        await store.load()
        store.select(stations[0])
        engine.announceDuration(180)
        player.playerStateDidChange(.readyToPlay)
        player.playTimeDidChange(42, duration: 180)
        if paused { player.pause() }
        let artwork = try #require(UIImage(named: "Fixtures/station", in: .module, compatibleWith: nil))
        player.updateArtwork(artwork, for: stations[0].id, artworkURL: nil)
        let calls = engine.calls
        let loadedURLs = engine.loadedURLs
        var updated = stations
        switch field {
        case "description": updated[0].desc = "Updated tagline"; updated[0].longDesc = "Updated details"
        case "artwork": updated[0].imageURL = "https://example.com/new-artwork.png"
        default: updated[0].website = "https://example.com/new-website"
        }
        let catalogChanges = ObservationCounter()
        let selectionChanges = ObservationCounter()
        withObservationTracking { _ = store.stations } onChange: { catalogChanges.increment() }
        withObservationTracking { _ = store.currentStation } onChange: { selectionChanges.increment() }
        await loader.replace(with: updated)
        await store.refresh()

        #expect(catalogChanges.value == 1)
        #expect(selectionChanges.value == 1)
        let selected = try #require(store.currentStation)
        #expect(selected.id == updated[0].id)
        #expect(selected.desc == updated[0].desc)
        #expect(selected.longDesc == updated[0].longDesc)
        #expect(selected.imageURL == updated[0].imageURL)
        #expect(selected.website == updated[0].website)
        #expect(store.stations[0].website == updated[0].website)
        #expect(store.stations[0].imageURL == updated[0].imageURL)
        #expect(engine.calls == calls)
        #expect(engine.loadedURLs == loadedURLs)
        #expect(player.state == (paused ? .paused : .playing))
        #expect(player.elapsed == 42)
        #expect(player.duration == 180)
        #expect(info?[MPMediaItemPropertyTitle] as? String == updated[0].name)
        #expect(info?[MPMediaItemPropertyArtist] as? String == updated[0].desc)
        let retainedArtwork = try #require(info?[MPMediaItemPropertyArtwork] as? MPMediaItemArtwork)
        #expect(retainedArtwork.bounds.size == artwork.size)

        let changes = ObservationCounter()
        withObservationTracking { _ = store.stations; _ = store.currentStation } onChange: { changes.increment() }
        let before = publications
        await store.refresh()
        #expect(changes.value == 0)
        #expect(publications == before)
        #expect(store.selectNext())
        #expect(store.currentStation?.id == stations[1].id)
        #expect(store.selectPrevious())
        #expect(store.currentStation?.id == updated[0].id)
        #expect(store.currentStation?.desc == updated[0].desc)
        #expect(store.currentStation?.website == updated[0].website)
    }

    @Test func metadataRefreshKeepsTrackArtworkAndPendingSeek() async throws {
        let stations = try RadioStationTests.fixtures()
        let loader = FakeStationsLoader(stations: stations)
        let engine = FakeRadioPlayer(fidelity: .vendor)
        engine.completesSeeksImmediately = false
        var info: [String: Any]?
        let player = PlayerService(player: engine, nowPlaying: NowPlayingInfoPublisher(publish: { info = $0 }),
                                   remoteCommands: RemoteCommandsController(handler: FakeRemoteCommandHandler()),
                                   activateAudioSession: nil)
        let store = StationsStore(loader: loader, player: player)
        await store.load()
        store.select(stations[0])
        engine.announceDuration(180)
        player.metadataDidChange(artist: "Artist", track: "Track")
        let artworkURL = try #require(URL(string: "https://example.com/track.png"))
        player.artworkDidChange(artworkURL)
        let artwork = try #require(UIImage(named: "Fixtures/placeholder", in: .module, compatibleWith: nil))
        player.updateArtwork(artwork, for: stations[0].id, artworkURL: artworkURL)
        player.seek(to: 90)
        let calls = engine.calls
        var updated = stations
        updated[0].imageURL = "new-station-artwork"
        updated[0].desc = "New description"
        await loader.replace(with: updated)
        await store.refresh()
        #expect(engine.calls == calls)
        #expect(player.isSeeking)
        #expect(player.elapsed == 90)
        #expect(player.track == "Track")
        #expect(player.artist == "Artist")
        #expect(player.artworkURL == artworkURL)
        let retainedArtwork = try #require(info?[MPMediaItemPropertyArtwork] as? MPMediaItemArtwork)
        #expect(retainedArtwork.bounds.size == artwork.size)
        engine.pendingSeeks.removeFirst()()
        #expect(!player.isSeeking)
        #expect(player.state == .playing)
    }

    @Test func websiteOnlyEditToAnotherStationUpdatesCatalogWithoutChangingSelection() async throws {
        var stations = try RadioStationTests.fixtures()
        let loader = FakeStationsLoader(stations: stations)
        let store = StationsStore(loader: loader, player: PlayerServiceTests.service())
        await store.load()
        store.select(stations[0])
        let changes = ObservationCounter()
        withObservationTracking { _ = store.currentStation } onChange: { changes.increment() }
        stations[1].website = "https://example.com/updated"
        await loader.replace(with: stations)
        await store.refresh()
        #expect(store.stations[1].website == stations[1].website)
        #expect(changes.value == 0)
    }

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
