//
//  RadioStationTests.swift
//  SwiftRadioCoreTests
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import Foundation
import Testing
@testable import SwiftRadioCore

/// Verifies decoding, stable identity, legacy equality, and URL presentation rules.
struct RadioStationTests {
    static func fixtures() throws -> [RadioStation] {
        let url = try #require(Bundle.module.url(forResource: "stations", withExtension: "json", subdirectory: "Fixtures"))
        return try JSONDecoder().decode(StationsResponse.self, from: Data(contentsOf: url)).station
    }

    @Test func decodingAndArtwork() throws {
        let stations = try Self.fixtures()
        #expect(stations.count == 6)
        #expect(stations.last?.artworkSource == .placeholder)
        #expect(stations.first?.artworkSource == .asset("station-absolutecountry"))
        var station = stations[0]
        station.imageURL = "https://example.com/art.png"
        #expect(station.artworkSource == .remote(URL(string: station.imageURL)!))
    }

    @Test(arguments: [nil, "", "radio.com", "ftp://radio.com", "https://", "httpx://radio.com"] as [String?])
    func rejectsInvalidWebsites(website: String?) throws {
        var station = try Self.fixtures()[0]
        station.website = website
        #expect(!station.hasValidWebsite)
    }

    @Test func identityAndEquality() throws {
        let station = try Self.fixtures()[0]
        var other = station
        other.website = "https://different.example"
        #expect(station == other)
        #expect(Set([station, other]).count == 1)
        other.streamURL += "/other"
        #expect(station.id != other.id) // Duplicate station names remain distinct.
        #expect(station != other)
        other = station
        other.name += " renamed"
        #expect(station.id != other.id)
        #expect(station.hasValidWebsite)
    }

    /// A fork's catalog may omit `longDesc` and `website`; neither may fail the whole catalog.
    @Test func decodesWithoutOptionalKeys() throws {
        let json = Data(#"{"name":"Test","streamURL":"https://radio.com/live","imageURL":"","desc":"Radio"}"#.utf8)
        let station = try JSONDecoder().decode(RadioStation.self, from: json)
        #expect(station.longDesc.isEmpty)
        #expect(station.website == nil)
        #expect(station.name == "Test")
        let roundTripped = try JSONDecoder().decode(RadioStation.self, from: JSONEncoder().encode(station))
        #expect(roundTripped == station)
    }

    @Test func musicSearchEscapesQueryAndInitializerKeepsWebsite() throws {
        let station = RadioStation(name: "Test", website: "https://radio.com", streamURL: "https://radio.com/live",
                                   imageURL: "", desc: "Radio")
        #expect(station.hasValidWebsite)
        let url = try #require(station.musicSearchURL(track: "Rock & Roll + ?", artist: "Björk / AC/DC"))
        let items = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
        #expect(items == [URLQueryItem(name: "term", value: "Rock & Roll + ? Björk / AC/DC")])
        #expect(station.musicSearchURL(track: nil, artist: "Artist") == nil)
    }
}
