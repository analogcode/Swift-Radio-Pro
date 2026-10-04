//
//  PlayerServiceTests.swift
//  SwiftRadioCoreTests
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import Foundation
import MediaPlayer
import Testing
@testable import SwiftRadioCore

/// Checks event mapping and lock-screen state using only injected infrastructure.
@MainActor struct PlayerServiceTests {
    static func service(_ engine: FakeRadioPlayer = FakeRadioPlayer()) -> PlayerService {
        PlayerService(player: engine, nowPlaying: NowPlayingInfoPublisher(publish: { _ in }),
                      remoteCommands: RemoteCommandsController(handler: FakeRemoteCommandHandler()),
                      activateAudioSession: nil)
    }

    static func gated(_ engine: FakeRadioPlayer, gate: ActivationGate) -> PlayerService {
        PlayerService(player: engine, nowPlaying: NowPlayingInfoPublisher(publish: { _ in }),
                      remoteCommands: RemoteCommandsController(handler: FakeRemoteCommandHandler()),
                      activateAudioSession: { try await gate.activate() })
    }

    /// The simulator's audio server (and, rarely, a device's) can stall session arbitration; Play
    /// must not stay dead behind it. After the deadline the engine starts without ownership.
    @Test func stalledActivationStartsTheEngineAfterTheDeadline() async throws {
        let engine = FakeRadioPlayer()
        let gate = ActivationGate()
        let service = Self.gated(engine, gate: gate)
        service.activationDeadline = .milliseconds(50)
        let station = try RadioStationTests.fixtures()[5]
        service.updateStation(station)
        let url = try #require(URL(string: station.streamURL))
        service.load(url: url)
        await gate.waitForPending(1)
        #expect(engine.radioURL == nil)
        await service.activation?.value // The gate is never released.
        #expect(engine.radioURL == url)
        if case .failed = service.state { Issue.record("a timeout is not a failure") }
        gate.release()
    }

    /// A non-mixable session activated early would silence other apps just by opening this one,
    /// and the session only applies its category when it activates, so the engine must not get a
    /// stream, Play or a seek until activation has finished.
    @Test(arguments: FakeRadioPlayer.Fidelity.allCases)
    func engineWaitsForTheActiveSession(_ fidelity: FakeRadioPlayer.Fidelity) async throws {
        let engine = FakeRadioPlayer(fidelity: fidelity)
        let gate = ActivationGate()
        let service = Self.gated(engine, gate: gate)
        service.play() // No selection: nothing will play, so nothing may activate.
        let station = try RadioStationTests.fixtures()[5]
        service.updateStation(station)
        await gate.waitForPending(0)
        #expect(gate.requests == 0)

        let url = try #require(URL(string: station.streamURL))
        service.load(url: url)
        await gate.waitForPending(1)
        #expect(engine.loadedURLs.isEmpty)
        #expect(engine.calls.isEmpty)
        #expect(service.isBuffering)
        #expect(service.state != .playing)
        gate.release()
        await service.activation?.value
        #expect(engine.radioURL == url)

        engine.announceDuration(180)
        service.stop()
        service.play()
        await gate.waitForPending(1)
        #expect(engine.calls.last == "stop")
        #expect(service.state == .stopped)
        gate.release()
        await service.activation?.value
        #expect(engine.calls.last == "play")
        #expect(service.state == .playing)

        service.seek(to: 60)
        await gate.waitForPending(1)
        #expect(engine.soughtTime == nil)
        gate.release()
        await service.activation?.value
        #expect(engine.soughtTime == 60)
        #expect(gate.requests == 3)
    }

