//
//  PlaybackArtworkImage.swift
//  Swift Radio
//
//  Created on 2026-09-23.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import NVActivityIndicatorView
import SwiftUI

struct PlaybackArtworkState {
    let isPlaying: Bool
    let isBuffering: Bool
}

/// Exact reference artwork transitions. Loading/state ownership stays in SwiftUI.
@MainActor struct PlaybackArtworkImage: UIViewRepresentable {
    let image: UIImage?
    let state: PlaybackArtworkState
    let cornerRadius: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeUIView(context: Context) -> ArtworkContainer { ArtworkContainer(cornerRadius: cornerRadius) }

    func updateUIView(_ view: ArtworkContainer, context: Context) {
        view.update(image: image, state: state, reduceMotion: reduceMotion)
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: ArtworkContainer, context: Context) -> CGSize? {
        CGSize(width: proposal.width ?? 0, height: proposal.height ?? 0)
    }

    static func dismantleUIView(_ view: ArtworkContainer, coordinator: ()) { view.stopAnimations() }

    final class ArtworkContainer: UIView {
        private let container = UIView()
        private let imageView = UIImageView()
        private let bufferingOverlay = UIView()
        private let indicator = NVActivityIndicatorView(frame: .zero, type: .ballPulse, color: .white)
        private let reducedMotionIndicator = UIImageView(image: UIImage(systemName: "ellipsis"))
        private var previousState: PlaybackArtworkState?
        private var previousReduceMotion: Bool?

        init(cornerRadius: CGFloat) {
            super.init(frame: .zero)
            layer.shadowColor = UIColor.black.cgColor
            layer.shadowOpacity = 0.4
            layer.shadowOffset = CGSize(width: 0, height: 10)
            layer.shadowRadius = 20
            container.clipsToBounds = true
            container.layer.cornerRadius = cornerRadius
            imageView.contentMode = .scaleAspectFill
            imageView.backgroundColor = .white.withAlphaComponent(0.12)
            bufferingOverlay.backgroundColor = .black.withAlphaComponent(0.4)
            bufferingOverlay.alpha = 0
            reducedMotionIndicator.contentMode = .scaleAspectFit
            reducedMotionIndicator.tintColor = .white
            reducedMotionIndicator.isHidden = true
            addSubview(container)
            container.addSubview(imageView)
            container.addSubview(bufferingOverlay)
            bufferingOverlay.addSubview(indicator)
            bufferingOverlay.addSubview(reducedMotionIndicator)
            isAccessibilityElement = false
        }
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        override func layoutSubviews() {
            super.layoutSubviews()
            // Bounds/center are safe while the content has a scale transform.
            container.bounds = bounds
            container.center = CGPoint(x: bounds.midX, y: bounds.midY)
            imageView.frame = container.bounds
            bufferingOverlay.frame = container.bounds
            indicator.frame = CGRect(x: bounds.midX - 20, y: bounds.midY - 15, width: 40, height: 30)
            reducedMotionIndicator.frame = indicator.frame
            updateIndicator()
        }

        func update(image: UIImage?, state: PlaybackArtworkState, reduceMotion: Bool) {
            if reduceMotion { stopAnimations() }
            if imageView.image !== image {
                // Clearing on a station switch is instant, like the reference setImage(nil).
                if imageView.image == nil || image == nil || reduceMotion {
                    imageView.image = image
                } else {
                    UIView.transition(with: imageView, duration: 0.3,
                                      options: [.transitionCrossDissolve, .beginFromCurrentState]) {
                        self.imageView.image = image
                    }
                }
            }
            if previousState?.isPlaying != state.isPlaying || previousReduceMotion != reduceMotion {
                let transform = CGAffineTransform(scaleX: state.isPlaying ? 1 : 0.85,
                                                   y: state.isPlaying ? 1 : 0.85)
                if reduceMotion || previousState == nil {
                    container.transform = transform
                } else {
                    UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7,
                                   initialSpringVelocity: 0, options: [.allowUserInteraction, .beginFromCurrentState]) {
                        self.container.transform = transform
                    }
                }
            }
            reducedMotionIndicator.isHidden = !state.isBuffering || !reduceMotion
            if previousState?.isBuffering != state.isBuffering || previousReduceMotion != reduceMotion {
                let alpha: CGFloat = state.isBuffering ? 1 : 0
                if reduceMotion { bufferingOverlay.alpha = alpha }
                else {
                    UIView.animate(withDuration: 0.3, delay: 0, options: .beginFromCurrentState) {
                        self.bufferingOverlay.alpha = alpha
                    }
                }
            }
            previousState = state
            previousReduceMotion = reduceMotion
            updateIndicator()
        }

        private func updateIndicator() {
            if previousState?.isBuffering == true && previousReduceMotion == false && indicator.bounds.width > 0 {
                indicator.startAnimating()
            } else { indicator.stopAnimating() }
        }

        func stopAnimations() {
            indicator.stopAnimating()
            container.layer.removeAllAnimations()
            imageView.layer.removeAllAnimations()
            bufferingOverlay.layer.removeAllAnimations()
        }
    }
}
