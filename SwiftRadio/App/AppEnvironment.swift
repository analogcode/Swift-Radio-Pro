//
//  AppEnvironment.swift
//  Swift Radio
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import Observation
import OSLog
import SwiftRadioCore

/// Composes the single playback owner, shared stores, and scene-independent artwork updates.
@MainActor final class AppEnvironment {
    /// The single intentional application global: UIKit CarPlay and SwiftUI share this instance.
    /// AppDelegate initializes it at launch. The audio session is activated by PlayerService when
    /// playback starts, not here: activating on launch would stop other apps' audio.
    static let shared = AppEnvironment()

    let stations: StationsStore
    let player: PlayerService
    let artwork: ArtworkLoader
    private var stationArtworkTask: Task<Void, Never>?
    private var trackArtworkTask: Task<Void, Never>?

    private init() {
        let engine: any RadioPlaying
        #if DEBUG
        // Opt-in only: UI regressions exercise the real app without relying on remote streams.
        engine = ProcessInfo.processInfo.arguments.contains("--ui-test-playback")
            ? UITestRadioPlayer() : PlayerService.makeRadioPlayer()
        #else
        engine = PlayerService.makeRadioPlayer()
        #endif
        let commands = RemoteCommandsController()
        #if DEBUG
        if engine is UITestRadioPlayer {
            // A fake engine produces no audio: owning the session would only gate UI tests on the
            // simulator's audio server. Session behaviour is covered by the core package tests.
            player = PlayerService(player: engine, nowPlaying: NowPlayingInfoPublisher(),
                                   remoteCommands: commands, activateAudioSession: nil)
        } else {
            player = PlayerService(player: engine, nowPlaying: NowPlayingInfoPublisher(), remoteCommands: commands,
                                   mixesWithOtherAudio: Config.mixesWithOtherAudio)
        }
        #else
        player = PlayerService(player: engine, nowPlaying: NowPlayingInfoPublisher(), remoteCommands: commands,
                               mixesWithOtherAudio: Config.mixesWithOtherAudio)
        #endif
        stations = StationsStore(loader: ConfiguredStationsLoader(), player: player)
        artwork = ArtworkLoader()
        commands.bind(player: player, stations: stations)
        observeArtwork()
        if Config.debugLog { observePlayback() }
    }

    private func observeArtwork() {
        let (station, url) = withObservationTracking {
            (stations.currentStation, player.artworkURL)
        } onChange: { [weak self] in
            // Observation fires before mutation; re-read and re-register on the next actor turn.
            Task { @MainActor [weak self] in self?.observeArtwork() }
        }
        stationArtworkTask?.cancel()
        trackArtworkTask?.cancel()
        guard let station else { return }
        stationArtworkTask = Task { [weak self, artwork] in
            let image = await artwork.image(for: station)
            guard !Task.isCancelled, let self, stations.currentStation?.id == station.id else { return }
            player.updateArtwork(image, for: station.id, artworkURL: nil)
        }
        if let url {
            trackArtworkTask = Task { [weak self, artwork] in
                let image = await artwork.trackArtwork(at: url)
                guard !Task.isCancelled, let self, stations.currentStation?.id == station.id,
                      player.artworkURL == url else { return }
                player.updateArtwork(image, for: station.id, artworkURL: url)
            }
        }
    }

    private func observePlayback() {
        let (state, readiness) = withObservationTracking {
            (player.state, player.readiness)
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in self?.observePlayback() }
        }
        Logger(subsystem: "SwiftRadio", category: "Playback")
            .info("Player state: \(String(describing: state), privacy: .public), readiness: \(String(describing: readiness), privacy: .public)")
    }
}
