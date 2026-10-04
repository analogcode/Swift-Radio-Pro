//
//  RemoteCommand.swift
//  SwiftRadioCore
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

/// The six transport commands supported by the radio app.
enum RemoteCommand: CaseIterable, Sendable {
    case play, pause, stop, toggle, next, previous
}
