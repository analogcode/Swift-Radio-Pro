//
//  RemoteCommandsControllerTests.swift
//  SwiftRadioCoreTests
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import MediaPlayer
import Testing
@testable import SwiftRadioCore

/// Ensures command callbacks hop to the main actor and registrations are removed.
@MainActor struct RemoteCommandsControllerTests {
    @Test func enablementRebindingAndUnbind() {
        let handler = FakeRemoteCommandHandler()
        let controller = RemoteCommandsController(handler: handler)
        #expect(handler.enabled[.pause] == true)
        #expect(handler.enabled[.stop] == false)
        controller.bind(play: { .success }, pause: { .success }, stop: { .success },
                        toggle: { .success }, next: { .success }, previous: { .success })
        #expect(handler.handlers.count == 6)
        #expect(handler.beginCount == 1)
        controller.updateLiveState(isLive: true)
        #expect(handler.enabled[.pause] == false)
        #expect(handler.enabled[.stop] == true)
        controller.bind(play: { .success }, pause: { .success }, stop: { .success },
                        toggle: { .success }, next: { .success }, previous: { .success })
        #expect(handler.enabled[.pause] == false)
        #expect(handler.enabled[.stop] == true)
        controller.updateLiveState(isLive: false)
        #expect(handler.enabled[.pause] == true)
        #expect(handler.removedCount == 6)
        controller.unbind()
        #expect(handler.handlers.isEmpty)
        #expect(handler.removedCount == 12)
    }

    @Test func backgroundCallbackReportsTheActionStatus() async throws {
        let handler = FakeRemoteCommandHandler()
        let controller = RemoteCommandsController(handler: handler)
        let runs = ObservationCounter()
        controller.bind(play: { runs.increment(); return .commandFailed }, pause: { .success },
                        stop: { .success }, toggle: { .success }, next: { .success }, previous: { .success })
        let callback = try #require(handler.handlers[.play])
        // Read the status back here: a detached task does not carry this test's context, so an
        // expectation inside it could be attributed to no test at all.
        let (status, ranOffMain) = await Task.detached { Self.callReportingThread(callback) }.value
        #expect(ranOffMain)
        #expect(status == .commandFailed)
        #expect(runs.value == 1) // Ran before the callback returned, not on a later turn.
    }

    nonisolated private static func callReportingThread(_ callback: @Sendable () -> MPRemoteCommandHandlerStatus)
        -> (MPRemoteCommandHandlerStatus, Bool) {
        (callback(), !Thread.isMainThread)
    }

