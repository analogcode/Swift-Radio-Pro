//
//  BundleStationsLoader.swift
//  SwiftRadioCore
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import Foundation

/// Decodes a station catalog from the supplied application or test bundle.
public struct BundleStationsLoader: StationsLoader {
    public var fileName: String
    public var bundle: Bundle
    public init(fileName: String = "stations", bundle: Bundle = .main) {
        self.fileName = fileName
        self.bundle = bundle
    }

    public func load() async throws -> [RadioStation] {
        guard let url = bundle.url(forResource: fileName, withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try JSONDecoder().decode(StationsResponse.self, from: Data(contentsOf: url)).station
    }
}
