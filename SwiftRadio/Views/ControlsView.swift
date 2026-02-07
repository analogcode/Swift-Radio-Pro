//
//  ControlsView.swift
//  SwiftRadio
//
//  Created by Fethi El Hassasna on 2024-01-14.
//  Copyright © 2024 matthewfecher.com. All rights reserved.
//

import UIKit
import AVKit
import MarqueeLabel

class ControlsView: UIView {

    var timeAction: ((UISlider, UIControl.Event) -> Void)?

    var playingAction: (() -> Void)?
    var nextAction: (() -> Void)?
    var previousAction: (() -> Void)?

    var moreAction: (() -> Void)?

    var isSliderSliding = false

    private var isLive = true

    // Row 1: song — artist (or station name when no metadata)
    private let titleLabel: MarqueeLabel = {
        let label = MarqueeLabel(frame: .zero, rate: 30, fadeLength: 10)
        label.font = UIFont.preferredFont(forTextStyle: .title2).bold()
        label.textAlignment = .center
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.trailingBuffer = 30
        return label
    }()

    // Row 2: station name (or station desc when no metadata)
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .title3)
        label.textAlignment = .center
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.alpha = 0.7
        return label
    }()

    private let timeSlider: ThinSlider = {
        let slider = ThinSlider()
        slider.value = 0.0
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.minimumTrackTintColor = Config.tintColor
        slider.maximumTrackTintColor = Config.tintColor.withAlphaComponent(0.3)
        return slider
    }()

    private let currentTimeLabel: UILabel = {
        let label = UILabel()
        label.text = "00:00"
        label.font = UIFont.systemFont(ofSize: 10, weight: .medium)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.textAlignment = .left
        label.alpha = 0.8
        return label
    }()

    private let totalTimeLabel: UILabel = {
        let label = UILabel()
        label.text = "00:00"
        label.font = UIFont.systemFont(ofSize: 10, weight: .medium)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.textAlignment = .right
        label.alpha = 0.8
        return label
    }()

    private let liveBadge: UIView = {
        let container = UIView()
        container.isHidden = true

        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialDark))
        blur.layer.cornerRadius = 6
        blur.clipsToBounds = true
        blur.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = "LIVE"
        label.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        label.textColor = .white.withAlphaComponent(0.9)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        blur.contentView.addSubview(label)
        container.addSubview(blur)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: blur.contentView.topAnchor, constant: 4),
            label.bottomAnchor.constraint(equalTo: blur.contentView.bottomAnchor, constant: -4),
            label.leadingAnchor.constraint(equalTo: blur.contentView.leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: blur.contentView.trailingAnchor, constant: -12),
            blur.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            blur.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])

        return container
    }()

    private let playPauseButton: UIButton = {
        let button = UIButton()
        let config = UIImage.SymbolConfiguration(pointSize: 60, weight: .regular)
        button.setImage(UIImage(systemName: "play.circle.fill", withConfiguration: config), for: .normal)
        button.setImage(UIImage(systemName: "stop.circle.fill", withConfiguration: config), for: .selected)
        button.tintColor = Config.tintColor
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let nextButton: UIButton = {
        let button = UIButton()
        let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .bold)
        button.setImage(UIImage(systemName: "forward.fill", withConfiguration: config), for: .normal)
        button.tintColor = Config.tintColor.withAlphaComponent(0.7)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let previousButton: UIButton = {
        let button = UIButton()
        let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .bold)
        button.setImage(UIImage(systemName: "backward.fill", withConfiguration: config), for: .normal)
        button.tintColor = Config.tintColor.withAlphaComponent(0.7)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let airPlayButton: AVRoutePickerView = {
        let button = AVRoutePickerView()
        button.activeTintColor = Config.tintColor
        button.tintColor = Config.tintColor.withAlphaComponent(0.7)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 44),
            button.heightAnchor.constraint(equalToConstant: 44),
        ])
        return button
    }()

    private let moreButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "list.dash"), for: .normal)
        button.tintColor = Config.tintColor.withAlphaComponent(0.7)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 44),
            button.heightAnchor.constraint(equalToConstant: 44),
        ])
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setPlaying(_ isPlaying: Bool) {
        playPauseButton.isSelected = isPlaying
    }

    func setLive(_ isLive: Bool) {
        self.isLive = isLive
        timeSlider.isEnabled = !isLive
        timeSlider.showThumb = !isLive
        currentTimeLabel.isHidden = isLive
        totalTimeLabel.isHidden = isLive
        liveBadge.isHidden = !isLive
        updatePlayPauseImages()
    }

    func setCurrentTime(_ secounds: TimeInterval) {
        currentTimeLabel.text = formatSecondsToString(secounds)
    }

    func setTotalTime(_ secounds: TimeInterval) {
        totalTimeLabel.text = "-" + formatSecondsToString(secounds)
    }

    func setTimeSilder(value: Float) {
        timeSlider.value = value
    }

    /// Update the two-row labels, mirroring the popup bar layout.
    /// - When metadata exists: row 1 = "Song — Artist", row 2 = station name
    /// - When no metadata: row 1 = station name, row 2 = station description
    func updateNowPlaying(song: String?, artist: String?, stationName: String?, stationDesc: String?) {
        if let song {
            titleLabel.text = [song, artist].compactMap { $0 }.joined(separator: " — ")
            subtitleLabel.text = stationName
        } else {
            titleLabel.text = stationName
            subtitleLabel.text = stationDesc
        }
    }

    // MARK: - Private

    private func updatePlayPauseImages() {
        let config = UIImage.SymbolConfiguration(pointSize: 60, weight: .regular)
        playPauseButton.setImage(UIImage(systemName: "play.circle.fill", withConfiguration: config), for: .normal)
        let selectedName = isLive ? "stop.circle.fill" : "pause.circle.fill"
        playPauseButton.setImage(UIImage(systemName: selectedName, withConfiguration: config), for: .selected)
    }

    private func formatSecondsToString(_ secounds: TimeInterval) -> String {
        guard secounds != 0 else { return "00:00" }
        let min = Int(secounds / 60)
        let sec = Int(secounds.truncatingRemainder(dividingBy: 60))
        return String(format: "%02d:%02d", min, sec)
    }

    private func setupViews() {
        let mainStackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, sliderContainerView, buttonsStackView, menuStackView])
        mainStackView.axis = .vertical
        mainStackView.spacing = 8
        mainStackView.alignment = .fill

        mainStackView.setCustomSpacing(4, after: titleLabel)
        mainStackView.setCustomSpacing(20, after: subtitleLabel)

        mainStackView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(mainStackView)

        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: topAnchor),
            mainStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            mainStackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    // MARK: - StackViews

    /// Slider with LIVE badge overlaid above it, and time labels below.
    private var sliderContainerView: UIView {
        let spacer1 = UIView()
        spacer1.setContentHuggingPriority(.defaultLow, for: .horizontal)
        let spacer2 = UIView()
        spacer2.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let timeLabelsStackView = UIStackView(arrangedSubviews: [currentTimeLabel, spacer1, spacer2, totalTimeLabel])
        timeLabelsStackView.axis = .horizontal
        timeLabelsStackView.distribution = .fillEqually
        timeLabelsStackView.alignment = .fill

        let vStackView = UIStackView(arrangedSubviews: [timeSlider, timeLabelsStackView])
        vStackView.axis = .vertical
        vStackView.distribution = .fill
        vStackView.alignment = .fill
        vStackView.spacing = 4

        // Wrap in a container so we can overlay the LIVE badge
        let container = UIView()
        vStackView.translatesAutoresizingMaskIntoConstraints = false
        liveBadge.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(vStackView)
        container.addSubview(liveBadge)

        NSLayoutConstraint.activate([
            vStackView.topAnchor.constraint(equalTo: container.topAnchor),
            vStackView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            vStackView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            vStackView.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            liveBadge.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            liveBadge.centerYAnchor.constraint(equalTo: timeSlider.centerYAnchor),
        ])

        return container
    }

    private var buttonsStackView: UIStackView {
        let hStackView = UIStackView(arrangedSubviews: [previousButton, playPauseButton, nextButton])
        hStackView.axis = .horizontal
        hStackView.spacing = 40
        hStackView.alignment = .center

        playPauseButton.addTarget(self, action: #selector(playingPressed), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(nextPressed), for: .touchUpInside)
        previousButton.addTarget(self, action: #selector(previousPressed), for: .touchUpInside)

        nextButton.isHidden = Config.hideNextPreviousButtons
        previousButton.isHidden = Config.hideNextPreviousButtons

        let vStackView = UIStackView(arrangedSubviews: [hStackView])
        vStackView.axis = .vertical
        vStackView.distribution = .fill
        vStackView.alignment = .center

        return vStackView
    }

    private var menuStackView: UIStackView {
        let stackView = UIStackView(arrangedSubviews: [airPlayButton, moreButton])
        stackView.axis = .horizontal
        stackView.spacing = 40
        stackView.alignment = .center
        stackView.distribution = .fill

        moreButton.addTarget(self, action: #selector(morePressed), for: .touchUpInside)
        timeSlider.addTarget(self, action: #selector(timeSliderTouchBegan(sender:)), for: .touchDown)
        timeSlider.addTarget(self, action: #selector(timeSliderValueChanged(sender:)), for: .valueChanged)
        timeSlider.addTarget(self, action: #selector(timeSliderTouchEnded(sender:)), for: [.touchUpInside, .touchCancel, .touchUpOutside])

        let containerStack = UIStackView(arrangedSubviews: [stackView])
        containerStack.axis = .vertical
        containerStack.alignment = .center

        return containerStack
    }

    // MARK: - Actions

    @objc private func playingPressed(_ sender: Any) {
        playingAction?()
    }

    @objc private func nextPressed(_ sender: Any) {
        nextAction?()
    }

    @objc private func previousPressed(_ sender: Any) {
        previousAction?()
    }

    @objc private func morePressed(_ sender: Any) {
        moreAction?()
    }

    @objc private func timeSliderTouchBegan(sender: UISlider) {
        isSliderSliding = true
        timeAction?(sender, .touchDown)
    }

    @objc private func timeSliderValueChanged(sender: UISlider) {
        timeAction?(sender, .valueChanged)
    }

    @objc private func timeSliderTouchEnded(sender: UISlider) {
        timeAction?(sender, .touchUpInside)
    }
}

// MARK: - UIFont Extension

private extension UIFont {
    func bold() -> UIFont {
        guard let descriptor = fontDescriptor.withSymbolicTraits(.traitBold) else { return self }
        return UIFont(descriptor: descriptor, size: 0)
    }
}

// MARK: - ThinSlider

private class ThinSlider: UISlider {

    private let trackHeight: CGFloat = 2
    private let normalThumbSize: CGFloat = 10
    private let highlightedThumbSize: CGFloat = 16

    var showThumb: Bool = false {
        didSet { updateThumbImages() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        updateThumbImages()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        let center = bounds.midY
        return CGRect(x: bounds.minX, y: center - trackHeight / 2, width: bounds.width, height: trackHeight)
    }

    private func updateThumbImages() {
        if showThumb {
            setThumbImage(makeThumbImage(size: normalThumbSize), for: .normal)
            setThumbImage(makeThumbImage(size: highlightedThumbSize), for: .highlighted)
        } else {
            setThumbImage(UIImage(), for: .normal)
            setThumbImage(UIImage(), for: .highlighted)
        }
    }

    private func makeThumbImage(size: CGFloat) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        return renderer.image { context in
            Config.tintColor.setFill()
            context.cgContext.fillEllipse(in: CGRect(x: 0, y: 0, width: size, height: size))
        }
    }
}
