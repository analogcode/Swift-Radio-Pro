//
//  ControlsView.swift
//  SwiftRadio
//
//  Created by Fethi El Hassasna on 2024-01-14.
//  Copyright © 2024 matthewfecher.com. All rights reserved.
//

import UIKit
import Spring
import AVKit

enum SongInfoType {
    case track(song: String?, artist: String?)
    case status(message: String, name: String?)
}

class ControlsView: UIView {
    
    var timeAction: ((UISlider, UIControl.Event) -> Void)?
    
    var playingAction: (() -> Void)?
    var stopAction: (() -> Void)?
    var nextAction: (() -> Void)?
    var previousAction: (() -> Void)?
    
    var logoAction: (() -> Void)?
    var moreAction: (() -> Void)?
    
    var isSliderSliding = false
        
    private let songLabel: SpringLabel = {
        let label = SpringLabel()
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        label.textAlignment = .center
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }()
    
    private let artistLabel: SpringLabel = {
        let label = SpringLabel()
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.textAlignment = .center
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.alpha = 0.8
        return label
    }()
    
    private let timeSlider: UISlider = {
        let slider = UISlider()
        slider.value = 0.0
        slider.setThumbImage(UIImage(), for: .normal)
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.value = 0.0
        slider.minimumTrackTintColor = .white
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
    
    private let liveLabel: UILabel = {
        let label = UILabel()
        label.text = "Live".uppercased()
        label.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.textAlignment = .center
        label.alpha = 0.8
        return label
    }()
    
    private let playPauseButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "play"), for: .normal)
        button.setImage(UIImage(named: "pause"), for: .selected)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([button.widthAnchor.constraint(equalToConstant: 70), button.heightAnchor.constraint(equalToConstant: 70)])
        return button
    }()
    
    private let stopButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "stop"), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([button.widthAnchor.constraint(equalToConstant: 55), button.heightAnchor.constraint(equalToConstant: 55)])
        return button
    }()
    
    private let nextButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "forward"), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([button.widthAnchor.constraint(equalToConstant: 44), button.heightAnchor.constraint(equalToConstant: 22)])
        return button
    }()
    
    private let previousButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "backward"), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([button.widthAnchor.constraint(equalToConstant: 44), button.heightAnchor.constraint(equalToConstant: 22)])
        return button
    }()
    
    private let logoButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "logo"), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([button.heightAnchor.constraint(equalToConstant: 36)])
        return button
    }()
    
    private let airPlayButton: AVRoutePickerView = {
        let button = AVRoutePickerView()
        button.activeTintColor = .white
        button.tintColor = .white.withAlphaComponent(0.85)
        return button
    }()
    
    private let moreButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "list.dash"), for: .normal)
        button.tintColor = .white.withAlphaComponent(0.85)
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
    
    func setStop(_ isActive: Bool) {
        stopButton.isEnabled = isActive
    }
    
    func setLive(_ isLive: Bool) {
        timeSlider.isEnabled = !isLive
        currentTimeLabel.isHidden = isLive
        totalTimeLabel.isHidden = isLive
        liveLabel.isHidden = !isLive
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
    
    func updateLabels(with type: SongInfoType, animate: Bool = true) {
        switch type {
        case .track(song: let song, artist: let artist):
            songLabel.text = song
            artistLabel.text = artist
            shouldAnimateSong(animate)
        case .status(message: let message, let name):
            guard songLabel.text != message else { break }
            songLabel.text = message
            artistLabel.text = name
            shouldAnimateStatus(animate)
        }
    }
    
    // TODO: Combine the 2 animate func
    
    private func shouldAnimateSong(_ animate: Bool) {
        guard animate else { return }
        songLabel.animation = "zoomIn"
        songLabel.duration = 1.5
        songLabel.damping = 1
        songLabel.animate()
    }
    
    private func shouldAnimateStatus(_ animate: Bool) {
        guard animate else { return }
        songLabel.animation = "flash"
        songLabel.repeatCount = 2
        songLabel.animate()
    }
    
    private func formatSecondsToString(_ secounds: TimeInterval) -> String {
        guard secounds != 0 else { return "00:00" }
        let min = Int(secounds / 60)
        let sec = Int(secounds.truncatingRemainder(dividingBy: 60))
        return String(format: "%02d:%02d", min, sec)
    }
    
    private func setupViews() {
        
        let mainStackView = UIStackView(arrangedSubviews: [songLabel, artistLabel, timeSliderStackView, buttonsStackView, menuStackView])
        mainStackView.axis = .vertical
        mainStackView.spacing = 8
        mainStackView.alignment = .fill
        
        // Add custom spacing after artistLabel
        mainStackView.setCustomSpacing(16, after: artistLabel)
        
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
    
    private var timeSliderStackView: UIStackView {
        let spacer1 = UIView()
        spacer1.setContentHuggingPriority(.defaultLow, for: .horizontal)
        let spacer2 = UIView()
        spacer2.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        let timeLabelsStackView = UIStackView(arrangedSubviews: [currentTimeLabel, spacer1, liveLabel, spacer2, totalTimeLabel])
        timeLabelsStackView.axis = .horizontal
        timeLabelsStackView.distribution = .fillEqually
        timeLabelsStackView.alignment = .fill
                
        let vStackView = UIStackView(arrangedSubviews: [timeSlider, timeLabelsStackView])
        vStackView.axis = .vertical
        vStackView.distribution = .fill
        vStackView.alignment = .fill
        vStackView.spacing = 4
        
        return vStackView
    }
    
    private var buttonsStackView: UIStackView {
        let playStackView = UIStackView(arrangedSubviews: [playPauseButton, stopButton])
        playStackView.axis = .horizontal
        playStackView.spacing = 10
        playStackView.alignment = .center
        
        let hStackView = UIStackView(arrangedSubviews: [previousButton, playStackView, nextButton])
        hStackView.axis = .horizontal
        hStackView.spacing = 20
        hStackView.alignment = .center
        
        // Actions
        playPauseButton.addTarget(self, action: #selector(playingPressed), for: .touchUpInside)
        stopButton.addTarget(self, action: #selector(stopPressed), for: .touchUpInside)
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
        let spacer1 = UIView()
        spacer1.setContentHuggingPriority(.defaultLow, for: .horizontal)
        let spacer2 = UIView()
        spacer2.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        let stackView = UIStackView(arrangedSubviews: [logoButton, spacer1, airPlayButton, spacer2, moreButton])
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .fill
        
        // Actions
        logoButton.addTarget(self, action: #selector(logoPressed), for: .touchUpInside)
        moreButton.addTarget(self, action: #selector(morePressed), for: .touchUpInside)
        timeSlider.addTarget(self, action: #selector(timeSliderTouchBegan(sender:)), for: .touchDown)
        timeSlider.addTarget(self, action: #selector(timeSliderValueChanged(sender:)), for: .valueChanged)
        timeSlider.addTarget(self, action: #selector(timeSliderTouchEnded(sender:)), for: [.touchUpInside, .touchCancel, .touchUpOutside])
                
        
        return stackView
    }
    
    // MARK: - Actions
    
    @objc private func playingPressed(_ sender: Any) {
        playingAction?()
    }
    
    @objc private func stopPressed(_ sender: Any) {
        stopAction?()
    }
    
    @objc private func nextPressed(_ sender: Any) {
        nextAction?()
    }
    
    @objc private func previousPressed(_ sender: Any) {
        previousAction?()
    }
    
    @objc private func logoPressed(_ sender: Any) {
        logoAction?()
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
