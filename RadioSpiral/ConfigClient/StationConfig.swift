//
//  StationConfig.swift
//  RadioSpiral
//
//  Created on 2025-11-12.
//  Portable station data structure from configuration sources
//

import Foundation

/// Portable station data structure from configuration sources
/// Can be converted to RadioStation using RadioStation.from(configStation:)
public struct StationConfig: Codable {
    public let name: String
    public let streamURL: String
    public let imageURL: String
    public let desc: String
    public let longDesc: String
    public let serverName: String
    public let shortCode: String
    public let defaultDJ: String
}
