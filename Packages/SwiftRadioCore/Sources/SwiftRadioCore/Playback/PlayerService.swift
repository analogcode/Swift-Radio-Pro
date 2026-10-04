//
//  PlayerService.swift
//  SwiftRadioCore
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import Foundation
import OSLog
import os
import Observation
import UIKit
import FRadioPlayer

/// Owns observable playback and translates engine callbacks into application-owned state.
@MainActor @Observable public final class PlayerService: RadioPlayerEvents {
    public private(set) var state: State = .idle
    public private(set) var readiness: Readiness = .idle
    public var isBuffering: Bool { readiness == .loading && state != .stopped }
    public var isLive: Bool { duration == 0 }
    public private(set) var track: String?
    public private(set) var artist: String?
    public private(set) var artworkURL: URL?
    public private(set) var elapsed: TimeInterval = 0
    public private(set) var duration: TimeInterval = 0
    public private(set) var isSeeking = false
    @ObservationIgnored private var seekGeneration = 0
    /// App-owned intent: late engine events must not override an explicit pause or stop.
    @ObservationIgnored private var transportIntent: TransportIntent?
    private enum TransportIntent { case playing, paused, stopped }
    /// Set by seek completion: the engine lands near, not exactly on, the target.
    @ObservationIgnored private var publishesNextTick = false
    @ObservationIgnored private let player: any RadioPlaying
    @ObservationIgnored private let nowPlaying: NowPlayingInfoPublisher
    @ObservationIgnored private let remoteCommands: RemoteCommandsController
    /// Awaited before the engine may start audio. `nil` means there is no session to prepare, so
    /// commands reach the engine synchronously (engine-ordering tests use this).
    @ObservationIgnored private let activateAudioSession: (@MainActor () async throws -> Void)?
    /// Bumped by every transport command, so a newer command supersedes one still waiting for the
    /// session: Stop right after Play must not start audio once activation finishes.
    @ObservationIgnored private var startGeneration = 0
    /// Session arbitration can stall in the audio server; past this deadline the engine starts
    /// anyway (the pre-ownership behaviour) rather than leaving Play dead. Tests shorten it.
    @ObservationIgnored var activationDeadline: Duration = .seconds(4)
    /// The latest activation; each one waits for the previous so session calls never overlap.
    @ObservationIgnored private(set) var activation: Task<Void, Never>?
    /// A load, play or seek is waiting for the session and will start playback when it is active.
    @ObservationIgnored private var hasPendingStart = false
    /// A stream selected while the session was activating that the engine has not received yet.
    @ObservationIgnored private var pendingURL: URL?
    @ObservationIgnored private var station: RadioStation?
    @ObservationIgnored private var stationArtwork: UIImage?
    @ObservationIgnored private var trackArtwork: UIImage?
    /// The station that was current when the engine reported `artworkURL`.
    @ObservationIgnored private var artworkStationID: String?

    /// `mixesWithOtherAudio` keeps other apps playing underneath, at the cost of lock-screen,
    /// Control Center and CarPlay Now Playing (see `AudioSessionConfigurator.categoryOptions`).
    public convenience init(player: any RadioPlaying, nowPlaying: NowPlayingInfoPublisher,
                            remoteCommands: RemoteCommandsController, mixesWithOtherAudio: Bool = false) {
        self.init(player: player, nowPlaying: nowPlaying, remoteCommands: remoteCommands,
                  activateAudioSession: {
                      try await AudioSessionConfigurator.activateForPlayback(mixesWithOthers: mixesWithOtherAudio)
                  })
    }

    /// `activateAudioSession` nil skips session ownership: for a fake engine there is no audio to
    /// own, and gating a UI test on the simulator's audio server only adds a flake.
    public init(player: any RadioPlaying, nowPlaying: NowPlayingInfoPublisher, remoteCommands: RemoteCommandsController,
                activateAudioSession: (@MainActor () async throws -> Void)?) {
        self.player = player
        self.nowPlaying = nowPlaying
        self.remoteCommands = remoteCommands
        self.activateAudioSession = activateAudioSession
        player.addObserver(self)
    }

    /// Creates the vendor adapter; call once in the composition root.
    public static func makeRadioPlayer() -> any RadioPlaying { Engine() }

    public func displayTitle(for station: RadioStation) -> String { track ?? station.name }
    public func displayArtist(for station: RadioStation) -> String { artist ?? station.desc }

    /// Supplies shared station fallbacks without making the player depend on StationsStore.
    public func updateStation(_ station: RadioStation?) {
        if self.station?.id != station?.id { invalidateSeek() }
        self.station = station
        stationArtwork = nil
        trackArtwork = nil
        if station == nil {
            transportIntent = .stopped
            track = nil
            artist = nil
            artworkURL = nil
            elapsed = 0
            updateDuration(0)
            publish()
        }
    }

