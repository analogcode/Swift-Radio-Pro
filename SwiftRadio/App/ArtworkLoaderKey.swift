//
//  ArtworkLoaderKey.swift
//  Swift Radio
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import SwiftUI
import SwiftRadioCore

/// Allows an explicitly injected loader without creating a second default artwork service.
struct ArtworkLoaderKey: EnvironmentKey {
    static let defaultValue: ArtworkLoader? = nil
}

extension EnvironmentValues {
    var artworkLoader: ArtworkLoader? {
        get { self[ArtworkLoaderKey.self] }
        set { self[ArtworkLoaderKey.self] = newValue }
    }
}
