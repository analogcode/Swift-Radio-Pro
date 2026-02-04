//
//  AlbumArtworkView.swift
//  SwiftRadio
//
//  Created by Fethi El Hassasna on 2024-01-13.
//  Copyright 2024 matthewfecher.com. All rights reserved.
//

import UIKit
import Spring
import NVActivityIndicatorView

class AlbumArtworkView: UIView {

    private let artworkCornerRadius: CGFloat = 20

    private let containerView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        return view
    }()

    private let imageView: SpringImageView = {
        let view = SpringImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        return view
    }()

    private let bufferingOverlay: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        view.alpha = 0
        return view
    }()

    private let bufferingIndicator: NVActivityIndicatorView = {
        let view = NVActivityIndicatorView(frame: .zero, type: .ballPulse, color: .white, padding: nil)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setImage(_ image: UIImage?, animated: Bool = false) {
        guard animated else {
            imageView.image = image
            return
        }
        UIView.transition(with: imageView, duration: 0.3, options: .transitionCrossDissolve) {
            self.imageView.image = image
        }
    }

    func setBuffering(_ isBuffering: Bool) {
        if isBuffering {
            bufferingIndicator.startAnimating()
            UIView.animate(withDuration: 0.3) { self.bufferingOverlay.alpha = 1 }
        } else {
            UIView.animate(withDuration: 0.3) { self.bufferingOverlay.alpha = 0 }
            bufferingIndicator.stopAnimating()
        }
    }

    func setPlaying(_ isPlaying: Bool) {
        let scale: CGFloat = isPlaying ? 1.0 : 0.85
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 0,
            options: .allowUserInteraction
        ) {
            self.containerView.transform = CGAffineTransform(scaleX: scale, y: scale)
        }
    }

    private func setupViews() {
        // Shadow on outer view
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.4
        layer.shadowOffset = CGSize(width: 0, height: 10)
        layer.shadowRadius = 20

        containerView.layer.cornerRadius = artworkCornerRadius
        containerView.translatesAutoresizingMaskIntoConstraints = false

        imageView.translatesAutoresizingMaskIntoConstraints = false
        bufferingOverlay.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(imageView)
        containerView.addSubview(bufferingOverlay)
        bufferingOverlay.addSubview(bufferingIndicator)
        addSubview(containerView)

        NSLayoutConstraint.activate([
            // Container fills the view
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),

            // Keep container square
            containerView.widthAnchor.constraint(equalTo: containerView.heightAnchor),

            // Image fills container
            imageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            // Buffering overlay fills container
            bufferingOverlay.topAnchor.constraint(equalTo: containerView.topAnchor),
            bufferingOverlay.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            bufferingOverlay.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            bufferingOverlay.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            bufferingIndicator.centerXAnchor.constraint(equalTo: bufferingOverlay.centerXAnchor),
            bufferingIndicator.centerYAnchor.constraint(equalTo: bufferingOverlay.centerYAnchor),
            bufferingIndicator.widthAnchor.constraint(equalToConstant: 40),
            bufferingIndicator.heightAnchor.constraint(equalToConstant: 30),
        ])
    }
}