    /// Rejects artwork that finished after selection or track artwork identity changed.
    public func updateArtwork(_ image: UIImage?, for stationID: String, artworkURL: URL?) {
        guard station?.id == stationID else { return }
        if let artworkURL {
            guard self.artworkURL == artworkURL, artworkStationID == stationID else { return }
            trackArtwork = image
        } else {
            stationArtwork = image
        }
        publish()
    }

    public func load(url: URL) {
        invalidateSeek()
        transportIntent = .playing
        // The previous stream would otherwise keep playing, and reporting its events under the new
        // station, until the session is ready for the new one.
        if activateAudioSession != nil, player.isPlaying { player.stop() }
        state = .idle
        readiness = .loading
        track = nil
        artist = nil
        artworkURL = nil
        trackArtwork = nil
        elapsed = 0
        updateDuration(0)
        pendingURL = url
        publish()
        afterActivation { service in
            service.pendingURL = nil
            service.player.radioURL = url // The production adapter enables autoplay.
            service.publish()
        }
    }

    /// Detaches the engine from a stream that is no longer selectable. `stop()` alone leaves the
    /// vendor's `radioURL` (and its player item) in place, so a later remote Play would resume a
    /// station the catalog has dropped while the phone controls and CarPlay show no selection.
    public func unload() {
        supersedePendingStart()
        pendingURL = nil
        transportIntent = .stopped
        player.stop()
        player.radioURL = nil
        state = .stopped
        readiness = .idle
        updateStation(nil) // Clears presentation and removes system Now Playing info.
    }

    /// Starting playback requires a selected station: remote commands and CarPlay can arrive after
    /// the catalog dropped the current one, and `unload()` leaves the engine with no stream.
    public func play() {
        guard station != nil else { return }
        // A pending load, play or seek already starts playback once the session is active.
        guard !hasPendingStart else { return }
        transportIntent = .playing
        if let url = pendingURL { return load(url: url) } // Stopped before the engine got it.
        afterActivation { service in
            service.player.play(); service.state = .playing; service.syncAndPublish()
        }
    }
    public func pause() {
        supersedePendingStart()
        transportIntent = .paused
        invalidateSeek()
        player.pause(); state = .paused; syncAndPublish()
    }
    public func stop() {
        supersedePendingStart()
        transportIntent = .stopped
        invalidateSeek()
        player.stop(); state = .stopped; syncAndPublish()
    }
    public func togglePlayPause() {
        updateDuration(player.duration ?? 0)
        if player.isPlaying || hasPendingStart {
            if isLive { stop() } else { pause() }
        } else { play() }
    }
    public func seek(to seconds: TimeInterval) {
        guard seconds.isFinite else { return }
        // The engine duration can change during a reload. Read it before seeking so a live
        // stream never enters the app's seek/resume flow, even when our cached duration lags.
        updateDuration(player.duration ?? 0)
        guard !isLive else { return publish() }
        let time = min(max(0, seconds), duration)
        // Releasing the scrubber resumes playback after the seek. A subsequent user command wins.
        transportIntent = .playing
        seekGeneration += 1
        let generation = seekGeneration
        isSeeking = true
        elapsed = time
        syncAndPublish()
        afterActivation { service in
            service.player.seek(to: time) { [weak service] in
                guard let service else { return }
                service.restoreTransportIntentAfterSeek()
                guard service.seekGeneration == generation else { return }
                service.isSeeking = false
                service.publishesNextTick = true
                // Resume-on-scrub is app policy. FRadioPlayer 0.4 seeks without changing
                // transport, so only this still-current completion may resume playback.
                if service.transportIntent == .playing {
                    if !service.player.isPlaying { service.player.play() }
                    service.state = .playing
                }
                service.syncAndPublish()
            }
        }
    }

    /// Hands `command` to the engine once the audio session is active. The session applies its
    /// category only on activation, so starting the engine first could play under the wrong
    /// category or without owning Now Playing. Only the latest transport command may run.
    private func afterActivation(_ command: @escaping @MainActor (PlayerService) -> Void) {
        startGeneration += 1
        guard let activateAudioSession else { return command(self) }
        let generation = startGeneration
        let previous = activation
        hasPendingStart = true
        activation = Task { @MainActor [weak self] in
            await previous?.value
            guard self?.startGeneration == generation else { return }
            let failure: (any Error)?
            let deadline = self?.activationDeadline ?? .seconds(4)
            do { try await Self.awaitActivation(activateAudioSession, deadline: deadline); failure = nil }
            catch { failure = error }
            guard let self, self.startGeneration == generation else { return }
            self.hasPendingStart = false
            if let failure { self.activationFailed(failure) } else { command(self) }
        }
    }

