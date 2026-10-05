//
//  NowPlayingIndicatorButton.swift
//  Swift Radio
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import SwiftRadioCore
import SwiftUI

/// Toolbar control that mirrors transport state (equalizer when playing, ball pulse while buffering)
/// and opens the Now Playing popup on tap.
@MainActor struct NowPlayingIndicatorButton: View {
    @Environment(PlayerService.self) private var player
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if player.isBuffering {
                    BufferingIndicator()
                } else {
                    EqualizerBars(isAnimating: player.state == .playing)
                }
            }
            .frame(width: 30, height: 20)
        }
        .tint(Color(uiColor: Config.tintColor))
        .accessibilityLabel(Text("player.nowPlaying"))
        .accessibilityIdentifier("showNowPlaying")
    }
}
