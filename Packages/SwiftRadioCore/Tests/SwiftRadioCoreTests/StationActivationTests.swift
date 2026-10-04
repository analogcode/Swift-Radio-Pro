//
//  StationActivationTests.swift
//  SwiftRadioCoreTests
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import Foundation
import Testing
@testable import SwiftRadioCore

/// Covers the row-tap contract on the phone and in the car (re-tapping the current station in every
/// transport state, unusable stream URLs) and stepping past unusable entries with Next/Previous.
@MainActor struct StationActivationTests {
    private static func store(_ stations: [RadioStation], engine: FakeRadioPlayer) async -> (StationsStore, PlayerService) {
        let player = PlayerServiceTests.service(engine)
        let store = StationsStore(loader: FakeStationsLoader(stations: stations), player: player)
        await store.load()
        return (store, player)
    }

    private static func unusable(_ name: String) -> RadioStation {
        // No scheme: URL(string:) succeeds but the engine cannot open it.
        RadioStation(name: name, streamURL: "stream.example.com/live", imageURL: "", desc: "")
    }

    @Test(arguments: StationsStore.ActivationSurface.allCases) func activatingADifferentStationSelectsIt(surface: StationsStore.ActivationSurface) async throws {
        let stations = try RadioStationTests.fixtures()
        let engine = FakeRadioPlayer()
        let (store, player) = await Self.store(stations, engine: engine)
        store.activate(stations[0], on: surface)
        player.playbackStateDidChange(.playing)
        #expect(store.activate(stations[1], on: surface) == .selected)
        #expect(store.currentStation == stations[1])
        #expect(engine.radioURL == URL(string: stations[1].streamURL))
    }

    @Test(arguments: StationsStore.ActivationSurface.allCases) func activatingThePlayingStationLeavesTheStreamAlone(surface: StationsStore.ActivationSurface) async throws {
        let stations = try RadioStationTests.fixtures()
        let engine = FakeRadioPlayer()
        let (store, player) = await Self.store(stations, engine: engine)
        #expect(store.activate(stations[1], on: surface) == .selected)
        player.playbackStateDidChange(.playing)
        let calls = engine.calls
        #expect(store.activate(stations[1], on: surface) == .alreadyActive)
        #expect(engine.calls == calls)
        #expect(engine.radioURL == URL(string: stations[1].streamURL))
    }

    /// FRadioPlayer's autoplay flips it to playing inside the `radioURL` setter, so a stream that is
    /// still buffering already reads as playing: a second tap opens the player on the phone (as
    /// UIKit's MainCoordinator does) and is ignored in the car. Nothing is restarted or cancelled.
    @Test(arguments: StationsStore.ActivationSurface.allCases) func activatingTheBufferingStation(surface: StationsStore.ActivationSurface) async throws {
        let stations = try RadioStationTests.fixtures()
        let engine = FakeRadioPlayer(fidelity: .vendor)
        let (store, player) = await Self.store(stations, engine: engine)
        #expect(store.activate(stations[2], on: surface) == .selected)
        #expect(player.isBuffering)
        #expect(player.state == .playing)
        let calls = engine.calls
        #expect(store.activate(stations[2], on: surface) == .alreadyActive)
        #expect(engine.calls == calls)
        #expect(engine.radioURL == URL(string: stations[2].streamURL))
    }

    /// Before the engine gets the stream (the audio session is still activating) the station is
    /// idle and loading. The car leaves it alone; the phone toggles like UIKit, so a second tap
    /// cancels the pending start. A CarPlay-only selection goes through the same activation.
    @Test(arguments: StationsStore.ActivationSurface.allCases) func activatingWhileTheSessionActivates(surface: StationsStore.ActivationSurface) async throws {
        let stations = try RadioStationTests.fixtures()
        let engine = FakeRadioPlayer(fidelity: .vendor)
        let gate = ActivationGate()
        let player = PlayerServiceTests.gated(engine, gate: gate)
        let store = StationsStore(loader: FakeStationsLoader(stations: stations), player: player)
        await store.load()
        #expect(store.activate(stations[2], on: .carPlay) == .selected)
        await gate.waitForPending(1)
        #expect(engine.loadedURLs.isEmpty)
        #expect(player.state == .idle)
        #expect(player.isBuffering)
        switch surface {
        case .carPlay:
            #expect(store.activate(stations[2], on: surface) == .alreadyActive)
        case .phone:
            #expect(store.activate(stations[2], on: surface) == .paused)
            #expect(player.state == .stopped)
        }
        gate.release()
        await player.activation?.value
        #expect(engine.loadedURLs == (surface == .carPlay ? [URL(string: stations[2].streamURL)] : []))
        #expect(player.state == (surface == .carPlay ? .playing : .stopped))
    }

