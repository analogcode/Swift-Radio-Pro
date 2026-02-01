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

protocol NowPlayingViewControllerDelegate: AnyObject {
    func didSelectBottomSheetOption(_ option: BottomSheetViewController.Option, from controller: NowPlayingViewController)
    func didTapCompanyButton(_ nowPlayingViewController: NowPlayingViewController)
}

class NowPlayingViewController: BaseController {
    
    // MARK: - Delegate
    weak var delegate: NowPlayingViewControllerDelegate?
    
    // MARK: - UI
    private let animationView: NVActivityIndicatorView = {
        let activityIndicatorView = NVActivityIndicatorView(frame: .zero, type: .audioEqualizer, color: .white, padding: nil)
        NSLayoutConstraint.activate([
            activityIndicatorView.widthAnchor.constraint(equalToConstant: 30),
            activityIndicatorView.widthAnchor.constraint(equalToConstant: 30),
            activityIndicatorView.heightAnchor.constraint(equalToConstant: 20)
        ])
        return activityIndicatorView
    }()
    
    private let albumArtworkView = AlbumArtworkView()
    private let controlsView = ControlsView()
    
    // MARK: - Properties
    private let player = FRadioPlayer.shared
    private let manager = StationsManager.shared
    
    var isNewStation = true
        
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.backButtonDisplayMode = .minimal
        
        player.addObserver(self)
        manager.addObserver(self)
        
        title = manager.currentStation?.name
        
        // Set UI - Reset UI
        
        // Check for station change
        if isNewStation {
            stationDidChange()
        } else {
            updateTrackArtwork()
            playerStateDidChange(player.state, animate: false)
        }
        
        setupViews()
        
        isPlayingDidChange(player.isPlaying)
        controlsView.setLive(player.duration == 0)
    }
    
    private func isPlayingDidChange(_ isPlaying: Bool) {
        controlsView.setPlaying(isPlaying)
        controlsView.setStop(isPlaying)
        isPlaying ? animationView.startAnimating() : animationView.stopAnimating()
    }
    
    func stationDidChange() {
        albumArtworkView.setImage(nil)
        manager.currentStation?.getImage { [weak self] image in
            self?.albumArtworkView.setImage(image)
        }

        title = manager.currentStation?.name
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
    
    override func setupViews() {
        super.setupViews()
        
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
        
        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            mainStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            mainStackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            mainStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: animationView)
    }
    
    func updateTrackArtwork() {
        getTrackArtwork { [weak self] image, isAnimated in
            DispatchQueue.main.async {
                self?.albumArtworkView.setImage(image)
                if isAnimated { self?.albumArtworkView.animate() }
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
