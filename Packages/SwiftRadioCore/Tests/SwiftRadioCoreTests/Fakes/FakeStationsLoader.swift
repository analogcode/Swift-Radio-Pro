//
//  FakeStationsLoader.swift
//  SwiftRadioCoreTests
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import Foundation
@testable import SwiftRadioCore

/// Supplies deterministic station lists and counts refreshes without networking.
actor FakeStationsLoader: StationsLoader {
    var stations: [RadioStation]
    private(set) var loadCount = 0
    init(stations: [RadioStation]) { self.stations = stations }
    func replace(with stations: [RadioStation]) { self.stations = stations }
    func load() async throws -> [RadioStation] {
        loadCount += 1
        return stations
    }
}
