//
//  ArtworkLoaderTests.swift
//  SwiftRadioCoreTests
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import Foundation
import Testing
import UIKit
@testable import SwiftRadioCore

/// Verifies station fallback, request-keyed decoded caching, and deterministic network failures.
struct ArtworkLoaderTests {
    @Test func bundleImagesAndEmptyArtwork() async throws {
        let loader = ArtworkLoader(session: StubURLProtocol.session(), placeholderName: "Fixtures/placeholder", bundle: .module)
        var station = try RadioStationTests.fixtures()[0]
        station.imageURL = "Fixtures/station"
        let image = await loader.image(for: station)
        let expected = try #require(UIImage(named: "Fixtures/station", in: .module, compatibleWith: nil))
        #expect(image.pngData() == expected.pngData())
        station.imageURL = ""
        let fallback = await loader.image(for: station)
        let placeholder = try #require(UIImage(named: "Fixtures/placeholder", in: .module, compatibleWith: nil))
        #expect(fallback.pngData() == placeholder.pngData())
        station.imageURL = "https://example.com/offline"
        #expect(await loader.image(for: station).pngData() == placeholder.pngData())
        #expect(await loader.trackArtwork(at: URL(string: "https://example.com/invalid")!) == nil)
        #expect(await loader.trackArtwork(at: URL(string: "https://example.com/missing")!) == nil)
    }

    @Test func decodedImagesAreCachedByURL() async throws {
        let loader = ArtworkLoader(session: StubURLProtocol.session())
        let url = URL(string: "https://example.com/image")!
        let first = try #require(await loader.trackArtwork(at: url))
        let second = try #require(await loader.trackArtwork(at: url))
        #expect(first === second)
        let different = try #require(await loader.trackArtwork(at: URL(string: "https://example.com/another")!))
        #expect(first !== different)
    }
}
