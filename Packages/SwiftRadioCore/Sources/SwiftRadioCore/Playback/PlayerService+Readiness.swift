//
//  PlayerService+Readiness.swift
//  SwiftRadioCore
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

extension PlayerService {
    /// Whether the current media item is usable, even while transport is stopped.
    public enum Readiness: Equatable, Sendable {
        case idle, loading, ready
    }
}
