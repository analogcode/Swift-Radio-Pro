//
//  RadioStation.swift
//  SwiftRadioCore
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import Foundation

/// A station's catalog data, stable identity, and metadata-independent presentation helpers.
public struct RadioStation: Codable, Hashable, Sendable, Identifiable {
    public var name: String
    public var streamURL: String
    public var imageURL: String
    public var desc: String
    public var longDesc: String
    public var website: String?
    public var id: String { streamURL + "|" + name }

    public init(name: String, website: String? = nil, streamURL: String, imageURL: String,
                desc: String, longDesc: String = "") {
        self.name = name
        self.website = website
        self.streamURL = streamURL
        self.imageURL = imageURL
        self.desc = desc
        self.longDesc = longDesc
    }

    private enum CodingKeys: String, CodingKey {
        case name, streamURL, imageURL, desc, longDesc, website
    }

    /// Hand-written so `longDesc` is genuinely optional in a fork's catalog: synthesized decoding
    /// requires the nonoptional property and the initializer's default never applies. A missing
    /// key becomes an empty string, which the station info screen already renders as its default.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        streamURL = try container.decode(String.self, forKey: .streamURL)
        imageURL = try container.decode(String.self, forKey: .imageURL)
        desc = try container.decode(String.self, forKey: .desc)
        longDesc = try container.decodeIfPresent(String.self, forKey: .longDesc) ?? ""
        website = try container.decodeIfPresent(String.self, forKey: .website)
    }

    public var hasValidWebsite: Bool {
        guard let website, let url = URL(string: website) else { return false }
        return Self.isWebURL(url)
    }

    public var shoutout: String {
        let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? ""
        return "I'm listening to \(name) via \(appName) app"
    }

    public func musicSearchURL(track: String?, artist: String?) -> URL? {
        guard let track, let artist else { return nil }
        var components = URLComponents()
        components.scheme = "https"
        components.host = "music.apple.com"
        components.path = "/search"
        components.queryItems = [URLQueryItem(name: "term", value: "\(track) \(artist)")]
        // A literal plus must survive servers that interpret '+' as form-encoded space.
        components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        return components.url
    }

    public var artworkSource: ArtworkSource {
        guard !imageURL.isEmpty else { return .placeholder }
        if let url = URL(string: imageURL), Self.isWebURL(url) { return .remote(url) }
        return .asset(imageURL)
    }

    private static func isWebURL(_ url: URL) -> Bool {
        ["http", "https"].contains(url.scheme?.lowercased() ?? "") && !(url.host ?? "").isEmpty
    }

    // Preserve the UIKit catalog's unchanged-list behavior: website is deliberately ignored.
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.name == rhs.name && lhs.streamURL == rhs.streamURL && lhs.imageURL == rhs.imageURL
            && lhs.desc == rhs.desc && lhs.longDesc == rhs.longDesc
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(streamURL)
        hasher.combine(imageURL)
        hasher.combine(desc)
        hasher.combine(longDesc)
    }
}
