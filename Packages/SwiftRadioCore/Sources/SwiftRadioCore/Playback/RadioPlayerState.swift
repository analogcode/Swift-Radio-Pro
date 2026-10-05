//
//  RadioPlayerState.swift
//  SwiftRadioCore
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

/// Readiness events retain both ready signals so lock-screen publication can repeat.
public enum RadioPlayerState: Equatable, Sendable {
    case urlNotSet, loading, readyToPlay, loadingFinished
    case failed(String)
}