    /// Activation can fail (another app holds a non-mixable session, for one). Nothing may then
    /// report Playing, and the next command retries.
    @Test(arguments: FakeRadioPlayer.Fidelity.allCases)
    func failedActivationIsAPlayerFailureAndRetries(_ fidelity: FakeRadioPlayer.Fidelity) async throws {
        let engine = FakeRadioPlayer(fidelity: fidelity)
        let gate = ActivationGate()
        let service = Self.gated(engine, gate: gate)
        let station = try RadioStationTests.fixtures()[0]
        let url = try #require(URL(string: station.streamURL))
        service.updateStation(station)
        service.load(url: url)
        await gate.waitForPending(1)
        gate.fail()
        await service.activation?.value
        guard case .failed = service.state else { Issue.record("state \(service.state)"); return }
        #expect(!service.isBuffering)
        #expect(engine.loadedURLs.isEmpty)
        #expect(!engine.calls.contains("play"))

        service.play() // A remote Play or a tap retries the stream that never reached the engine.
        await gate.waitForPending(1)
        gate.release()
        await service.activation?.value
        #expect(engine.radioURL == url)
    }

    /// Stop, Pause or a newer selection while the session is activating wins: the superseded
    /// request never reaches the engine, and the activations run one after another.
    @Test(arguments: ["stop", "pause", "select"])
    func laterCommandSupersedesPendingActivation(_ command: String) async throws {
        let engine = FakeRadioPlayer(fidelity: .vendor)
        let gate = ActivationGate()
        let service = Self.gated(engine, gate: gate)
        let stations = try RadioStationTests.fixtures()
        let first = try #require(URL(string: stations[0].streamURL))
        let second = try #require(URL(string: stations[1].streamURL))
        service.updateStation(stations[0])
        service.load(url: first)
        await gate.waitForPending(1)
        switch command {
        case "stop": service.stop()
        case "pause": service.pause()
        default: service.updateStation(stations[1]); service.load(url: second)
        }
        await gate.waitForPending(1) // The next activation waits for the one in progress.
        #expect(gate.requests == 1)
        gate.release()
        if command == "select" {
            await gate.waitForPending(1) // Only now, after the first one finished.
            #expect(engine.loadedURLs.isEmpty)
            gate.release()
            await service.activation?.value
            #expect(gate.requests == 2)
            #expect(engine.loadedURLs == [second])
            #expect(service.state == .playing)
        } else {
            await service.activation?.value
            #expect(engine.loadedURLs.isEmpty)
            #expect(service.state == (command == "stop" ? .stopped : .paused))
            #expect(!service.isBuffering)
        }
    }

