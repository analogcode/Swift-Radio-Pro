//
//  ArtworkView.swift
//  Swift Radio
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import SwiftRadioCore
import SwiftUI

/// Station artwork resolved asynchronously through the shared `ArtworkLoader`, with a dimmed placeholder while loading.
/// When `trackURL` is set (popup player), stream metadata artwork wins and station art is the fallback.
@MainActor struct ArtworkView: View {
    let station: SwiftRadioCore.RadioStation
    var cornerRadius: CGFloat = 8
    var trackURL: URL? = nil
    var playback: PlaybackArtworkState? = nil
    @Environment(\.artworkLoader) private var artworkLoader
    @State private var image: UIImage?
    /// Station artwork source the current image belongs to; a track-only change keeps it.
    @State private var imageStationKey: String?

    var body: some View {
        imageContent
        // Row identity stays the station ID; the image request additionally keys on the station's
        // artwork source so a refreshed imageURL restarts the load instead of showing stale art.
        .task(id: station.id + "|" + station.imageURL + "|" + (trackURL?.absoluteString ?? "")) {
            guard let artworkLoader else { return }
            // A different station must not show the previous station's art while its own loads
            // (or fails after the request timeout); a new track on the same station still crossfades.
            let stationKey = station.id + "|" + station.imageURL
            if imageStationKey != stationKey {
                image = nil
                imageStationKey = stationKey
            }
            let loaded: UIImage
            if let trackURL, let track = await artworkLoader.trackArtwork(at: trackURL) {
                loaded = track
            } else {
                loaded = await artworkLoader.image(for: station)
            }
            guard !Task.isCancelled else { return }
            image = loaded
        }
    }

    @ViewBuilder private var imageContent: some View {
        if let playback {
            PlaybackArtworkImage(image: image, state: playback, cornerRadius: cornerRadius)
        } else {
            CrossfadeImage(image: image, duration: 0.3)
                .background(Color.white.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        }
    }
}
