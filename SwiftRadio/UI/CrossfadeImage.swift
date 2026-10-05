//
//  CrossfadeImage.swift
//  Swift Radio
//
//  Created on 2026-09-23.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import SwiftUI

/// UIKit's image cross-dissolve, without allowing image dimensions to influence SwiftUI layout.
@MainActor struct CrossfadeImage: UIViewRepresentable {
    let image: UIImage?
    let duration: TimeInterval
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeUIView(context: Context) -> Container { Container() }

    func updateUIView(_ view: Container, context: Context) {
        if reduceMotion { view.imageView.layer.removeAllAnimations() }
        guard view.imageView.image !== image else { return }
        // Clearing on a station switch is instant; only image-to-image changes dissolve.
        if view.imageView.image == nil || image == nil || reduceMotion {
            view.imageView.image = image
        } else {
            UIView.transition(with: view.imageView, duration: duration,
                              options: [.transitionCrossDissolve, .beginFromCurrentState, .allowAnimatedContent]) {
                view.imageView.image = image
            }
        }
    }

    static func dismantleUIView(_ view: Container, coordinator: ()) {
        view.imageView.layer.removeAllAnimations()
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: Container, context: Context) -> CGSize? {
        CGSize(width: proposal.width ?? 0, height: proposal.height ?? 0)
    }

    final class Container: UIView {
        let imageView = UIImageView()
        init() {
            super.init(frame: .zero)
            clipsToBounds = true
            imageView.contentMode = .scaleAspectFill
            imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            addSubview(imageView)
        }
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
        override func layoutSubviews() {
            super.layoutSubviews()
            imageView.frame = bounds
        }
    }
}
