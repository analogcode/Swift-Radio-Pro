//
//  NowPlayingView.swift
//  Swift Radio
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import LNPopupUI
import SwiftRadioCore
import SwiftUI

/// Full-screen popup player: blurred artwork backdrop, marquee metadata, transport controls,
/// and the LNPopup bar configuration (title, image, progress, transport button).
/// SwiftUI successor to NowPlayingViewController.
@MainActor struct NowPlayingView: View {
    @Environment(StationsStore.self) private var stations
    @Environment(PlayerService.self) private var player
    @Environment(\.artworkLoader) private var artworkLoader
    @Environment(\.openURL) private var openURL

    /// RootView-owned requests; RootView runs them after the popup has closed.
    let requestInfo: (SwiftRadioCore.RadioStation) -> Void
    let requestWebsite: (URL) -> Void

    @State private var presentedSheet: PlayerSheet?
    /// Effective artwork (track art when the stream supplies it, else station art) used for
    /// the blurred backdrop and the popup bar image.
    @State private var displayedArtwork: UIImage?
    /// Station artwork source `displayedArtwork` belongs to; a track-only change keeps it.
    @State private var displayedArtworkStationKey: String?
    @State private var pendingOption: NowPlayingOption?

    var body: some View {
        GeometryReader { geometry in
            if let station = stations.currentStation {
                NowPlayingContent(station: station, artworkURL: player.artworkURL,
                                  title: title, subtitle: subtitle,
                                  isPlaying: player.state == .playing,
                                  isBuffering: player.isBuffering,
                                  availableSize: geometry.size) {
                    presentedSheet = .options(OptionsContext(station: station, artwork: displayedArtwork,
                                                             track: player.track, artist: player.artist,
                                                             hasTrackArtwork: player.artworkURL != nil))
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("nowPlayingContent")
            }
        }
        // A background must not contribute the source image's intrinsic size to layout.
        .background { NowPlayingBackground(image: displayedArtwork) }
        .sheet(item: $presentedSheet, onDismiss: performPendingOption) { sheet in
            switch sheet {
            case .options(let context):
                NowPlayingOptionsSheet(
                    station: context.station,
                    artwork: context.artwork,
                    track: context.track,
                    artist: context.artist,
                    hasTrackArtwork: context.hasTrackArtwork,
                    requestInfo: { pendingOption = .info(context.station) },
                    requestWebsite: { pendingOption = .website($0) },
                    requestMusic: { pendingOption = .music($0) },
                    requestShare: { pendingOption = .share($0) }
                )
            case .share(let payload):
                ActivityView(items: payload.items)
            }
        }
        .task(id: artworkIdentity) { await loadArtwork() }
        .popupTitle(verbatim: title, subtitle: subtitle)
        .popupImage(displayedArtwork.map { Image(uiImage: $0) })
        .modifier(PopupProgress())
        .popupBarButtons { playbackToggle }
    }

    private func performPendingOption() {
        let option = pendingOption
        pendingOption = nil
        switch option {
        case .info(let station): requestInfo(station)
        case .website(let url): requestWebsite(url)
        case .music(let url): openURL(url)
        case .share(let items): presentedSheet = .share(SharePayload(items: items))
        case nil: break
        }
    }

    private enum NowPlayingOption {
        case info(SwiftRadioCore.RadioStation)
        case website(URL)
        case music(URL)
        case share([Any])
    }

    private struct SharePayload: Identifiable {
        let id = UUID()
        let items: [Any]
    }

    /// Snapshot a coherent station/metadata pair for the duration of an options presentation.
    private struct OptionsContext: Identifiable {
        let id = UUID()
        let station: SwiftRadioCore.RadioStation
        let artwork: UIImage?
        let track: String?
        let artist: String?
        let hasTrackArtwork: Bool
    }

    private enum PlayerSheet: Identifiable {
        case options(OptionsContext)
        case share(SharePayload)
        var id: UUID {
            switch self {
            case .options(let context): context.id
            case .share(let payload): payload.id
            }
        }
    }

    /// Play/pause in the popup bar; shows Stop while a live stream plays (UI-test contract).
    private var playbackToggle: some View {
        Button { player.togglePlayPause() } label: {
            Image(systemName: player.state == .playing ? (player.isLive ? "stop.fill" : "pause.fill") : "play.fill")
        }
        .accessibilityLabel(player.state == .playing ? (player.isLive ? Content.Player.stop : Content.Player.pause) : Content.Player.play)
        .accessibilityIdentifier("playbackToggle")
    }

    private var title: String {
        guard let station = stations.currentStation else { return "" }
        guard let track = player.track else { return station.name }
        return [track, player.artist].compactMap { $0 }.joined(separator: " — ")
    }

    private var subtitle: String {
        guard let station = stations.currentStation else { return "" }
        return player.track == nil ? station.desc : station.name
    }

    /// Reload when the station changes or new track artwork arrives.
    private var artworkIdentity: String {
        (stations.currentStation?.id ?? "") + "|" + (stations.currentStation?.imageURL ?? "")
            + "|" + (player.artworkURL?.absoluteString ?? "")
    }

    private func loadArtwork() async {
        guard let station = stations.currentStation, let artworkLoader else {
            displayedArtwork = nil
            displayedArtworkStationKey = nil
            return
        }
        // Like the reference stationDidChange: drop the previous station's backdrop and bar image
        // at once instead of keeping it under the new station's title until the load finishes.
        let stationKey = station.id + "|" + station.imageURL
        if displayedArtworkStationKey != stationKey {
            displayedArtwork = nil
            displayedArtworkStationKey = stationKey
        }
        let image: UIImage
        if let url = player.artworkURL, let track = await artworkLoader.trackArtwork(at: url) {
            image = track
        } else {
            image = await artworkLoader.image(for: station)
        }
        guard !Task.isCancelled else { return }
        displayedArtwork = image // CrossfadeImage owns the explicit, Reduce Motion-aware transition.
    }
}

/// Only this modifier reads playback time, so a time tick re-runs it instead of the whole
/// player (content, controls, artwork and sheets).
@MainActor private struct PopupProgress: ViewModifier {
    @Environment(PlayerService.self) private var player

