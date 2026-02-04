//
//  NowPlayingViewControllerWIP.swift
//  SwiftRadio
//
//  Created by Fethi El Hassasna on 2024-01-13.
//  Copyright © 2024 matthewfecher.com. All rights reserved.
//

import UIKit
import MediaPlayer
import AVKit
import FRadioPlayer
import NVActivityIndicatorView
import LNPopupController

protocol NowPlayingViewControllerDelegate: AnyObject {
    func didSelectBottomSheetOption(_ option: BottomSheetViewController.Option, from controller: NowPlayingViewController)
    func didTapCompanyButton(_ nowPlayingViewController: NowPlayingViewController)
}

class NowPlayingViewController: UIViewController {

    // MARK: - Delegate
    weak var delegate: NowPlayingViewControllerDelegate?

    // MARK: - UI
    private let backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let backgroundBlurView: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .systemThickMaterialDark)
        let view = UIVisualEffectView(effect: blur)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let backgroundDimView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let albumArtworkView = AlbumArtworkView()
    private let controlsView = ControlsView()
    private var topConstraint: NSLayoutConstraint?

    // MARK: - Popup Bar
    private lazy var playPauseButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: UIImage(systemName: "play.fill"), style: .plain, target: self, action: #selector(popupBarPlayPauseTapped))
        return button
    }()

    // MARK: - Properties
    private let player = FRadioPlayer.shared
    private let manager = StationsManager.shared

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        player.addObserver(self)
        manager.addObserver(self)

        setupViews()
        stationDidChange()
        isPlayingDidChange(player.isPlaying)
        controlsView.setLive(player.duration == 0)

        // Popup bar button items
        popupItem.barButtonItems = [playPauseButton]
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        topConstraint?.constant = navigationController != nil ? 16 : 48
    }

    private func isPlayingDidChange(_ isPlaying: Bool) {
        controlsView.setPlaying(isPlaying)
        albumArtworkView.setPlaying(isPlaying)
        updatePopupBarPlayPauseButton(isPlaying: isPlaying)
    }

    func stationDidChange() {
        albumArtworkView.setImage(nil)
        updateBackground(with: nil)
        manager.currentStation?.getImage { [weak self] image in
            self?.albumArtworkView.setImage(image)
            self?.updateBackground(with: image)
            self?.updatePopupBarImage(image)
        }

        updatePopupBarMetadata()
        updateLabels()
        controlsView.setLive(player.duration == 0)
    }

    func updateLabels() {
        controlsView.updateNowPlaying(
            song: player.currentMetadata?.trackName,
            artist: player.currentMetadata?.artistName,
            stationName: manager.currentStation?.name,
            stationDesc: manager.currentStation?.desc
        )
    }

    func playbackStateDidChange(_ playbackState: FRadioPlayer.PlaybackState) {
        isPlayingDidChange(player.isPlaying)
    }

    func playerStateDidChange(_ state: FRadioPlayer.State) {
        switch state {
        case .readyToPlay, .loadingFinished:
            playbackStateDidChange(player.playbackState)
        default:
            break
        }
    }

    // MARK: - Setup Methods

    private func setupViews() {
        // Dynamic blurred background
        view.addSubview(backgroundImageView)
        view.addSubview(backgroundBlurView)
        view.addSubview(backgroundDimView)

        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            backgroundBlurView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundBlurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundBlurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundBlurView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            backgroundDimView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundDimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundDimView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundDimView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        let mainStackView = UIStackView(arrangedSubviews: [albumArtworkView, controlsView])
        mainStackView.axis = .vertical
        mainStackView.spacing = 24
        mainStackView.distribution = .fill
        mainStackView.translatesAutoresizingMaskIntoConstraints = false

        controlsView.playingAction = { [unowned self] in
            if player.isPlaying, player.duration == 0 {
                player.stop()
            } else {
                player.togglePlaying()
            }
        }

        controlsView.nextAction = { [unowned self] in
            manager.setNext()
        }

        controlsView.previousAction = { [unowned self] in
            manager.setPrevious()
        }

        controlsView.moreAction = { [unowned self] in
            handleMoreMenu()
        }

        controlsView.timeAction = { [unowned self] slider, event in
            handleTimeSlider(slider: slider, event: event)
        }

        view.addSubview(mainStackView)

        topConstraint = mainStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8)

        let artworkHeight = albumArtworkView.heightAnchor.constraint(equalTo: mainStackView.heightAnchor, multiplier: 0.55)
        artworkHeight.priority = .defaultHigh

        NSLayoutConstraint.activate([
            topConstraint!,
            mainStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            mainStackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            mainStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            artworkHeight,
        ])
    }

    // MARK: - Dynamic Background

    private func updateBackground(with image: UIImage?) {
        UIView.transition(
            with: backgroundImageView,
            duration: 0.5,
            options: .transitionCrossDissolve
        ) {
            self.backgroundImageView.image = image
        }
    }

    func updateTrackArtwork() {
        getTrackArtwork { [weak self] image in
            DispatchQueue.main.async {
                self?.albumArtworkView.setImage(image, animated: true)
                self?.updateBackground(with: image)
                self?.updatePopupBarImage(image)
            }
        }
    }

    private func getTrackArtwork(completion: @escaping (UIImage?) -> Void) {
        guard let artworkURL = player.currentArtworkURL else {
            manager.currentStation?.getImage { image in
                completion(image)
            }
            return
        }

        UIImage.image(from: artworkURL) { image in
            completion(image)
        }
    }

    func handleMoreMenu() {
        guard let station = manager.currentStation else { return }
        let bottomSheet = BottomSheetViewController(station: station)
        bottomSheet.delegate = self
        present(bottomSheet, animated: true)
    }

    private func handleTimeSlider(slider: UISlider, event: UIControl.Event) {

        guard player.duration != 0 else { return }

        let seekTime =  TimeInterval(slider.value) * player.duration

        switch event {
        case .valueChanged:
            controlsView.setCurrentTime(seekTime)
            controlsView.setTotalTime(player.duration - seekTime)
        case .touchUpInside:
            player.seek(to: seekTime) { [weak self] in
                self?.controlsView.isSliderSliding = false
            }
        default:
            break
        }
    }

    // MARK: - Popup Bar

    private func updatePopupBarMetadata() {
        if let trackName = player.currentMetadata?.trackName {
            let artistName = player.currentMetadata?.artistName
            popupItem.title = [trackName, artistName].compactMap { $0 }.joined(separator: " — ")
            popupItem.subtitle = manager.currentStation?.name
        } else {
            popupItem.title = manager.currentStation?.name
            popupItem.subtitle = manager.currentStation?.desc
        }
    }

    private func updatePopupBarImage(_ image: UIImage?) {
        popupItem.image = image
        DispatchQueue.main.async {
            self.popupPresentationContainer?.popupBar.imageView.contentMode = .scaleAspectFill
            self.popupPresentationContainer?.popupBar.imageView.clipsToBounds = true
        }
    }

    private func updatePopupBarPlayPauseButton(isPlaying: Bool) {
        let isLive = player.duration == 0
        let imageName = isPlaying ? (isLive ? "stop.fill" : "pause.fill") : "play.fill"
        playPauseButton.image = UIImage(systemName: imageName)
    }

    @objc private func popupBarPlayPauseTapped() {
        if player.isPlaying, player.duration == 0 {
            player.stop()
        } else {
            player.togglePlaying()
        }
    }
}

