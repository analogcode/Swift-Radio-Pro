//
//  ConfiguredStationsLoader.swift
//  Swift Radio
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import Foundation
import SwiftRadioCore

/// Resolves template configuration at load time so an invalid remote URL reaches the retry screen.
struct ConfiguredStationsLoader: StationsLoader {
    func load() async throws -> [SwiftRadioCore.RadioStation] {
        if Config.useLocalStations { return try await BundleStationsLoader().load() }
        guard let url = URL(string: Config.stationsURL),
              ["http", "https"].contains(url.scheme?.lowercased() ?? ""), url.host != nil else {
            throw URLError(.badURL)
        }
        return try await RemoteStationsLoader(url: url).load()
    }
}