    /// Races the activation against `deadline`. A timeout is not a failure: the engine starts
    /// without confirmed ownership and the next command tries the session again. Awaiting a
    /// blocked `setActive` cannot be cancelled, so the loser simply finds the continuation gone.
    private static func awaitActivation(_ activate: @escaping @MainActor () async throws -> Void,
                                        deadline: Duration) async throws {
        let activated: Bool = try await withCheckedThrowingContinuation { continuation in
            let slot = OSAllocatedUnfairLock<CheckedContinuation<Bool, any Error>?>(initialState: continuation)
            let resume: @Sendable (Result<Bool, any Error>) -> Void = { result in
                slot.withLock { pending -> CheckedContinuation<Bool, any Error>? in
                    defer { pending = nil }
                    return pending
                }?.resume(with: result)
            }
            Task { @MainActor in
                do { try await activate(); resume(.success(true)) } catch { resume(.failure(error)) }
            }
            Task {
                try? await Task.sleep(for: deadline)
                resume(.success(false))
            }
        }
        if !activated {
            Logger(subsystem: "SwiftRadioCore", category: "AudioSession")
                .error("Audio activation exceeded \(deadline); starting playback without it")
        }
    }

    private func supersedePendingStart() {
        startGeneration += 1
        hasPendingStart = false
        // A superseded load never reached the engine: nothing is loading until play() retries it.
        if pendingURL != nil { readiness = .idle }
    }

    /// Without an active session the engine must not play: report it as a player failure so no
    /// surface keeps showing Playing, and let the next tap or Play command retry.
    private func activationFailed(_ error: any Error) {
        transportIntent = .stopped
        invalidateSeek()
        player.stop()
        state = .failed(error.localizedDescription)
        readiness = .idle
        syncAndPublish()
    }

    private func invalidateSeek() {
        seekGeneration += 1
        isSeeking = false
        publishesNextTick = false
    }

    private func restoreTransportIntentAfterSeek() {
        switch transportIntent {
        case .paused: player.pause(); state = .paused
        case .stopped: player.stop(); state = .stopped
        case .playing, nil: break
        }
    }

    public func playerStateDidChange(_ event: RadioPlayerState) {
        switch event {
        case .urlNotSet: readiness = .idle; state = .idle
        case .loading: readiness = .loading
        case .readyToPlay, .loadingFinished: readiness = .ready
        case .failed(let message): readiness = .idle; state = .failed(message)
        }
        syncAndPublish()
    }
    public func playbackStateDidChange(_ state: State) {
        if state == .playing, transportIntent == .paused || transportIntent == .stopped {
            restoreTransportIntentAfterSeek()
        } else if state == .paused, transportIntent == .stopped {
            // The vendor pauses on an interruption even after the user stopped; stopped stays stopped.
        } else {
            self.state = state
        }
        syncAndPublish()
    }
    public func metadataDidChange(artist: String?, track: String?) {
        self.artist = artist
        self.track = track
        syncAndPublish()
    }
    /// FRadioPlayer 0.4 rejects superseded lookups. The app also requires track context before
    /// accepting artwork and keys downloaded images to station/URL identity, so injected or late
    /// application events cannot replace the current station's fallback.
    public func artworkDidChange(_ url: URL?) {
        if url != nil, track == nil, artist == nil { return }
        artworkURL = url
        artworkStationID = url == nil ? nil : station?.id
        trackArtwork = nil // Nil immediately exposes station art, with no network dependency.
        syncAndPublish()
    }
    public func durationDidChange(_ duration: TimeInterval) { updateDuration(duration); publish() }
    /// The system advances lock-screen elapsed time from the published rate, so ticks only update
    /// the observable clock. Rebuilding the dictionary (and its artwork) every 0.5 s adds nothing.
    public func playTimeDidChange(_ elapsed: TimeInterval, duration: TimeInterval) {
        if !isSeeking { self.elapsed = elapsed.isFinite ? max(0, elapsed) : 0 }
        let durationChanged = Self.normalizedDuration(duration) != self.duration
        guard durationChanged || (publishesNextTick && !isSeeking) else { return }
        publishesNextTick = false
        if durationChanged { updateDuration(duration) }
        publish()
    }
    private func updateDuration(_ value: TimeInterval) {
        duration = Self.normalizedDuration(value)
        remoteCommands.updateLiveState(isLive: isLive)
    }
    private static func normalizedDuration(_ value: TimeInterval) -> TimeInterval {
        value.isFinite && value > 0 ? value : 0
    }
    private func syncAndPublish() { updateDuration(player.duration ?? 0); publish() }
    /// The system extrapolates a file's elapsed time from the rate, so a rebuffering file publishes
    /// 0 until it is ready again; transport intent is unchanged. A live stream publishes no clock,
    /// and a 0 rate would only flip its lock-screen button to Play on every rebuffer.
    private var isClockRunning: Bool { state == .playing && (isLive || readiness != .loading) }

