//
//  StationRow.swift
//  Swift Radio
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import SwiftRadioCore
import SwiftUI

/// Matches the UIKit catalog's 104-point card rhythm at the default text size.
/// Text can grow at accessibility sizes rather than inheriting UIKit's fixed row height.
@MainActor struct StationRow: View, Equatable {
    let station: SwiftRadioCore.RadioStation
    let isCurrent: Bool
    let isPlaying: Bool
    let isBuffering: Bool
    let action: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var activationFeedback = false

    /// `action` is left out: a fresh closure is built on every parent pass but always routes
    /// the tap through the same stores, so comparing it would only defeat the skip.
    nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.station == rhs.station && lhs.isCurrent == rhs.isCurrent
            && lhs.isPlaying == rhs.isPlaying && lhs.isBuffering == rhs.isBuffering
    }

    var body: some View {
        Button {
            activationFeedback.toggle()
            action()
        } label: {
            HStack(spacing: 14) {
                StationRowArtwork(station: station, isCurrent: isCurrent,
                                  isPlaying: isPlaying, isBuffering: isBuffering)
                VStack(alignment: .leading, spacing: 4) {
                    Text(station.name)
                        .font(.headline)
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
                    HStack(spacing: 6) {
                        // UIKit hides the arranged equalizer when stopped, collapsing its space.
                        if isCurrent && isPlaying && !isBuffering {
                            EqualizerBars(isAnimating: isPlaying, color: .white)
                                .frame(width: 16, height: 12)
                                .opacity(isPlaying ? 0.7 : 0.4)
                                .accessibilityHidden(true)
                        }
                        Text(station.desc)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.55))
                            .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(.white.opacity(0.12), lineWidth: 0.5)
            }
            .shadow(color: .black.opacity(0.2), radius: 8, y: 2)
            .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(StationCardButtonStyle(activationTrigger: activationFeedback))
        .padding(.horizontal, 16)
        .padding(.vertical, 5)
    }
}

@MainActor private struct StationRowArtwork: View {
    let station: SwiftRadioCore.RadioStation
    let isCurrent: Bool
    let isPlaying: Bool
    let isBuffering: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ArtworkView(station: station, cornerRadius: 12)
            .frame(width: 70, height: 70)
            .overlay {
                if isCurrent && isBuffering {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.black.opacity(0.5))
                        .overlay { BufferingIndicator(color: .white).frame(width: 30, height: 20) }
                        .transition(.opacity)
                }
            }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: isBuffering)
            .background {
                if isCurrent && !isBuffering {
                    if isPlaying && !reduceMotion {
                        selectionRing.phaseAnimator([false, true]) { content, phase in
                            content
                                .opacity(phase ? 0.4 : 0)
                                .scaleEffect(phase ? 1.06 : 1)
                        } animation: { _ in
                            .easeInOut(duration: 1.5)
                        }
                    } else {
                        selectionRing.opacity(isPlaying ? 0.4 : 0.25)
                    }
                }
            }
            .accessibilityHidden(true)
    }

    private var selectionRing: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(.white, lineWidth: 2.5)
            .padding(-4)
    }
}

private struct StationCardButtonStyle: ButtonStyle {
    let activationTrigger: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            // A short tap may finish before List exposes a visible pressed frame.
            // Complete one feedback pulse on activation too, without replacing Button's
            // cancellation/scrolling/accessibility behavior with a competing gesture.
            .phaseAnimator([false, true], trigger: activationTrigger) { content, active in
                content
                    .scaleEffect(!reduceMotion && (configuration.isPressed || active) ? 0.97 : 1)
                    .opacity(reduceMotion && (configuration.isPressed || active) ? 0.8 : 1)
            } animation: { active in
                active ? .easeOut(duration: 0.08) : .spring(duration: 0.3, bounce: 0.2)
            }
            .animation(reduceMotion ? nil : .spring(duration: 0.3), value: configuration.isPressed)
    }
}
