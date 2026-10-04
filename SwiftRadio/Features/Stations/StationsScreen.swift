//
//  StationsScreen.swift
//  Swift Radio
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import SwiftRadioCore
import SwiftUI

/// The station catalog: material cards with search, pull-to-refresh, About menu, and
/// a Now Playing toolbar indicator that opens the popup owned by RootView.
@MainActor struct StationsScreen: View {
    @Environment(StationsStore.self) private var stations
    @Environment(PlayerService.self) private var player
    @Binding var isPopupOpen: Bool
    @State private var showAbout = false

    var body: some View {
        catalog
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(GradientBackground())
            // The reference shows its loading cell only for an empty catalog; a search that
            // matches nothing leaves the list empty.
            .overlay { if stations.stations.isEmpty && stations.searchText.isEmpty { EmptyStationsView() } }
            .navigationTitle(Content.Stations.title)
            .navigationBarTitleDisplayMode(.large)
            .refreshable { await stations.refresh() }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showAbout = true } label: {
                        Image(systemName: "line.3.horizontal")
                    }
                    .accessibilityLabel(Content.About.title)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NowPlayingToolbarSlot { isPopupOpen = true }
                }
            }
            .sheet(isPresented: $showAbout) {
                AboutScreen()
            }
            .modifier(TrackHandoff())
    }

    /// Search filtering is only compiled in when `Config.searchable` is enabled.
    @ViewBuilder private var catalog: some View {
        if Config.searchable {
            stationList.searchable(text: Bindable(stations).searchText,
                                   placement: .navigationBarDrawer(displayMode: .automatic))
        } else {
            stationList
        }
    }

    private var stationList: some View {
        List(stations.filteredStations) { station in
            let isCurrent = station == stations.currentStation
            // Only the current row carries playback state, so a play/pause or buffering change
            // leaves every other row's inputs equal and SwiftUI skips their bodies.
            StationRow(
                station: station,
                isCurrent: isCurrent,
                isPlaying: isCurrent && player.state == .playing,
                isBuffering: isCurrent && player.isBuffering
            ) {
                tap(station)
            }
            .equatable()
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
        }
    }

    /// Row tap follows the UIKit reference: a new station selects, the playing one opens the
    /// player, and any other state of the current one toggles playback.
    private func tap(_ station: SwiftRadioCore.RadioStation) {
        if stations.activate(station, on: .phone) == .alreadyActive {
            isPopupOpen = true
        }
    }
}

/// Shows the Now Playing indicator only while something plays or loads. Reading transport
/// state here keeps those changes from re-running the whole catalog body.
@MainActor private struct NowPlayingToolbarSlot: View {
    @Environment(StationsStore.self) private var stations
    @Environment(PlayerService.self) private var player
    let action: () -> Void

    var body: some View {
        if stations.currentStation != nil && (player.state == .playing || player.isBuffering) {
            NowPlayingIndicatorButton(action: action)
        }
    }
}

/// Advertises a web search for the playing track. Only this modifier reads track metadata, so
/// a metadata change does not re-run the catalog body.
@MainActor private struct TrackHandoff: ViewModifier {
    @Environment(PlayerService.self) private var player

    func body(content: Self.Content) -> some View {
        let url = HandoffActivity.searchURL(track: player.track, artist: player.artist)
        content.userActivity(NSUserActivityTypeBrowsingWeb, isActive: url != nil) { activity in
            activity.webpageURL = url
            activity.isEligibleForHandoff = true
        }
    }
}
