//
//  StationsLoader.swift
//  SwiftRadioCore
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

/// Loads a station catalog without tying observable state to its source.
public protocol StationsLoader: Sendable {
    func load() async throws -> [RadioStation]
}
