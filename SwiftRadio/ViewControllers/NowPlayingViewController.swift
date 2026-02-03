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
        let image = UIImage(named: "background")
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
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
        topConstraint?.constant = navigationController != nil ? 8 : 40
    }

    private func isPlayingDidChange(_ isPlaying: Bool) {
        controlsView.setPlaying(isPlaying)
        controlsView.setStop(isPlaying)
        updatePopupBarPlayPauseButton(isPlaying: isPlaying)
    }

    func stationDidChange() {
        albumArtworkView.setImage(nil)
        manager.currentStation?.getImage { [weak self] image in
            self?.albumArtworkView.setImage(image)
            self?.updatePopupBarImage(image)
        }

        updatePopupBarMetadata()
        updateLabels()
        controlsView.setLive(player.duration == 0)
    }

    func updateLabels(with statusMessage: String? = nil, animate: Bool = true) {
        guard let statusMessage = statusMessage else {
            controlsView.updateLabels(with: .track(song: manager.currentStation?.trackName,
                                                   artist: manager.currentStation?.artistName))
            return
        }

        controlsView.updateLabels(with: .status(message: statusMessage, name: manager.currentStation?.name))
    }

    func playbackStateDidChange(_ playbackState: FRadioPlayer.PlaybackState, animate: Bool) {

        let message: String?

        switch playbackState {
        case .paused:
            message = "Paused..."
        case .playing:
            message = nil
        case .stopped:
            message = "Stopped..."
        }

        updateLabels(with: message, animate: animate)
        isPlayingDidChange(player.isPlaying)
    }

    func playerStateDidChange(_ state: FRadioPlayer.State, animate: Bool) {

        let message: String?

        switch state {
        case .loading:
            message = "Loading ..."
        case .urlNotSet:
            message = "URL not valide"
        case .readyToPlay, .loadingFinished:
            playbackStateDidChange(player.playbackState, animate: animate)
            return
        case .error:
            message = "Error Playing"
        }

        updateLabels(with: message, animate: animate)
    }

    // MARK: - Setup Methods

    private func setupViews() {
        view.addSubview(backgroundImageView)

        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.rightAnchor.constraint(equalTo: view.rightAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundImageView.leftAnchor.constraint(equalTo: view.leftAnchor)
        ])

        let mainStackView = UIStackView(arrangedSubviews: [albumArtworkView, controlsView])
        mainStackView.axis = .vertical
        mainStackView.spacing = 20
        mainStackView.distribution = .fillEqually
        mainStackView.translatesAutoresizingMaskIntoConstraints = false

        controlsView.playingAction = { [unowned self] in
            player.togglePlaying()
        }

        controlsView.stopAction = { [unowned self] in
            player.stop()
        }

        controlsView.nextAction = { [unowned self] in
            manager.setNext()
        }

        controlsView.previousAction = { [unowned self] in
            manager.setPrevious()
        }

        controlsView.logoAction = { [unowned self] in
            delegate?.didTapCompanyButton(self)
        }

        controlsView.moreAction = { [unowned self] in
            handleMoreMenu()
        }

        controlsView.timeAction = { [unowned self] slider, event in
            handleTimeSlider(slider: slider, event: event)
        }

        view.addSubview(mainStackView)

        topConstraint = mainStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8)

        NSLayoutConstraint.activate([
            topConstraint!,
            mainStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            mainStackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            mainStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }

    func updateTrackArtwork() {
        getTrackArtwork { [weak self] image, isAnimated in
            DispatchQueue.main.async {
                self?.albumArtworkView.setImage(image)
                if isAnimated { self?.albumArtworkView.animate() }
                self?.updatePopupBarImage(image)
            }
        }
    }

    private func getTrackArtwork(completion: @escaping (UIImage?, Bool) -> Void) {
        guard let artworkURL = player.currentArtworkURL else {
            manager.currentStation?.getImage { image in
                completion(image, false)
            }
            return
        }

        UIImage.image(from: artworkURL) { image in
            completion(image, true)
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
        let imageName = isPlaying ? "pause.fill" : "play.fill"
        playPauseButton.image = UIImage(systemName: imageName)
    }

    @objc private func popupBarPlayPauseTapped() {
        player.togglePlaying()
    }
}

extension NowPlayingViewController: FRadioPlayerObserver {

    func radioPlayer(_ player: FRadioPlayer, playerStateDidChange state: FRadioPlayer.State) {
        playerStateDidChange(state, animate: true)
    }

    func radioPlayer(_ player: FRadioPlayer, playbackStateDidChange state: FRadioPlayer.PlaybackState) {
        playbackStateDidChange(state, animate: true)
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
            getTrackArtwork { [weak self] image, _ in
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
