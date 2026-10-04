//
//  StationsStore+LoadState.swift
//  SwiftRadioCore
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

extension StationsStore {
    /// The latest catalog request's progress, independent of navigation lifetime.
    public enum LoadState: Equatable, Sendable {
        case idle, loading, loaded
        case failed(String)
    }

    /// Which surface a row tap came from; see `activate(_:on:)`.
    public enum ActivationSurface: CaseIterable, Sendable {
        case phone, carPlay
    }

    /// Outcome of `activate(_:on:)`, so a caller can finish its UI flow without inspecting the player.
    public enum Activation: Equatable, Sendable {
        /// The station was selected and its stream loaded (autoplay starts it).
        case selected
        /// The paused or stopped current station was asked to play again.
        case resumed
        /// A phone tap paused or stopped the current station, or cancelled its pending start.
        case paused
        /// The station is already playing (or, on CarPlay, loading); nothing changed.
        case alreadyActive
        /// The station's stream URL is unusable; nothing changed.
        case unavailable
    }
}
