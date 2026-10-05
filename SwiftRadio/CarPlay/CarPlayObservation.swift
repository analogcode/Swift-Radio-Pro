//
//  CarPlayObservation.swift
//  Swift Radio
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import Observation
import SwiftRadioCore

/// Re-renders CarPlay for catalog, load state, selection, and transport changes, never playback-clock ticks.
@MainActor final class CarPlayObservation {
    private let stations: StationsStore
    private let player: PlayerService
    private var generation = 0
    private var render: (() -> Void)?

    init(stations: StationsStore, player: PlayerService) {
        self.stations = stations
        self.player = player
    }

    func start(render: @escaping () -> Void) {
        generation += 1
        self.render = render
        observe(generation: generation)
    }

    func stop() {
        generation += 1
        render = nil
    }

    private func observe(generation: Int) {
        guard generation == self.generation, render != nil else { return }
        withObservationTracking {
            _ = stations.stations
            _ = stations.loadState // Drives the loading, failure and retry rows.
            _ = stations.currentStation
            _ = player.state
        } onChange: { [weak self] in
            // Tracking fires before the write. Re-read after it, and re-register on MainActor.
            Task { @MainActor [weak self] in self?.observe(generation: generation) }
        }
        render?() // Initial render and subsequent renders use the latest main-actor values.
    }
}
