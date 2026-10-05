//
//  HandoffSearchURLTests.swift
//  SwiftRadioCoreTests
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import Foundation
import Testing
@testable import SwiftRadioCore

/// The outgoing Handoff search needs both artist and track, like the reference app.
struct HandoffSearchURLTests {
    @Test func encodesArtistThenTrack() throws {
        let url = try #require(HandoffActivity.searchURL(track: "Rock & Roll?", artist: "Björk"))
        #expect(url.host == "google.com")
        #expect(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems == [
            URLQueryItem(name: "q", value: "Björk Rock & Roll?")
        ])
    }

    @Test(arguments: [
        (String?.none, String?.some("Artist")),
        (String?.some("Track"), String?.none),
        (String?.some(""), String?.some("Artist")),
        (String?.some("Track"), String?.some("")),
        (String?.none, String?.none),
    ])
    func missingMetadataAdvertisesNothing(track: String?, artist: String?) {
        #expect(HandoffActivity.searchURL(track: track, artist: artist) == nil)
    }
}
