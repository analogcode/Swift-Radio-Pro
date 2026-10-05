//
//  PlaybackInterruptionTests.swift
//  SwiftRadioCoreTests
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import Foundation
import MediaPlayer
import Testing
@testable import SwiftRadioCore

/// FRadioPlayer 0.4 observes AVAudioSession interruptions and route changes itself and answers
/// with its own play()/pause(), which reach the service only as playback-state events. These tests
/// drive those vendor handlers through the fake and check how the service's transport intent
/// treats them, together with the state the CarPlay list derives its playing badge from.
@MainActor struct PlaybackInterruptionTests {
    private struct Harness {
        let engine: FakeRadioPlayer
        let service: PlayerService
        let stations: StationsStore
        let catalog: [RadioStation]
        let rates: () -> [Float]
    }

    private final class RateLog {
        var rates: [Float] = []
    }

    /// Station 0 is live, station 5 is a file; `isFile` picks which one is playing.
    private static func playing(isFile: Bool = false) async throws -> Harness {
        let engine = FakeRadioPlayer(fidelity: .vendor)
        let log = RateLog()
        let service = PlayerService(player: engine, nowPlaying: NowPlayingInfoPublisher(publish: {
                                        if let rate = $0?[MPNowPlayingInfoPropertyPlaybackRate] as? Float { log.rates.append(rate) }
                                    }),
                                    remoteCommands: RemoteCommandsController(handler: FakeRemoteCommandHandler()),
                                    activateAudioSession: nil)
        let catalog = try RadioStationTests.fixtures()
        let stations = StationsStore(loader: FakeStationsLoader(stations: catalog), player: service)
        await stations.load()
        #expect(stations.activate(catalog[isFile ? 5 : 0], on: .carPlay) == .selected)
        if isFile { engine.announceDuration(180) }
        engine.observer?.playerStateDidChange(.loadingFinished) // The item is ready and playing.
        #expect(service.state == .playing)
        return Harness(engine: engine, service: service, stations: stations, catalog: catalog, rates: { log.rates })
    }

    @Test(arguments: [false, true]) func interruptionPausesThenResumesWhenAsked(isFile: Bool) async throws {
        let h = try await Self.playing(isFile: isFile)
        h.engine.interruptionBegan()
        #expect(h.service.state == .paused)
        #expect(h.rates().last == 0)
        h.engine.interruptionEnded(shouldResume: true)
        #expect(h.service.state == .playing)
        #expect(h.engine.isPlaying)
        #expect(h.rates().last == 1)
    }

    @Test func interruptionEndedWithoutShouldResumeStaysPaused() async throws {
        let h = try await Self.playing()
        h.engine.interruptionBegan()
        h.engine.interruptionEnded(shouldResume: false)
        #expect(h.service.state == .paused)
        #expect(!h.engine.isPlaying)
    }

    /// The supported engine respects a pause or stop across an interruption. The app also rejects
    /// a separately injected unexpected resume, without publishing Playing to lock screen/CarPlay.
    @Test(arguments: [false, true]) func resumeAfterAnExplicitPauseOrStopIsReverted(stop: Bool) async throws {
        let h = try await Self.playing(isFile: !stop)
        if stop { h.service.stop() } else { h.service.pause() }
        let published = h.rates().count
        h.engine.interruptionBegan()
        // The vendor answers the interruption with pause(); a stopped live stream stays stopped.
        #expect(h.service.state == (stop ? .stopped : .paused))
        h.engine.interruptionEnded(shouldResume: true)
        #expect(h.service.state == (stop ? .stopped : .paused))
        #expect(!h.engine.isPlaying)
        #expect(!h.rates().dropFirst(published).contains(1))
        h.engine.play() // Adversarial resume: test app policy independently of the library fix.
        #expect(h.service.state == (stop ? .stopped : .paused))
        #expect(!h.engine.isPlaying)
        #expect(!h.rates().dropFirst(published).contains(1))
    }

    /// Unplugging headphones (or losing the car's route) pauses in the vendor. That is not a user
    /// command, so the service keeps the playing intent: a later vendor resume is accepted, as in
    /// the UIKit app, and the user can resume from any surface.
    @Test func routeLossPausesWithoutRecordingAUserPause() async throws {
        let h = try await Self.playing()
        h.engine.previousOutputBecameUnavailable()
        #expect(h.service.state == .paused)
        #expect(!h.engine.isPlaying)
        #expect(h.rates().last == 0)
        h.engine.interruptionEnded(shouldResume: true) // No matching interruption began.
        #expect(h.service.state == .paused)
        #expect(!h.engine.isPlaying)
        #expect(h.stations.activate(h.catalog[0], on: .carPlay) == .resumed)
        #expect(h.service.state == .playing)
        #expect(h.engine.isPlaying)
    }

    // MARK: - Contracts the CarPlay list relies on

    /// Re-tapping the playing station must not touch the engine, with the vendor's autoplay and
    /// re-entrant state events in play.
    @Test func reselectingTheCurrentStationIsANoOp() async throws {
        let h = try await Self.playing()
        let calls = h.engine.calls
        let url = h.engine.radioURL
        #expect(h.stations.activate(h.catalog[0], on: .carPlay) == .alreadyActive)
        #expect(h.engine.calls == calls)
        #expect(h.engine.radioURL == url)
    }

    /// A row whose stream URL cannot be opened must not start, or keep, the previous station
    /// under the new row's name: the bridge ignores `.unavailable` and stays on the list.
    @Test func malformedStreamURLLeavesTheCurrentStationPlaying() async throws {
        let h = try await Self.playing()
        let broken = RadioStation(name: "Broken", streamURL: "not a url", imageURL: "", desc: "")
        let calls = h.engine.calls
        #expect(h.stations.activate(broken, on: .carPlay) == .unavailable)
        #expect(h.stations.currentStation == h.catalog[0])
        #expect(h.engine.calls == calls)
        #expect(h.service.state == .playing)
    }

    /// The bridge badges a row when `player.state == .playing` and the row is the current station.
    /// Every way playback ends must leave that state, and a station change moves it.
    @Test func playingBadgeInputsFollowTransport() async throws {
        let h = try await Self.playing()
        let badged = { (station: RadioStation) in
            h.service.state == .playing && h.stations.currentStation?.id == station.id
        }
        #expect(badged(h.catalog[0]))
        h.service.stop()
        #expect(!badged(h.catalog[0]))
        #expect(h.stations.activate(h.catalog[0], on: .carPlay) == .resumed)
        #expect(badged(h.catalog[0]))
        h.engine.interruptionBegan()
        #expect(!badged(h.catalog[0]))
        h.engine.interruptionEnded(shouldResume: true)
        #expect(h.stations.activate(h.catalog[1], on: .carPlay) == .selected)
        #expect(!badged(h.catalog[0]))
        #expect(badged(h.catalog[1]))
        h.engine.observer?.playerStateDidChange(.failed("offline"))
        #expect(!badged(h.catalog[1]))
    }
}
