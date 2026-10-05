//
//  HandoffActivity.swift
//  SwiftRadioCore
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import Foundation

/// The outgoing Handoff target: a web search for the playing artist and track.
///
/// The app advertises it with SwiftUI's `userActivity` modifier, which ties the activity to
/// the scene that shows it, so this type only decides the URL.
public enum HandoffActivity {
    /// `nil` unless both artist and track are known, so a partial search is never advertised.
    public static func searchURL(track: String?, artist: String?) -> URL? {
        guard let track, let artist, !track.isEmpty, !artist.isEmpty else { return nil }
        var components = URLComponents()
        components.scheme = "https"
        components.host = "google.com"
        components.path = "/search"
        components.queryItems = [URLQueryItem(name: "q", value: "\(artist) \(track)")]
        return components.url
    }
}