    func body(content: Self.Content) -> some View {
        content.popupProgress(progress)
    }

    private var progress: Float {
        guard !player.isLive, player.duration > 0 else { return 0 }
        return Float(min(max(player.elapsed / player.duration, 0), 1))
    }
}

@MainActor private struct NowPlayingContent: View {
    let station: SwiftRadioCore.RadioStation
    let artworkURL: URL?
    let title: String
    let subtitle: String
    let isPlaying: Bool
    let isBuffering: Bool
    let availableSize: CGSize
    let onMore: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                ArtworkView(station: station, cornerRadius: 20, trackURL: artworkURL,
                            playback: PlaybackArtworkState(isPlaying: isPlaying, isBuffering: isBuffering))
                    .frame(width: artworkSide, height: artworkSide)
                    .accessibilityHidden(true)
                VStack(spacing: 20) {
                    NowPlayingMetadata(title: title, subtitle: subtitle)
                    PlaybackControls(onMore: onMore)
                        .frame(maxHeight: .infinity)
                }
                .frame(maxHeight: .infinity)
            }
            .padding(.horizontal, 24)
            .padding(.top, 48)
            .padding(.bottom, 20)
            .frame(width: availableSize.width)
            .frame(minHeight: availableSize.height)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    private var artworkSide: CGFloat {
        let width = max(0, availableSize.width - 48)
        // Leave room for controls in landscape, iPad windows and larger text sizes.
        return min(width, max(120, availableSize.height * (dynamicTypeSize.isAccessibilitySize ? 0.3 : 0.5)))
    }
}

private struct NowPlayingMetadata: View {
    let title: String
    let subtitle: String
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 4) {
            if dynamicTypeSize.isAccessibilitySize || reduceMotion {
                Text(title)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                MarqueeText(text: title)
            }
            Text(subtitle)
                .font(.title3)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }
}

private struct NowPlayingBackground: View {
    let image: UIImage?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geometry in
            if let image {
                CrossfadeImage(image: image, duration: 0.5)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .overlay(.thickMaterial)
                    .overlay(.black.opacity(0.3))
            } else {
                GradientBackground()
            }
        }
        // Dissolves to and from the gradient when a station switch clears the art, matching the
        // reference backdrop transition; image-to-image changes are CrossfadeImage's.
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.5), value: image == nil)
        .ignoresSafeArea()
    }
}
