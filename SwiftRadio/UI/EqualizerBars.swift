//
//  EqualizerBars.swift
//  Swift Radio
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import SwiftUI

/// Uses the reference indicator's explicit start/stop lifecycle, not a retained repeatForever.
@MainActor struct EqualizerBars: View {
    var isAnimating = true
    var color: UIColor = Config.tintColor
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        if reduceMotion && isAnimating {
            Image(systemName: "waveform").resizable().scaledToFit()
                .foregroundStyle(Color(uiColor: color))
        } else {
            PlaybackActivityIndicator(kind: .equalizer, isAnimating: isAnimating, color: color)
        }
    }
}
