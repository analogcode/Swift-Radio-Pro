//
//  NowPlayingOptionsSheet.swift
//  Swift Radio
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import SwiftRadioCore
import SwiftUI

/// Content-sized options sheet for the popup: Info, Website, Open in Music, Share.
/// SwiftUI successor to BottomSheetViewController; Info/Website hand off to RootView so the
/// popup can close before the push/Safari presentation runs.
@MainActor struct NowPlayingOptionsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.displayScale) private var displayScale
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var rowHeight = 50.0
    /// The list's measured content height; row and section metrics differ between OS releases.
    @State private var measuredHeight: CGFloat?

    let station: SwiftRadioCore.RadioStation
    /// Artwork currently shown in the popup (track art when available), reused for sharing.
    let artwork: UIImage?
    let track: String?
    let artist: String?
    let hasTrackArtwork: Bool
    let requestInfo: () -> Void
    let requestWebsite: (URL) -> Void
    let requestMusic: (URL) -> Void
    let requestShare: ([Any]) -> Void

    var body: some View {
        List {
            Section {
                option(Content.BottomSheet.aboutStation, systemImage: "info.circle") {
                    choose { requestInfo() }
                }
                if let websiteURL {
                    option(Content.BottomSheet.stationWebsite, systemImage: "safari") {
                        choose { requestWebsite(websiteURL) }
                    }
                }
            }
            Section {
                option(Content.BottomSheet.playInMusicApp, systemImage: "music.note") {
                    if let musicURL { choose { requestMusic(musicURL) } }
                }
                .disabled(musicURL == nil || !hasTrackArtwork)
            }
            Section {
                option(Content.BottomSheet.shareNowPlaying, systemImage: "square.and.arrow.up") {
                    share()
                }
            }
        }
        .contentMargins(.horizontal, 20, for: .scrollContent)
        .readingContentHeight(into: $measuredHeight)
        // Fit the rows like the UIKit table did. Accessibility sizes get the full sheet rather
        // than compressing their labels.
        .presentationDetents(dynamicTypeSize.isAccessibilitySize ? [.large] : [.height(measuredHeight ?? estimatedHeight)])
        .presentationDragIndicator(.visible)
        .accessibilityIdentifier("playerOptionsSheet")
    }

    /// Used until the list reports its size, and on iOS 17, which has no scroll geometry to read.
    private var estimatedHeight: CGFloat {
        rowHeight * (websiteURL == nil ? 3 : 4) + 188
    }

    private var websiteURL: URL? {
        guard station.hasValidWebsite, let website = station.website else { return nil }
        return URL(string: website)
    }

    private var musicURL: URL? {
        station.musicSearchURL(track: track, artist: artist)
    }

    private func option(_ title: String, systemImage: String,
                        action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
        }
        .foregroundStyle(.primary)
    }

    /// Queue the request on the presenter, which executes it from the sheet's onDismiss.
    private func choose(_ action: @escaping @MainActor () -> Void) {
        action()
        dismiss()
    }

    /// Shares the shoutout plus the composed share card; text-only when rendering fails.
    private func share() {
        var items: [Any] = [station.shoutout]
        // Without stream metadata the card still names the station: the display fallbacks are
        // the station's name and description, matching the popup and Now Playing info.
        let card = LogoShareView(artwork: artwork, shoutout: station.shoutout,
                                 track: track ?? station.name,
                                 artist: artist ?? station.desc)
        if let image = card.rendered(scale: displayScale) {
            items.append(image)
        }
        choose { requestShare(items) }
    }
}

/// Reports a scroll view's content height plus its top inset. A height detent excludes the
/// bottom safe area, which the scroll view adds to its own bottom inset, so that part is left out.
private extension View {
    @ViewBuilder func readingContentHeight(into height: Binding<CGFloat?>) -> some View {
        if #available(iOS 18, *) {
            onScrollGeometryChange(for: CGFloat.self) { geometry in
                geometry.contentSize.height > 0 ? geometry.contentSize.height + geometry.contentInsets.top : 0
            } action: { _, newHeight in
                // The first pass runs before the rows exist; keep the estimate until they do.
                if newHeight > 0 { height.wrappedValue = newHeight.rounded(.up) }
            }
        } else {
            self
        }
    }
}
