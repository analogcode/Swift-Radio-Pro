//
//  StationTableViewCell.swift
//  SwiftRadio
//
//  Created by Fethi El Hassasna on 2023-06-24.
//  Copyright © 2023 matthewfecher.com. All rights reserved.
//

import UIKit
import NVActivityIndicatorView

class StationTableViewCell: UITableViewCell {

    // MARK: - UI
    private var representedStation: RadioStation?

    private let cardBlurView: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .systemUltraThinMaterialDark)
        let view = UIVisualEffectView(effect: blur)
        view.layer.cornerRadius = 14
        view.clipsToBounds = true
        view.layer.borderWidth = 0.5
        view.layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.cornerRadius = 14
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.2
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let pulseRingView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 2.5
        view.layer.borderColor = UIColor.white.cgColor
        view.layer.shadowColor = UIColor.white.cgColor
        view.layer.shadowOpacity = 0.5
        view.layer.shadowOffset = .zero
        view.layer.shadowRadius = 6
        view.alpha = 0
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    let stationImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let artworkShadowView: UIView = {
        let view = UIView()
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.35
        view.layer.shadowOffset = CGSize(width: 0, height: 3)
        view.layer.shadowRadius = 8
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let subtitleStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 6
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = .white.withAlphaComponent(0.55)
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let equalizerView: NVActivityIndicatorView = {
        let view = NVActivityIndicatorView(frame: .zero, type: .audioEqualizer, color: .white, padding: nil)
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: 16),
            view.heightAnchor.constraint(equalToConstant: 12)
        ])
        view.alpha = 0
        return view
    }()

    private let bufferingOverlay: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        view.alpha = 0
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let bufferingIndicator: NVActivityIndicatorView = {
        let view = NVActivityIndicatorView(frame: .zero, type: .ballPulse, color: .white, padding: nil)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private var isAnimatingPulse = false

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        representedStation = nil
        titleLabel.text = nil
        subtitleLabel.text = nil
        stationImageView.image = nil
        stopPulseAnimation()
        pulseRingView.alpha = 0
        equalizerView.stopAnimating()
        equalizerView.alpha = 0
        bufferingIndicator.stopAnimating()
        bufferingOverlay.alpha = 0
    }

    // MARK: - Highlight / Tap Feedback

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        let scale: CGFloat = highlighted ? 0.97 : 1.0
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
            self.cardView.transform = CGAffineTransform(scaleX: scale, y: scale)
            self.cardBlurView.transform = CGAffineTransform(scaleX: scale, y: scale)
        }
    }

    // MARK: - Setup

    private func setupViews() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        // Card shadow container + blur
        contentView.addSubview(cardView)
        cardView.addSubview(cardBlurView)

        // Artwork container: shadow view + pulse ring + image
        let artworkContainer = UIView()
        artworkContainer.translatesAutoresizingMaskIntoConstraints = false

        artworkContainer.addSubview(artworkShadowView)
        artworkContainer.addSubview(pulseRingView)
        artworkContainer.addSubview(stationImageView)
        artworkContainer.addSubview(bufferingOverlay)
        bufferingOverlay.addSubview(bufferingIndicator)

        // Subtitle stack: label + equalizer
        subtitleStack.addArrangedSubview(equalizerView)
        subtitleStack.addArrangedSubview(subtitleLabel)

        // Labels stack
        let vStackView = UIStackView(arrangedSubviews: [titleLabel, subtitleStack])
        vStackView.spacing = 4
        vStackView.axis = .vertical
        vStackView.translatesAutoresizingMaskIntoConstraints = false

        // Main horizontal stack
        let hStackView = UIStackView(arrangedSubviews: [artworkContainer, vStackView])
        hStackView.spacing = 14
        hStackView.axis = .horizontal
        hStackView.alignment = .center
        hStackView.translatesAutoresizingMaskIntoConstraints = false

        cardBlurView.contentView.addSubview(hStackView)

        let artworkSize: CGFloat = 70
        let pulseInset: CGFloat = -4

        NSLayoutConstraint.activate([
            // Card inset from contentView
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            // Blur fills card
            cardBlurView.topAnchor.constraint(equalTo: cardView.topAnchor),
            cardBlurView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),
            cardBlurView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            cardBlurView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),

            // HStack inside blur content
            hStackView.topAnchor.constraint(equalTo: cardBlurView.contentView.topAnchor, constant: 12),
            hStackView.bottomAnchor.constraint(equalTo: cardBlurView.contentView.bottomAnchor, constant: -12),
            hStackView.leadingAnchor.constraint(equalTo: cardBlurView.contentView.leadingAnchor, constant: 14),
            hStackView.trailingAnchor.constraint(equalTo: cardBlurView.contentView.trailingAnchor, constant: -14),

            // Artwork container size
            artworkContainer.widthAnchor.constraint(equalToConstant: artworkSize),
            artworkContainer.heightAnchor.constraint(equalToConstant: artworkSize),

            // Image fills container
            stationImageView.topAnchor.constraint(equalTo: artworkContainer.topAnchor),
            stationImageView.bottomAnchor.constraint(equalTo: artworkContainer.bottomAnchor),
            stationImageView.leadingAnchor.constraint(equalTo: artworkContainer.leadingAnchor),
            stationImageView.trailingAnchor.constraint(equalTo: artworkContainer.trailingAnchor),

            // Shadow matches image
            artworkShadowView.topAnchor.constraint(equalTo: stationImageView.topAnchor),
            artworkShadowView.bottomAnchor.constraint(equalTo: stationImageView.bottomAnchor),
            artworkShadowView.leadingAnchor.constraint(equalTo: stationImageView.leadingAnchor),
            artworkShadowView.trailingAnchor.constraint(equalTo: stationImageView.trailingAnchor),

            // Pulse ring slightly larger than artwork
            pulseRingView.topAnchor.constraint(equalTo: stationImageView.topAnchor, constant: pulseInset),
            pulseRingView.bottomAnchor.constraint(equalTo: stationImageView.bottomAnchor, constant: -pulseInset),
            pulseRingView.leadingAnchor.constraint(equalTo: stationImageView.leadingAnchor, constant: pulseInset),
            pulseRingView.trailingAnchor.constraint(equalTo: stationImageView.trailingAnchor, constant: -pulseInset),

            // Buffering overlay on top of image
            bufferingOverlay.topAnchor.constraint(equalTo: stationImageView.topAnchor),
            bufferingOverlay.bottomAnchor.constraint(equalTo: stationImageView.bottomAnchor),
            bufferingOverlay.leadingAnchor.constraint(equalTo: stationImageView.leadingAnchor),
            bufferingOverlay.trailingAnchor.constraint(equalTo: stationImageView.trailingAnchor),
            bufferingIndicator.centerXAnchor.constraint(equalTo: bufferingOverlay.centerXAnchor),
            bufferingIndicator.centerYAnchor.constraint(equalTo: bufferingOverlay.centerYAnchor),
            bufferingIndicator.widthAnchor.constraint(equalToConstant: 30),
            bufferingIndicator.heightAnchor.constraint(equalToConstant: 20),
        ])
    }

    // MARK: - Now Playing

    func setNowPlaying(isPlaying: Bool, isBuffering: Bool, isCurrentStation: Bool) {
        guard isCurrentStation else {
            stopPulseAnimation()
            pulseRingView.alpha = 0
            equalizerView.stopAnimating()
            equalizerView.alpha = 0
            bufferingIndicator.stopAnimating()
            bufferingOverlay.alpha = 0
            return
        }

        if isBuffering {
            // Dark overlay + buffering indicator on artwork
            stopPulseAnimation()
            pulseRingView.alpha = 0
            equalizerView.stopAnimating()
            equalizerView.alpha = 0
            bufferingIndicator.startAnimating()
            bufferingOverlay.alpha = 1
        } else if isPlaying {
            // Pulse ring + equalizer
            bufferingIndicator.stopAnimating()
            bufferingOverlay.alpha = 0
            startPulseAnimation()
            equalizerView.startAnimating()
            equalizerView.alpha = 0.7
        } else {
            // Stopped — subtle indicators
            bufferingIndicator.stopAnimating()
            bufferingOverlay.alpha = 0
            stopPulseAnimation()
            pulseRingView.alpha = 0.25
            pulseRingView.transform = .identity
            equalizerView.stopAnimating()
            equalizerView.alpha = 0.4
        }
    }

    // MARK: - Pulse Animation

    private func startPulseAnimation() {
        guard !isAnimatingPulse else { return }
        isAnimatingPulse = true

        pulseRingView.alpha = 0
        pulseRingView.transform = .identity

        UIView.animate(withDuration: 1.5, delay: 0, options: [.repeat, .autoreverse, .curveEaseInOut]) {
            self.pulseRingView.alpha = 0.4
            self.pulseRingView.transform = CGAffineTransform(scaleX: 1.06, y: 1.06)
        }
    }

    private func stopPulseAnimation() {
        guard isAnimatingPulse else { return }
        isAnimatingPulse = false
        pulseRingView.layer.removeAllAnimations()
        pulseRingView.transform = .identity
    }
}

// MARK: - Configuration

extension StationTableViewCell {
    func configureStationCell(station: RadioStation) {
        representedStation = station
        titleLabel.text = station.name
        subtitleLabel.text = station.desc

        station.getImage { [weak self] image in
            guard let self = self, self.representedStation == station else { return }
            self.stationImageView.image = image
        }
    }
}