    private func publish() {
        guard let station else {
            nowPlaying.clear()
            return
        }
        nowPlaying.update(title: track ?? station.name, artist: artist ?? station.desc,
                          artwork: trackArtwork ?? stationArtwork, isLive: isLive, elapsed: elapsed,
                          duration: duration, rate: isClockRunning ? 1 : 0)
    }
}

extension PlayerService {
    /// Adapts incompatible vendor duration/metadata signatures while keeping vendor types private.
    @MainActor private final class Engine: RadioPlaying, FRadioPlayerObserver {
        private let engine: FRadioPlayer
        private weak var observer: (any RadioPlayerEvents)?
        init() {
            // SwiftRadio owns category setup and activation. Opt out before creating the singleton
            // so startup leaves audio session setup to the app.
            FRadioPlayer.configuresAudioSession = false
            engine = FRadioPlayer.shared
            engine.isAutoPlay = true
            engine.enableArtwork = true
            engine.artworkAPI = iTunesAPI(artworkSize: 600)
            engine.addObserver(self)
        }
        isolated deinit { engine.removeObserver(self) }
        var radioURL: URL? {
            get { engine.radioURL }
            set { engine.radioURL = newValue }
        }
        var isPlaying: Bool { engine.isPlaying }
        var duration: TimeInterval? { engine.duration }
        var currentMetadata: (artist: String?, track: String?)? {
            engine.currentMetadata.map { ($0.artistName, $0.trackName) }
        }
        func play() { engine.play() }
        func pause() { engine.pause() }
        func stop() { engine.stop() }
        func togglePlaying() { engine.togglePlaying() }
        func seek(to seconds: TimeInterval, completion: @escaping @MainActor @Sendable () -> Void) {
            engine.seek(to: seconds) { deliverOnMainActor(completion) }
        }
        func addObserver(_ observer: any RadioPlayerEvents) { self.observer = observer }

        // FRadioPlayer 0.4 guarantees main-actor observer delivery. Keep the defensive adapter
        // boundary: production callbacks run inline, preserving ordering, while explicitly
        // injected background callbacks hop before touching application state. Only application
        // values cross that boundary; vendor metadata is reduced to strings here.
        nonisolated func radioPlayer(_ player: FRadioPlayer, playerStateDidChange state: FRadioPlayer.State) {
            let event: RadioPlayerState
            switch state {
            case .urlNotSet: event = .urlNotSet
            case .loading: event = .loading
            case .readyToPlay: event = .readyToPlay
            case .loadingFinished: event = .loadingFinished
            case .error: event = .failed(state.description)
            }
            deliverOnMainActor { [weak self] in self?.observer?.playerStateDidChange(event) }
        }
        nonisolated func radioPlayer(_ player: FRadioPlayer, playbackStateDidChange state: FRadioPlayer.PlaybackState) {
            let event: PlayerService.State
            switch state {
            case .playing: event = .playing
            case .paused: event = .paused
            case .stopped: event = .stopped
            }
            deliverOnMainActor { [weak self] in self?.observer?.playbackStateDidChange(event) }
        }
        nonisolated func radioPlayer(_ player: FRadioPlayer, metadataDidChange metadata: FRadioPlayer.Metadata?) {
            let artist = metadata?.artistName
            let track = metadata?.trackName
            deliverOnMainActor { [weak self] in self?.observer?.metadataDidChange(artist: artist, track: track) }
        }
        nonisolated func radioPlayer(_ player: FRadioPlayer, artworkDidChange artworkURL: URL?) {
            deliverOnMainActor { [weak self] in self?.observer?.artworkDidChange(artworkURL) }
        }
        nonisolated func radioPlayer(_ player: FRadioPlayer, durationDidChange duration: TimeInterval) {
            deliverOnMainActor { [weak self] in self?.observer?.durationDidChange(duration) }
        }
        nonisolated func radioPlayer(_ player: FRadioPlayer, playTimeDidChange currentTime: TimeInterval, duration: TimeInterval) {
            deliverOnMainActor { [weak self] in self?.observer?.playTimeDidChange(currentTime, duration: duration) }
        }
    }
}
