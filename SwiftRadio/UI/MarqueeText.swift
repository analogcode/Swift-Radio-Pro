//
//  MarqueeText.swift
//  Swift Radio
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import MarqueeLabel
import SwiftUI

/// Reference title behavior: continuous scrolling, 30pt/s, 10pt fades and a 30pt buffer.
/// The caller uses wrapping Text instead at accessibility sizes or with Reduce Motion.
/// The label keeps the default text color like the reference title, not the configured tint.
@MainActor struct MarqueeText: UIViewRepresentable {
    let text: String
    func makeUIView(context: Context) -> MarqueeLabel {
        let label = MarqueeLabel(frame: .zero, rate: 30, fadeLength: 10)
        label.type = .continuous
        label.trailingBuffer = 30
        label.textAlignment = .center
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.accessibilityIdentifier = "nowPlayingTitle"
        return label
    }
    func updateUIView(_ label: MarqueeLabel, context: Context) {
        let base = UIFont.preferredFont(forTextStyle: .title2, compatibleWith: label.traitCollection)
        let descriptor = base.fontDescriptor.withSymbolicTraits(.traitBold) ?? base.fontDescriptor
        let font = UIFont(descriptor: descriptor, size: 0)
        if label.font != font { label.font = font }
        // Reassigning identical text every playback tick would restart the marquee.
        if label.text != text {
            label.text = text
            label.accessibilityLabel = text
        }
    }
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: MarqueeLabel, context: Context) -> CGSize? {
        guard let width = proposal.width else { return nil }
        return CGSize(width: width, height: ceil(uiView.font.lineHeight))
    }
    static func dismantleUIView(_ label: MarqueeLabel, coordinator: ()) {
        label.shutdownLabel()
    }
}
