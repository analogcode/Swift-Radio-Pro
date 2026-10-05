//
//  RadioStation+ArtworkSource.swift
//  SwiftRadioCore
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import Foundation

extension RadioStation {
    /// Identifies a bundled image, a remote image, or the app's station placeholder.
    public enum ArtworkSource: Equatable, Sendable {
        case asset(String)
        case remote(URL)
        case placeholder
    }
}