    @Test(arguments: StationsStore.ActivationSurface.allCases, [false, true])
    func activatingThePausedOrStoppedStationResumesWithoutReloading(surface: StationsStore.ActivationSurface, stopped: Bool) async throws {
        let stations = try RadioStationTests.fixtures()
        let engine = FakeRadioPlayer()
        let (store, player) = await Self.store(stations, engine: engine)
        store.activate(stations[0], on: surface)
        player.playbackStateDidChange(.playing)
        if stopped { player.stop() } else { player.pause() }
        engine.radioURL = URL(string: "sentinel://unchanged")
        let calls = engine.calls
        #expect(store.activate(stations[0], on: surface) == .resumed)
        #expect(engine.calls == calls + ["play"])
        #expect(player.state == .playing)
        #expect(engine.radioURL == URL(string: "sentinel://unchanged"))
    }

    @Test(arguments: StationsStore.ActivationSurface.allCases) func activatingAFailedStationReloadsIt(surface: StationsStore.ActivationSurface) async throws {
        let stations = try RadioStationTests.fixtures()
        let engine = FakeRadioPlayer()
        let (store, player) = await Self.store(stations, engine: engine)
        store.activate(stations[0], on: surface)
        player.playerStateDidChange(.failed("offline"))
        engine.radioURL = nil
        #expect(store.activate(stations[0], on: surface) == .selected)
        #expect(engine.radioURL == URL(string: stations[0].streamURL))
    }

    @Test(arguments: StationsStore.ActivationSurface.allCases) func unusableStationIsNotSelectedAndDoesNotPlayThePreviousOne(surface: StationsStore.ActivationSurface) async throws {
        var stations = try RadioStationTests.fixtures()
        stations.insert(Self.unusable("Broken"), at: 1)
        let engine = FakeRadioPlayer()
        let (store, player) = await Self.store(stations, engine: engine)
        store.activate(stations[0], on: surface)
        player.pause()
        let calls = engine.calls
        #expect(store.select(stations[1]) == false)
        #expect(store.activate(stations[1], on: surface) == .unavailable)
        #expect(store.currentStation == stations[0])
        #expect(engine.calls == calls)
        #expect(engine.radioURL == URL(string: stations[0].streamURL))
    }

    @Test func nextAndPreviousStepOverUnusableStations() async throws {
        var stations = try RadioStationTests.fixtures()
        stations.insert(Self.unusable("Broken A"), at: 1)
        stations.insert(Self.unusable("Broken B"), at: 2)
        let engine = FakeRadioPlayer()
        let (store, _) = await Self.store(stations, engine: engine)
        store.select(stations[0])
        store.selectNext()
        #expect(store.currentStation == stations[3])
        store.selectPrevious()
        #expect(store.currentStation == stations[0])
        store.selectPrevious() // Wraps around to the last usable entry.
        #expect(store.currentStation == stations.last)
    }

    @Test func nextFromNoSelectionPicksTheFirstUsableStation() async throws {
        var stations = try RadioStationTests.fixtures()
        stations.insert(Self.unusable("Broken"), at: 0)
        let (store, _) = await Self.store(stations, engine: FakeRadioPlayer())
        #expect(store.selectNext())
        #expect(store.currentStation == stations[1])
    }

    @Test func nextWithOnlyUnusableNeighboursKeepsTheCurrentStream() async throws {
        let good = try RadioStationTests.fixtures()[0]
        let stations = [good, Self.unusable("Broken A"), Self.unusable("Broken B")]
        let engine = FakeRadioPlayer()
        let (store, _) = await Self.store(stations, engine: engine)
        store.select(good)
        let calls = engine.calls
        engine.radioURL = URL(string: "sentinel://unchanged")
        #expect(store.selectNext() == false)
        #expect(store.selectPrevious() == false)
        #expect(store.currentStation == good)
        #expect(engine.calls == calls)
        #expect(engine.radioURL == URL(string: "sentinel://unchanged"))
    }

    @Test func allUnusableCatalogSelectsNothing() async {
        let stations = [Self.unusable("A"), Self.unusable("B")]
        let (store, _) = await Self.store(stations, engine: FakeRadioPlayer())
        #expect(store.selectNext() == false)
        #expect(store.selectPrevious() == false)
        #expect(store.currentStation == nil)
    }
}