    /// MediaPlayer can call a target off the main thread; the system must still learn whether the
    /// command did anything. Without a selection every command is rejected; with a single station
    /// Next and Previous have nowhere to go and must not claim success.
    @Test(arguments: [0, 1]) func backgroundCommandsReportWhatHappened(catalogSize: Int) async throws {
        let stations = Array(try RadioStationTests.fixtures().prefix(catalogSize))
        let engine = FakeRadioPlayer()
        let player = PlayerServiceTests.service(engine)
        let store = StationsStore(loader: FakeStationsLoader(stations: stations), player: player)
        await store.load()
        let handler = FakeRemoteCommandHandler()
        let controller = RemoteCommandsController(handler: handler)
        controller.bind(player: player, stations: store)
        if let only = stations.first { store.select(only) }
        let selected = store.currentStation
        let expected: [RemoteCommand: MPRemoteCommandHandlerStatus] = catalogSize == 0
            ? Dictionary(uniqueKeysWithValues: RemoteCommand.allCases.map { ($0, .noActionableNowPlayingItem) })
            : [.play: .success, .pause: .success, .stop: .success, .toggle: .success,
               .next: .noSuchContent, .previous: .noSuchContent]
        for command in [RemoteCommand.next, .previous, .pause, .play, .stop, .toggle] {
            let callback = try #require(handler.handlers[command])
            let status = await Task.detached { callback() }.value
            #expect(status == expected[command], "\(command)")
            #expect(store.currentStation == selected, "\(command)")
        }
        if catalogSize == 0 { #expect(engine.calls.isEmpty) } else { #expect(engine.calls.last == "play") }
    }

    /// `bind` pairs commands with actions positionally; reordering either list would silently send
    /// the lock screen's Pause to Stop, so every command must reach its own action.
    @Test func bindMapsEveryCommandToItsOwnAction() throws {
        let handler = FakeRemoteCommandHandler()
        let controller = RemoteCommandsController(handler: handler)
        var ran: [String] = []
        controller.bind(play: { ran.append("play"); return .success },
                        pause: { ran.append("pause"); return .success },
                        stop: { ran.append("stop"); return .success },
                        toggle: { ran.append("toggle"); return .success },
                        next: { ran.append("next"); return .success },
                        previous: { ran.append("previous"); return .success })
        let expected: [(RemoteCommand, String)] = [(.play, "play"), (.pause, "pause"), (.stop, "stop"),
                                                   (.toggle, "toggle"), (.next, "next"), (.previous, "previous")]
        #expect(Set(handler.handlers.keys) == Set(RemoteCommand.allCases))
        for (command, name) in expected {
            ran.removeAll()
            let callback = try #require(handler.handlers[command])
            _ = callback()
            #expect(ran == [name], "\(command)")
        }
    }

    /// Live streams can only stop (a paused live stream would resume behind real time), files can
    /// only pause; everything else stays enabled in both.
    @Test(arguments: [true, false]) func enablementTableForLiveAndFile(isLive: Bool) {
        let handler = FakeRemoteCommandHandler()
        let controller = RemoteCommandsController(handler: handler)
        controller.bind(play: { .success }, pause: { .success }, stop: { .success },
                        toggle: { .success }, next: { .success }, previous: { .success })
        controller.updateLiveState(isLive: isLive)
        let expected: [RemoteCommand: Bool] = [.play: true, .pause: !isLive, .stop: isLive,
                                               .toggle: true, .next: true, .previous: true]
        #expect(handler.enabled == expected)
    }

    /// The service drives the table from the engine's duration, including the flip back when a
    /// file is replaced by a live stream.
    @Test func serviceDurationDrivesCommandEnablement() throws {
        let engine = FakeRadioPlayer(fidelity: .vendor)
        let handler = FakeRemoteCommandHandler()
        let controller = RemoteCommandsController(handler: handler)
        let service = PlayerService(player: engine, nowPlaying: NowPlayingInfoPublisher(publish: { _ in }),
                                    remoteCommands: controller, activateAudioSession: nil)
        controller.bind(play: { .success }, pause: { .success }, stop: { .success },
                        toggle: { .success }, next: { .success }, previous: { .success })
        let stations = try RadioStationTests.fixtures()
        service.updateStation(stations[0])
        service.load(url: try #require(URL(string: stations[0].streamURL)))
        #expect(handler.enabled[.stop] == true)
        #expect(handler.enabled[.pause] == false)
        engine.announceDuration(180)
        #expect(handler.enabled[.stop] == false)
        #expect(handler.enabled[.pause] == true)
        service.updateStation(stations[1])
        service.load(url: try #require(URL(string: stations[1].streamURL)))
        #expect(handler.enabled[.stop] == true)
        #expect(handler.enabled[.pause] == false)
    }

    /// Once the catalog drops the playing station there is nothing to act on: the engine was
    /// unloaded, and a remote command must neither resume it nor pick a new station.
    @Test func commandsAfterTheCatalogDropsTheStationAreRejected() async throws {
        let stations = try RadioStationTests.fixtures()
        let engine = FakeRadioPlayer(fidelity: .vendor)
        let player = PlayerServiceTests.service(engine)
        let loader = FakeStationsLoader(stations: stations)
        let store = StationsStore(loader: loader, player: player)
        await store.load()
        let handler = FakeRemoteCommandHandler()
        let controller = RemoteCommandsController(handler: handler)
        controller.bind(player: player, stations: store)
        store.select(stations[2])
        await loader.replace(with: stations.filter { $0 != stations[2] })
        await store.refresh()
        #expect(store.currentStation == nil)
        #expect(engine.radioURL == nil)
        let calls = engine.calls
        for command in RemoteCommand.allCases {
            let callback = try #require(handler.handlers[command])
            #expect(callback() == .noActionableNowPlayingItem, "\(command)")
        }
        #expect(engine.calls == calls)
        #expect(store.currentStation == nil)
        #expect(!engine.isPlaying)
    }

    /// The controller outlives neither the player nor the catalog it was bound to.
    @Test func commandsAfterTheBoundObjectsAreGoneAreRejected() async throws {
        let handler = FakeRemoteCommandHandler()
        let controller = RemoteCommandsController(handler: handler)
        do {
            let player = PlayerServiceTests.service(FakeRadioPlayer())
            let store = StationsStore(loader: FakeStationsLoader(stations: try RadioStationTests.fixtures()), player: player)
            await store.load()
            store.select(store.stations[0])
            controller.bind(player: player, stations: store)
            let pause = try #require(handler.handlers[.pause])
            #expect(pause() == .success)
        }
        for command in RemoteCommand.allCases {
            let callback = try #require(handler.handlers[command])
            #expect(callback() == .noActionableNowPlayingItem, "\(command)")
        }
    }

    @Test func mainThreadCallbackReportsTheActionStatus() {
        let handler = FakeRemoteCommandHandler()
        let controller = RemoteCommandsController(handler: handler)
        let runs = ObservationCounter()
        controller.bind(play: { runs.increment(); return .noActionableNowPlayingItem }, pause: { .success },
                        stop: { .success }, toggle: { .success }, next: { .success }, previous: { .success })
        #expect(handler.handlers[.play]!() == .noActionableNowPlayingItem)
        #expect(runs.value == 1)
    }

    /// Headset, lock screen and steering-wheel commands must not start the radio from nothing:
    /// UIKit's setNext/setPrevious ignored a missing selection, and the system is told why.
    @Test func commandsWithoutASelectionAreRejectedAndDoNothing() async throws {
        let stations = try RadioStationTests.fixtures()
        let engine = FakeRadioPlayer()
        let player = PlayerServiceTests.service(engine)
        let store = StationsStore(loader: FakeStationsLoader(stations: stations), player: player)
        await store.load()
        let handler = FakeRemoteCommandHandler()
        let controller = RemoteCommandsController(handler: handler)
        controller.bind(player: player, stations: store)
        for command in RemoteCommand.allCases {
            #expect(handler.handlers[command]!() == .noActionableNowPlayingItem)
        }
        #expect(store.currentStation == nil)
        #expect(engine.radioURL == nil)
        #expect(engine.calls.isEmpty)

        store.select(stations[0])
        #expect(handler.handlers[.next]!() == .success)
        #expect(store.currentStation == stations[1])
        #expect(handler.handlers[.previous]!() == .success)
        #expect(store.currentStation == stations[0])
        #expect(handler.handlers[.pause]!() == .success)
        #expect(engine.calls.last == "pause")
        #expect(handler.handlers[.play]!() == .success)
        #expect(engine.calls.last == "play")
        #expect(handler.handlers[.stop]!() == .success)
        #expect(engine.calls.last == "stop")
        #expect(handler.handlers[.toggle]!() == .success)
        #expect(engine.calls.last == "play")
    }

    @Test func deinitRemovesHandlers() {
        let handler = FakeRemoteCommandHandler()
        var controller: RemoteCommandsController? = RemoteCommandsController(handler: handler)
        controller?.bind(play: { .success }, pause: { .success }, stop: { .success },
                         toggle: { .success }, next: { .success }, previous: { .success })
        controller = nil
        #expect(handler.handlers.isEmpty)
    }
}
