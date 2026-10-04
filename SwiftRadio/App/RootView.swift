//
//  RootView.swift
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

/// Keeps navigation alive after bootstrap and coordinates selection with popup presentation.
/// Also owns the sequenced popup-close → push-Info/present-Safari handoff from the options sheet.
@MainActor struct RootView: View {
    @Environment(StationsStore.self) private var stations
    @State private var bootstrapped = false
    @State private var path = NavigationPath()
    @State private var barPresented = false
    @State private var popupOpen = false
    @State private var safariURL: URL?
    /// Requests queued by the options sheet; run from `popupDidClose` so the push/presentation
    /// only starts after the popup has fully closed.
    @State private var pendingInfo: SwiftRadioCore.RadioStation?
    @State private var pendingSafari: URL?

    var body: some View {
        Group {
            if bootstrapped {
                NavigationStack(path: $path) {
                    StationsScreen(isPopupOpen: $popupOpen)
                        .navigationDestination(for: SwiftRadioCore.RadioStation.self) { station in
                            StationInfoScreen(station: station)
                        }
                }
                .popup(isBarPresented: $barPresented, isPopupOpen: $popupOpen, onClose: popupDidClose) {
                    NowPlayingView(
                        requestInfo: { station in
                            pendingInfo = station
                            popupOpen = false
                        },
                        requestWebsite: { url in
                            pendingSafari = url
                            popupOpen = false
                        }
                    )
                }
                .popupBarStyle(Self.popupBarStyle)
                .popupInteractionStyle(.drag)
                .popupBarProgressViewStyle(.bottom)
                .popupCloseButtonStyle(.chevron)
                // Names the bar for UI tests and accessibility tooling. The library keeps
                // supplying the bar's own VoiceOver label from the popup item's title,
                // which a custom popup title view would drop.
                .popupBarCustomizer { bar in
                    bar.accessibilityIdentifier = "popupBar"
                    bar.tintColor = Config.tintColor
                }
                .tint(Color(uiColor: Config.tintColor))
            } else {
                LoadingScreen(error: loadingError) { await stations.load() }
            }
        }
        .sheet(isPresented: safariPresented) {
            if let url = safariURL {
                SafariView(url: url)
            }
        }
        .task {
            if stations.loadState == .idle { await stations.load() }
        }
        .onChange(of: stations.loadState, initial: true) { _, state in
            if state == .loaded { bootstrapped = true }
        }
        .onChange(of: stations.currentStation, initial: true) { _, station in
            if station != nil {
                barPresented = true
            } else if popupOpen {
                // Finish closing content before removing its bar. Future pushes/presentations
                // should also run from onClose, after any options sheet has dismissed.
                popupOpen = false
            } else {
                barPresented = false
            }
        }
    }

    /// Matches the UIKit reference's `.prominent` bar. `.default` is not equivalent: it resolves to
    /// floating on iOS 17/18 and to floating compact on iOS 26, where prominent maps to floating.
    private static var popupBarStyle: LNPopupBar.Style {
        if #available(iOS 26, *) {
            return .floating
        } else {
            return .prominent
        }
    }

    private var loadingError: String? {
        if case .failed(let message) = stations.loadState { return message }
        return nil
    }

    private var safariPresented: Binding<Bool> {
        Binding(
            get: { safariURL != nil },
            set: { if !$0 { safariURL = nil } }
        )
    }

    private func popupDidClose() {
        if let station = pendingInfo {
            pendingInfo = nil
            path.append(station)
        }
        if let url = pendingSafari {
            pendingSafari = nil
            safariURL = url
        }
        if stations.currentStation == nil { barPresented = false }
    }
}