extension NowPlayingViewController: FRadioPlayerObserver {

    func radioPlayer(_ player: FRadioPlayer, playerStateDidChange state: FRadioPlayer.State) {
        playerStateDidChange(state)
    }

    func radioPlayer(_ player: FRadioPlayer, playbackStateDidChange state: FRadioPlayer.PlaybackState) {
        playbackStateDidChange(state)
    }

    func radioPlayer(_ player: FRadioPlayer, metadataDidChange metadata: FRadioPlayer.Metadata?) {
        updateLabels()
        updatePopupBarMetadata()
    }

    func radioPlayer(_ player: FRadioPlayer, artworkDidChange artworkURL: URL?) {
        updateTrackArtwork()
    }

    func radioPlayer(_ player: FRadioPlayer, durationDidChange duration: TimeInterval) {
        controlsView.setLive(player.duration == 0)
    }

    func radioPlayer(_ player: FRadioPlayer, playTimeDidChange currentTime: TimeInterval, duration: TimeInterval) {
        guard !controlsView.isSliderSliding, player.duration != 0 else { return }

        // Update timer labels
        controlsView.setCurrentTime(currentTime)
        controlsView.setTotalTime(duration - currentTime)
        controlsView.setTimeSilder(value: Float(currentTime / duration))

        // Update popup bar progress
        popupItem.progress = Float(currentTime / duration)
    }
}

extension NowPlayingViewController: StationsManagerObserver {

    func stationsManager(_ manager: StationsManager, stationDidChange station: RadioStation?) {
        stationDidChange()
    }
}

extension NowPlayingViewController: BottomSheetViewControllerDelegate {

    func bottomSheet(_ controller: BottomSheetViewController, didSelect option: BottomSheetViewController.Option) {
        if case .share = option {
            getTrackArtwork { [weak self] image in
                guard let self = self else { return }
                self.delegate?.didSelectBottomSheetOption(.share(image), from: self)
            }
        } else if case .openInMusic = option {
            delegate?.didSelectBottomSheetOption(.openInMusic(manager.currentStation?.musicSearchURL), from: self)
        } else {
            delegate?.didSelectBottomSheetOption(option, from: self)
        }
    }
}
