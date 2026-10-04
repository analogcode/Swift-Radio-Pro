//
//  StationsStore.swift
//  SwiftRadioCore
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import Foundation
import Observation

/// Owns catalog loading, filtering, and circular station selection for all app scenes.
@MainActor @Observable public final class StationsStore {
    public private(set) var stations: [RadioStation] = []
    public private(set) var currentStation: RadioStation?
    public private(set) var loadState: LoadState = .idle
    public var searchText = ""
    @ObservationIgnored private let loader: any StationsLoader
    @ObservationIgnored private let player: PlayerService
    @ObservationIgnored private var loadGeneration = 0

    public init(loader: any StationsLoader, player: PlayerService) {
        self.loader = loader
        self.player = player
    }

    public var filteredStations: [RadioStation] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return query.isEmpty ? stations : stations.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    public func load() async {
        loadGeneration += 1
        let generation = loadGeneration
        let previousState = loadState
        loadState = .loading
        do {
            let loaded = try await loader.load()
            try Task.checkCancellation()
            guard generation == loadGeneration else { return }
            if loaded != stations {
                stations = loaded
                if let currentStation, !loaded.contains(currentStation) {
                    self.currentStation = nil
                    // Clearing selection must not leave audio playing behind hidden controls, nor
                    // leave the removed stream loaded and resumable from a remote Play command.
                    player.unload()
                }
            }
            loadState = .loaded
        } catch {
            guard generation == loadGeneration else { return }
            if error is CancellationError || (error as? URLError)?.code == .cancelled {
                loadState = previousState == .loading ? .idle : previousState
            } else {
                loadState = .failed(error.localizedDescription)
            }
        }
    }

    public func refresh() async { await load() }

    /// Returns `false`, leaving the current selection and stream untouched, when the station's
    /// stream URL cannot be opened. Callers must not start playback on `false`: the engine would
    /// resume the previously selected station under the new station's row.
    @discardableResult public func select(_ station: RadioStation) -> Bool {
        guard let url = Self.streamURL(for: station) else { return false }
        currentStation = station
        player.updateStation(station)
        player.load(url: url)
        return true
    }

    /// Row-tap rule. A different (or failed) station reloads its stream on every surface; for the
    /// current station the surfaces differ on purpose:
    /// - `.phone` mirrors the UIKit reference: playing opens the player, anything else (paused,
    ///   stopped, or a load still waiting for the audio session) toggles. The vendor's autoplay
    ///   reports a buffering stream as playing, so that opens the player, as in UIKit.
    /// - `.carPlay` never restarts or cancels: playing or loading is left alone, paused or stopped plays.
    @discardableResult public func activate(_ station: RadioStation, on surface: ActivationSurface) -> Activation {
        guard station == currentStation else { return select(station) ? .selected : .unavailable }
        switch (player.state, surface) {
        case (.playing, _):
            return .alreadyActive
        case (.failed, _):
            return select(station) ? .selected : .unavailable
        case (.idle, .carPlay) where player.isBuffering:
            return .alreadyActive // The pending load starts once the session is active.
        case (_, .carPlay):
            player.play()
            return .resumed
        case (_, .phone):
            player.togglePlayPause()
            return player.state == .playing ? .resumed : .paused
        }
    }

    /// Returns whether a station was selected, so a remote command can report that it could not act.
    @discardableResult public func selectNext() -> Bool { selectRelative(offset: 1) }
    @discardableResult public func selectPrevious() -> Bool { selectRelative(offset: -1) }

    /// Steps over stations with unusable stream URLs so a single bad catalog entry cannot trap
    /// Next/Previous on it. With every other entry unusable the current stream is left alone.
    private func selectRelative(offset: Int) -> Bool {
        let count = stations.count
        guard count > 0 else { return false }
        guard let currentStation, let index = stations.firstIndex(of: currentStation) else {
            return stations.contains { select($0) }
        }
        for step in 1..<count {
            let candidate = stations[((index + offset * step) % count + count) % count]
            if select(candidate) { return true }
        }
        return false
    }

    private static func streamURL(for station: RadioStation) -> URL? {
        guard let url = URL(string: station.streamURL), url.scheme != nil else { return nil }
        return url
    }
}
