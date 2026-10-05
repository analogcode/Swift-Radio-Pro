//
//  PlaybackActivityIndicator.swift
//  Swift Radio
//
//  Created on 2026-09-23.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import NVActivityIndicatorView
import SwiftUI

/// The same equalizer/ball-pulse implementation as UIKit, with deterministic teardown.
@MainActor struct PlaybackActivityIndicator: UIViewRepresentable {
    enum Kind { case equalizer, buffering }
    let kind: Kind
    var isAnimating = true
    /// The reference draws row indicators white and only the toolbar one in the tint.
    var color: UIColor = Config.tintColor
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeUIView(context: Context) -> Container {
        Container(type: kind == .equalizer ? .audioEqualizer : .ballPulse, color: color)
    }

    func updateUIView(_ view: Container, context: Context) {
        view.indicator.color = color
        view.shouldAnimate = isAnimating && !reduceMotion
        view.setNeedsLayout()
        if !view.shouldAnimate { view.indicator.stopAnimating() }
    }

    static func dismantleUIView(_ view: Container, coordinator: ()) {
        view.shouldAnimate = false
        view.indicator.stopAnimating()
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: Container, context: Context) -> CGSize? {
        CGSize(width: proposal.width ?? 30, height: proposal.height ?? 20)
    }

    /// NV builds its animation from frame, not the SwiftUI proposal. Start only after layout;
    /// SwiftUI may otherwise call updateUIView while the vendor view still has a zero frame.
    final class Container: UIView {
        let indicator: NVActivityIndicatorView
        var shouldAnimate = false
        private var animationSize = CGSize.zero
        init(type: NVActivityIndicatorType, color: UIColor) {
            indicator = NVActivityIndicatorView(frame: .zero, type: type, color: color, padding: 0)
            super.init(frame: .zero)
            isAccessibilityElement = false
            indicator.isAccessibilityElement = false
            addSubview(indicator)
        }
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
        override func layoutSubviews() {
            super.layoutSubviews()
            indicator.frame = bounds
            if animationSize != bounds.size {
                indicator.stopAnimating()
                animationSize = bounds.size
            }
            if shouldAnimate && bounds.width > 0 && bounds.height > 0 { indicator.startAnimating() }
            else { indicator.stopAnimating() }
        }
    }
}

/// Reduced motion keeps a visible, stationary loading cue.
struct BufferingIndicator: View {
    var color: UIColor = Config.tintColor
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        if reduceMotion {
            Image(systemName: "ellipsis").foregroundStyle(Color(uiColor: color))
        } else {
            PlaybackActivityIndicator(kind: .buffering, color: color)
        }
    }
}
