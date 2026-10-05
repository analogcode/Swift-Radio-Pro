//
//  PlayerService+State.swift
//  SwiftRadioCore
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

extension PlayerService {
    /// Playback transport, independent of the current item's loading progress.
    public enum State: Equatable, Sendable {
        case idle, playing, paused, stopped
        case failed(String)
    }
}