    /// The previous stream must not keep playing, or report its events under the new station,
    /// while the session activates for the next one.
    @Test func selectionStopsThePreviousStreamWhileActivating() async throws {
        let engine = FakeRadioPlayer(fidelity: .vendor)
        let gate = ActivationGate()
        let service = Self.gated(engine, gate: gate)
        let stations = try RadioStationTests.fixtures()
        service.updateStation(stations[0])
        service.load(url: try #require(URL(string: stations[0].streamURL)))
        await gate.waitForPending(1)
        gate.release()
        await service.activation?.value
        #expect(engine.isPlaying)
        service.updateStation(stations[1])
        service.load(url: try #require(URL(string: stations[1].streamURL)))
        #expect(!engine.isPlaying)
        #expect(service.state == .idle)
        #expect(service.isBuffering)
    }

    /// The system advances lock-screen elapsed time from the published rate, so clock ticks must
    /// not rebuild the Now Playing dictionary; only new information (duration, seek result) does.
    @Test func playbackClockTicksDoNotRepublishNowPlaying() throws {
        let engine = FakeRadioPlayer()
        engine.duration = 180
        engine.completesSeeksImmediately = false
        var published: [[String: Any]?] = []
        let remote = FakeRemoteCommandHandler()
        let service = PlayerService(player: engine, nowPlaying: NowPlayingInfoPublisher(publish: { published.append($0) }),
                                    remoteCommands: RemoteCommandsController(handler: remote),
                                    activateAudioSession: nil)
        service.updateStation(try RadioStationTests.fixtures()[0])
        service.durationDidChange(180)
        let before = published.count
        remote.enabled.removeAll()
        for second in 1...10 { service.playTimeDidChange(TimeInterval(second), duration: 180) }
        #expect(published.count == before)
        #expect(remote.enabled.isEmpty)
        #expect(service.elapsed == 10)

        engine.duration = 240
        service.playTimeDidChange(11, duration: 240)
        #expect(published.count == before + 1)

        service.seek(to: 100)
        let afterSeek = published.count
        engine.pendingSeeks.removeFirst()()
        #expect(published.count == afterSeek + 1)
        // The engine lands near, not on, the target: the first tick after completion corrects it once.
        service.playTimeDidChange(99, duration: 240)
        service.playTimeDidChange(100, duration: 240)
        #expect(published.count == afterSeek + 2)
        #expect(published.last??[MPNowPlayingInfoPropertyElapsedPlaybackTime] as? Double == 99)
    }

    @Test func toggleUsesLiveRule() throws {
        let engine = FakeRadioPlayer()
        let service = Self.service(engine)
        service.updateStation(try RadioStationTests.fixtures()[0]) // play() requires a selection.
        engine.isPlaying = true
        engine.duration = 0
        service.togglePlayPause()
        #expect(engine.calls.last == "stop")
        engine.isPlaying = true
        engine.duration = 180
        service.togglePlayPause()
        #expect(engine.calls.last == "pause")
        service.togglePlayPause()
        #expect(engine.calls.last == "play")
    }

    /// An injected engine event can arrive off-main, so the adapter's defensive delivery
    /// helper must hop instead of asserting isolation.
    @Test func backgroundCallbackReachesTheObserverOnTheMainActor() async {
        let engine = FakeRadioPlayer()
        let service = Self.service(engine)
        #expect(service.state == .idle)
        let ranOffMain = await engine.emitPlaybackStateFromBackground(.stopped)
        #expect(ranOffMain)
        #expect(service.state == .stopped)
    }

    /// Transport is gated on a selection: `unload()` clears both, so a late remote Play is inert.
    @Test func unloadClearsTheEngineAndRejectsPlay() throws {
        let engine = FakeRadioPlayer()
        let service = Self.service(engine)
        let station = try RadioStationTests.fixtures()[0]
        service.updateStation(station)
        service.load(url: try #require(URL(string: station.streamURL)))
        service.play()
        #expect(engine.calls.last == "play")
        service.unload()
        #expect(engine.radioURL == nil)
        #expect(engine.calls.last == "stop")
        #expect(service.state == .stopped)
        #expect(service.readiness == .idle)
        let callsAfterUnload = engine.calls.count
        service.play()
        service.togglePlayPause()
        #expect(engine.calls.count == callsAfterUnload)
        #expect(service.state == .stopped)
    }

    @Test func readinessIsSeparateAndRepeatedReadyEventsPublish() {
        let engine = FakeRadioPlayer()
        var publications = 0
        let remote = FakeRemoteCommandHandler()
        let service = PlayerService(player: engine, nowPlaying: NowPlayingInfoPublisher(publish: { _ in publications += 1 }),
                                    remoteCommands: RemoteCommandsController(handler: remote),
                                    activateAudioSession: nil)
        engine.observer?.playbackStateDidChange(.playing)
        engine.observer?.playerStateDidChange(.loading)
        #expect(service.state == .playing)
        #expect(service.readiness == .loading)
        #expect(service.isBuffering)
        engine.duration = 180
        engine.observer?.playerStateDidChange(.readyToPlay)
        #expect(!service.isBuffering)
        #expect(!service.isLive)
        #expect(remote.enabled[.pause] == true)
        let before = publications
        engine.observer?.playerStateDidChange(.loadingFinished)
        #expect(publications == before + 1)
        service.stop()
        engine.observer?.playerStateDidChange(.loading)
        #expect(!service.isBuffering)
        #expect(service.state == .stopped)
    }

    /// A seekable file with a pending-seek engine. The vendor engine only seeks with a stream and
    /// a nonzero duration of its own, so both are set up the way the engine reports them.
    static func seekableFile(_ fidelity: FakeRadioPlayer.Fidelity) throws -> (FakeRadioPlayer, PlayerService) {
        let engine = FakeRadioPlayer(fidelity: fidelity)
        engine.completesSeeksImmediately = false
        let service = service(engine)
        let station = try RadioStationTests.fixtures()[0]
        service.updateStation(station)
        service.load(url: try #require(URL(string: station.streamURL)))
        engine.announceDuration(180)
        return (engine, service)
    }

    @Test(arguments: FakeRadioPlayer.Fidelity.allCases)
    func seekHoldsPositionUntilCompletion(_ fidelity: FakeRadioPlayer.Fidelity) throws {
        let (engine, service) = try Self.seekableFile(fidelity)
        service.seek(to: 90)
        #expect(service.isSeeking)
        service.playTimeDidChange(12, duration: 180)
        #expect(service.elapsed == 90)
        engine.pendingSeeks.removeFirst()()
        #expect(!service.isSeeking)
        #expect(service.state == .playing)
        service.playTimeDidChange(91, duration: 180)
        #expect(service.elapsed == 91)
    }

    /// The app owns resume-on-scrub, even when the engine only changes position (0.4).
    @Test(arguments: FakeRadioPlayer.Fidelity.allCases)
    func completedSeekResumesPausedFile(_ fidelity: FakeRadioPlayer.Fidelity) throws {
        let (engine, service) = try Self.seekableFile(fidelity)
        service.pause()
        service.seek(to: 90)
        #expect(!engine.isPlaying)
        engine.pendingSeeks.removeFirst()()
        #expect(service.state == .playing)
        #expect(engine.isPlaying)
        #expect(!service.isSeeking)
    }

    @Test(arguments: FakeRadioPlayer.Fidelity.allCases)
    func staleIndependentSeekCannotResumeBeforeNewSeekCompletes(_ fidelity: FakeRadioPlayer.Fidelity) throws {
        let (engine, service) = try Self.seekableFile(fidelity)
        service.pause()
        service.seek(to: 30)
        service.seek(to: 90)
        let plays = engine.calls.filter { $0 == "play" }.count
        engine.pendingSeeks.removeFirst()()
        #expect(engine.calls.filter { $0 == "play" }.count == plays)
        #expect(!engine.isPlaying)
        #expect(service.isSeeking)
        engine.pendingSeeks.removeFirst()()
        #expect(engine.isPlaying)
        #expect(!service.isSeeking)
    }

    @Test(arguments: FakeRadioPlayer.Fidelity.allCases)
    func staleIndependentSeekDoesNotPlayAnotherStation(_ fidelity: FakeRadioPlayer.Fidelity) throws {
        let (engine, service) = try Self.seekableFile(fidelity)
        service.pause()
        service.seek(to: 30)
        let station = try RadioStationTests.fixtures()[1]
        service.updateStation(station)
        service.load(url: try #require(URL(string: station.streamURL)))
        let plays = engine.calls.filter { $0 == "play" }.count
        engine.pendingSeeks.removeFirst()()
        #expect(engine.calls.filter { $0 == "play" }.count == plays)
        // Loading the new station autoplays only in vendor mode. The old completion
        // must leave that station's state unchanged and must not issue another Play.
        #expect(service.state == (fidelity == .vendor ? .playing : .idle))
        #expect(engine.isPlaying == (fidelity == .vendor))
        #expect(!service.isSeeking)
    }

    @Test(arguments: FakeRadioPlayer.Fidelity.allCases)
    func staleSeekCompletionCannotReleaseNewSeek(_ fidelity: FakeRadioPlayer.Fidelity) throws {
        let (engine, service) = try Self.seekableFile(fidelity)
        service.seek(to: 30)
        service.seek(to: 90)
        engine.pendingSeeks.removeFirst()()
        #expect(service.isSeeking)
        #expect(service.elapsed == 90)
        engine.pendingSeeks.removeFirst()()
        #expect(!service.isSeeking)
    }

    @Test(arguments: FakeRadioPlayer.Fidelity.allCases)
    func stationChangeAndStopInvalidateSeek(_ fidelity: FakeRadioPlayer.Fidelity) throws {
        let (engine, service) = try Self.seekableFile(fidelity)
        service.seek(to: 90)
        service.load(url: try #require(URL(string: "https://example.com/new.mp3")))
        #expect(!service.isSeeking)
        #expect(service.elapsed == 0)
        // The old item's completion still arrives after the new item has been loaded.
        engine.pendingSeeks.removeFirst()()
        #expect(service.elapsed == 0)
        #expect(!service.isSeeking)
        engine.announceDuration(180)
        service.seek(to: 20)
        service.stop()
        #expect(!service.isSeeking)
        engine.pendingSeeks.removeFirst()()
        #expect(service.state == .stopped)
        #expect(!engine.isPlaying)
    }

    /// Both engine shapes preserve the user's pause/stop across seek completion. Recording mode
    /// additionally injects an unexpected Playing event to exercise the app's defensive guard.
    @Test(arguments: FakeRadioPlayer.Fidelity.allCases, [false, true])
    func lateSeekCannotOverrideTransportCommand(_ fidelity: FakeRadioPlayer.Fidelity, stop: Bool) throws {
        let (engine, service) = try Self.seekableFile(fidelity)
        service.seek(to: 90)
        if stop { service.stop() } else { service.pause() }
        if fidelity == .recording {
            engine.play()
            engine.observer?.playbackStateDidChange(.playing)
            #expect(service.state == (stop ? .stopped : .paused))
        }
        engine.pendingSeeks.removeFirst()()
        #expect(service.state == (stop ? .stopped : .paused))
        #expect(!engine.isPlaying)
        #expect(!service.isSeeking)
    }

    /// A live or reloading engine should not enter the app's seek/resume flow. The service's
    /// cached duration can lag behind a reload; using it would wrongly request a seek and resume
    /// a stream whose current duration is unknown.
    @Test(arguments: FakeRadioPlayer.Fidelity.allCases)
    func unknownEngineDurationDoesNotEnterSeekFlow(_ fidelity: FakeRadioPlayer.Fidelity) throws {
        let (engine, service) = try Self.seekableFile(fidelity)
        engine.duration = 0 // Changed underneath the service, with no durationDidChange yet.
        #expect(service.duration == 180)
        service.seek(to: 60)
        #expect(!service.isSeeking)
        #expect(engine.pendingSeeks.isEmpty)
        #expect(service.isLive)
        service.playTimeDidChange(5, duration: 0)
        #expect(service.elapsed == 5)
    }

    /// What the lock screen shows for each transport change: the published rate and elapsed time
    /// are all the system has to run its own clock between updates.
    @Test func nowPlayingReflectsTransport() throws {
        let engine = FakeRadioPlayer(fidelity: .vendor)
        engine.completesSeeksImmediately = false
        var info: [String: Any]?
        let service = PlayerService(player: engine, nowPlaying: NowPlayingInfoPublisher(publish: { info = $0 }),
                                    remoteCommands: RemoteCommandsController(handler: FakeRemoteCommandHandler()),
                                    activateAudioSession: nil)
        let stations = try RadioStationTests.fixtures()
        service.updateStation(stations[5])
        service.load(url: try #require(URL(string: stations[5].streamURL)))
        engine.announceDuration(180)
        #expect(info?[MPNowPlayingInfoPropertyPlaybackRate] as? Float == 0) // Still buffering.
        engine.observer?.playerStateDidChange(.loadingFinished)
        #expect(info?[MPNowPlayingInfoPropertyPlaybackRate] as? Float == 1)
        service.playTimeDidChange(30, duration: 180)

        service.pause()
        #expect(info?[MPNowPlayingInfoPropertyPlaybackRate] as? Float == 0)
        #expect(info?[MPNowPlayingInfoPropertyElapsedPlaybackTime] as? Double == 30)
        #expect(info?[MPMediaItemPropertyPlaybackDuration] as? Double == 180)

        service.seek(to: 100)
        #expect(info?[MPNowPlayingInfoPropertyElapsedPlaybackTime] as? Double == 100)
        engine.pendingSeeks.removeFirst()() // The app explicitly resumes after the independent seek completes.
        #expect(info?[MPNowPlayingInfoPropertyPlaybackRate] as? Float == 1)
        #expect(info?[MPNowPlayingInfoPropertyElapsedPlaybackTime] as? Double == 100)

        service.updateStation(stations[0])
        service.load(url: try #require(URL(string: stations[0].streamURL)))
        #expect(info?[MPNowPlayingInfoPropertyIsLiveStream] as? Bool == true)
        #expect(info?[MPNowPlayingInfoPropertyPlaybackRate] as? Float == 1)
        service.stop()
        #expect(info?[MPNowPlayingInfoPropertyPlaybackRate] as? Float == 0)
        #expect(info?[MPNowPlayingInfoPropertyElapsedPlaybackTime] == nil)
        #expect(info?[MPMediaItemPropertyPlaybackDuration] == nil)
        #expect(info?[MPMediaItemPropertyTitle] as? String == stations[0].name)
    }

    /// A buffering file keeps its transport intent but its clock stands still; a nonzero rate
    /// would let the lock screen run ahead and jump back when audio resumes.
    @Test func bufferingFilePublishesAStoppedClock() throws {
        let engine = FakeRadioPlayer(fidelity: .vendor)
        engine.completesSeeksImmediately = false
        var published: [[String: Any]] = []
        let service = PlayerService(player: engine, nowPlaying: NowPlayingInfoPublisher(publish: { published.append($0 ?? [:]) }),
                                    remoteCommands: RemoteCommandsController(handler: FakeRemoteCommandHandler()),
                                    activateAudioSession: nil)
        let station = try RadioStationTests.fixtures()[5]
        service.updateStation(station)
        service.load(url: try #require(URL(string: station.streamURL)))
        engine.announceDuration(180)
        engine.observer?.playerStateDidChange(.loadingFinished)
        service.playTimeDidChange(30, duration: 180)
        func last(_ key: String) -> Any? { published.last?[key] }
        #expect(last(MPNowPlayingInfoPropertyPlaybackRate) as? Float == 1)

        engine.observer?.playerStateDidChange(.loading) // Stalled mid-file.
        #expect(service.state == .playing)
        #expect(last(MPNowPlayingInfoPropertyPlaybackRate) as? Float == 0)
        #expect(last(MPNowPlayingInfoPropertyElapsedPlaybackTime) as? Double == 30)
        engine.observer?.playerStateDidChange(.loadingFinished)
        #expect(last(MPNowPlayingInfoPropertyPlaybackRate) as? Float == 1)
        #expect(last(MPNowPlayingInfoPropertyElapsedPlaybackTime) as? Double == 30)

        service.pause()
        #expect(last(MPNowPlayingInfoPropertyPlaybackRate) as? Float == 0)
        service.seek(to: 100)
        #expect(last(MPNowPlayingInfoPropertyElapsedPlaybackTime) as? Double == 100)
        engine.pendingSeeks.removeFirst()() // The app explicitly resumes after the independent seek completes.
        #expect(last(MPNowPlayingInfoPropertyPlaybackRate) as? Float == 1)
        service.pause()
        service.play()
        #expect(last(MPNowPlayingInfoPropertyPlaybackRate) as? Float == 1)
        #expect(last(MPNowPlayingInfoPropertyElapsedPlaybackTime) as? Double == 100)
    }

    @Test func metadataArtworkTimeAndFallbacks() throws {
        let engine = FakeRadioPlayer()
        let service = Self.service(engine)
        let station = try RadioStationTests.fixtures()[0]
        #expect(service.displayTitle(for: station) == station.name)
        #expect(service.displayArtist(for: station) == station.desc)
        engine.observer?.metadataDidChange(artist: "Artist", track: "Track")
        #expect(service.track == "Track")
        #expect(service.artist == "Artist")
        #expect(service.displayTitle(for: station) == "Track")
        let artwork = URL(string: "https://example.com/art.jpg")!
        engine.observer?.artworkDidChange(artwork)
        #expect(service.artworkURL == artwork)
        engine.duration = 180
        engine.observer?.durationDidChange(180)
        engine.observer?.playTimeDidChange(30, duration: 180)
        #expect(service.elapsed == 30)
        #expect(service.duration == 180)
        service.seek(to: 45)
        #expect(engine.soughtTime == 45)
        #expect(service.elapsed == 45)
        engine.observer?.artworkDidChange(nil)
        #expect(service.artworkURL == nil)
        service.load(url: URL(string: station.streamURL)!)
        #expect(service.track == nil)
        #expect(service.artist == nil)
        #expect(service.elapsed == 0)
        #expect(service.isLive)
    }
}
