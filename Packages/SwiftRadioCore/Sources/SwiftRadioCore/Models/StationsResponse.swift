//
//  StationsResponse.swift
//  SwiftRadioCore
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

/// The JSON envelope used by bundled and remote station catalogs.
public struct StationsResponse: Codable, Sendable {
    public var station: [RadioStation]
    public init(station: [RadioStation]) { self.station = station }
}
