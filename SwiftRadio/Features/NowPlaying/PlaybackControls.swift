//
//  PlaybackControls.swift
//  Swift Radio
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import SwiftRadioCore
import SwiftUI

/// Transport cluster for the popup: seek slider with time labels for files, a LIVE badge for
/// streams, previous/play/next, the AirPlay route picker, and the "more" options button.
@MainActor struct PlaybackControls: View {
    @Environment(StationsStore.self) private var stations
    @Environment(PlayerService.self) private var player
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Opens the options sheet owned by NowPlayingView.
    let onMore: () -> Void

    /// Holds the in-flight drag position so playback time does not fight the user's finger.
    @State private var scrubPosition: Double?
    @ScaledMetric(relativeTo: .caption2) private var timeFontSize = 10.0

    var body: some View {
        VStack(spacing: 8) {
            timeline
                .frame(minHeight: 44, maxHeight: .infinity, alignment: .top)
            transport
                .frame(minHeight: 64, maxHeight: .infinity)
            HStack(spacing: 40) {
                AirPlayButton()
                    .frame(width: 44, height: 44)
                Button(action: onMore) {
                    Image(systemName: "list.dash")
                        .font(.system(size: 17))
                        .foregroundStyle(Color(uiColor: Config.tintColor).opacity(0.7))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel(Text("player.options"))
                .accessibilityIdentifier("playerOptions")
            }
            .frame(minHeight: 44, maxHeight: .infinity, alignment: .bottom)
        }
        .onChange(of: stations.currentStation?.id) { scrubPosition = nil }
    }

    @ViewBuilder private var timeline: some View {
        if player.isLive {
            ZStack {
                Rectangle()
                    .fill(Color(uiColor: Config.tintColor).opacity(0.3))
                    .frame(height: 2)
                    .accessibilityHidden(true)
                Text(Content.Player.liveBadge)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 6))
            }
            .frame(height: 31)
        } else {
            VStack(spacing: 6) {
                PlaybackSeekSlider(value: sliderValue, duration: max(player.duration, 1)) { value in
                    player.seek(to: value)
                    scrubPosition = nil
                }
                .id(stations.currentStation?.id)
                .frame(height: 31)
                HStack {
                    Text(formatted(scrubPosition ?? player.elapsed))
                        .accessibilityIdentifier("playbackElapsed")
                    Spacer()
                    Text("-" + formatted(remaining))
                }
                .font(.system(size: timeFontSize, weight: .medium))
                .monospacedDigit()
                .opacity(0.8)
            }
        }
    }

    private var transport: some View {
        HStack(spacing: 40) {
            if !Config.hideNextPreviousButtons {
                Button { stations.selectPrevious() } label: {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Color(uiColor: Config.tintColor).opacity(0.7))
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel(Text("player.previous"))
            }
            Button { player.togglePlayPause() } label: {
                Image(systemName: playIcon)
                    .font(.system(size: 60))
                    .foregroundStyle(Color(uiColor: Config.tintColor))
                    .contentTransition(reduceMotion ? .identity : .symbolEffect(.replace))
            }
            .accessibilityLabel(playLabel)
            .accessibilityIdentifier("playerTransport")
            if !Config.hideNextPreviousButtons {
                Button { stations.selectNext() } label: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Color(uiColor: Config.tintColor).opacity(0.7))
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel(Text("player.next"))
            }
        }
    }

    private var sliderValue: Binding<Double> {
        Binding(
            get: { scrubPosition ?? player.elapsed },
            set: { scrubPosition = $0 }
        )
    }

    private var remaining: TimeInterval {
        max(0, player.duration - (scrubPosition ?? player.elapsed))
    }

    private var playIcon: String {
        guard player.state == .playing else { return "play.circle.fill" }
        return player.isLive ? "stop.circle.fill" : "pause.circle.fill"
    }

    private var playLabel: String {
        guard player.state == .playing else { return Content.Player.play }
        return player.isLive ? Content.Player.stop : Content.Player.pause
    }

    /// Same "05:07" shape as the reference, with the locale's digits and separator.
    private func formatted(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded(.down)))
        return Duration.seconds(total).formatted(.time(pattern: .minuteSecond(padMinuteToLength: 2)))
    }
}

/// Preserves the template's thin native seek control and adjustable accessibility.
/// Scrubbing state and the playback action stay owned by SwiftUI.
private struct PlaybackSeekSlider: UIViewRepresentable {
    @Binding var value: Double
    let duration: Double
    let onEndEditing: (Double) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> SeekSlider {
        let slider = SeekSlider()
        slider.minimumValue = 0
        slider.minimumTrackTintColor = Config.tintColor
        slider.maximumTrackTintColor = Config.tintColor.withAlphaComponent(0.3)
        slider.accessibilityLabel = String(localized: "player.seek")
        slider.accessibilityIdentifier = "playbackSeek"
        slider.addTarget(context.coordinator, action: #selector(Coordinator.began(_:)), for: .touchDown)
        slider.addTarget(context.coordinator, action: #selector(Coordinator.changed(_:)), for: .valueChanged)
        slider.addTarget(context.coordinator, action: #selector(Coordinator.ended(_:)),
                         for: [.touchUpInside, .touchUpOutside, .touchCancel])
        return slider
    }

    func updateUIView(_ slider: SeekSlider, context: Context) {
        context.coordinator.parent = self
        slider.maximumValue = Float(duration)
        if !slider.isTracking { slider.value = Float(value) }
        let elapsed = spokenTime(value)
        let total = spokenTime(duration)
        slider.accessibilityValue = String(localized: "player.seekValue",
                                           defaultValue: "\(elapsed) of \(total)",
                                           comment: "Elapsed playback time followed by total duration")
    }

    private func spokenTime(_ seconds: Double) -> String {
        Duration.seconds(max(0, seconds).rounded(.down))
            .formatted(.units(allowed: [.hours, .minutes, .seconds], width: .wide))
    }

    @MainActor final class Coordinator: NSObject {
        var parent: PlaybackSeekSlider
        init(_ parent: PlaybackSeekSlider) { self.parent = parent }
        @objc func began(_ slider: UISlider) { parent.value = Double(slider.value) }
        @objc func changed(_ slider: UISlider) {
            parent.value = Double(slider.value)
            // VoiceOver adjustments don't send a touch-up event.
            if !slider.isTracking { parent.onEndEditing(Double(slider.value)) }
        }
        @objc func ended(_ slider: UISlider) { parent.onEndEditing(Double(slider.value)) }
    }

    final class SeekSlider: UISlider {
        override init(frame: CGRect) {
            super.init(frame: frame)
            for (state, size) in [(UIControl.State.normal, CGFloat(10)), (.highlighted, CGFloat(16))] {
                let image = UIGraphicsImageRenderer(size: CGSize(width: size, height: size)).image { context in
                    Config.tintColor.setFill()
                    context.cgContext.fillEllipse(in: CGRect(x: 0, y: 0, width: size, height: size))
                }
                setThumbImage(image, for: state)
            }
        }
        required init?(coder: NSCoder) { super.init(coder: coder) }
        override func trackRect(forBounds bounds: CGRect) -> CGRect {
            CGRect(x: bounds.minX, y: bounds.midY - 1, width: bounds.width, height: 2)
        }
    }
}
