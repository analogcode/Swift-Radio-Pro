//
//  NowPlayingViewController.swift
//  Swift Radio
//
//  Created by Matthew Fecher on 7/22/15.
//  Copyright (c) 2015 MatthewFecher.com. All rights reserved.
//

import UIKit
import MediaPlayer
import AVKit
import Spring
import FRadioPlayer
import Kingfisher

protocol NowPlayingViewControllerDelegate: AnyObject {
    func didTapCompanyButton(_ nowPlayingViewController: NowPlayingViewController)
    func didTapInfoButton(_ nowPlayingViewController: NowPlayingViewController, station: RadioStation)
    func didTapShareButton(_ nowPlayingViewController: NowPlayingViewController, station: RadioStation, artworkURL: URL?)
}

class NowPlayingViewController: UIViewController {
    
    weak var delegate: NowPlayingViewControllerDelegate?
    let client = ACWebSocketClient.shared
    
    // MARK: - IB UI
    
    @IBOutlet weak var albumHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var albumImageView: SpringImageView!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var releaseLabel: SpringLabel!
    @IBOutlet weak var playingButton: UIButton!
    @IBOutlet weak var songLabel: SpringLabel!
    @IBOutlet weak var volumeParentView: UIView!
    @IBOutlet weak var previousButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var airPlayView: UIView!
    @IBOutlet weak var djName: UILabel!
    @IBOutlet weak var liveDJIndicator: UIButton!
    
    // MARK: - Properties
    
    private let player = FRadioPlayer.shared
    private let manager = StationsManager.shared
    
    var isNewStation = true
    var nowPlayingImageView: UIImageView!
    
    var mpVolumeSlider: UISlider?

    // MARK: - ViewDidLoad
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.hidesBackButton = true
        
        player.addObserver(self)
        manager.addObserver(self)
        
        let viewSize = CGSize(width:  self.view.bounds.width, height:  self.view.bounds.height)
        optimizeForDeviceSize(size: viewSize)
        
        // Create Now Playing BarItem
        createNowPlayingAnimation()
        
        // Set View Title
        self.title = manager.currentStation?.name
        
        // Set UI
        djName.text = ""
        liveDJIndicator.isHidden = true
        
        // Check for station change
        if isNewStation {
            stationDidChange()
        } else {
            updateTrackArtwork()
            playerStateDidChange(player.state, animate: false)
        }
        
        // Setup volumeSlider
        setupVolumeSlider()
        
        // Setup AirPlayButton
        setupAirPlayButton()
        
        // Hide / Show Next/Previous buttons
        previousButton.isHidden = Config.hideNextPreviousButtons
        nextButton.isHidden = Config.hideNextPreviousButtons
        
        // Connect websocket client
        client.configurationDidChange(serverName: "Spiral.radio", shortCode: "radiospiral")
        client.setDefaultDJ(name: "Spud the Ambient Robot")
        client.addSubscriber(callback: updatedUI)
        client.connect()
        
        isPlayingDidChange(player.isPlaying)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { _ in
            print("rotating")
            self.optimizeForDeviceSize(size: size)
        })
    }
    
    func updatedUI(status: ACStreamStatus) {
        if !client.status.changed { return }
        artistLabel.text = client.status.artist
        songLabel.text = client.status.track
        releaseLabel.text = client.status.album
        djName.text = client.status.dj
        
        Task {
            let processor = DownsamplingImageProcessor(size: albumImageView.bounds.size)
            albumImageView.kf.indicatorType = .activity
            albumImageView.kf.setImage(with: client.status.artwork,
                                       options: [.processor(processor),
                                                 .scaleFactor(UIScreen.main.scale),
                                                 .transition(.fade(1))
                                       ])
            StationsManager.shared.updateLockscreenStatus(status: client.status)
        }
        //albumImageView.load(url: client.status.artwork!) { [weak self] in
        //    self?.albumImageView.animation = "wobble"
        //    self?.albumImageView.duration = 2
        //    self?.albumImageView.animate()
        //
        //    // Force app to update display
        //    self?.view.setNeedsDisplay()
        //}

    }
              
    // MARK: - Setup
    
    func setupVolumeSlider() {
        // Note: This slider implementation uses a MPVolumeView
        // The volume slider only works in devices, not the simulator.
        for subview in MPVolumeView().subviews {
            guard let volumeSlider = subview as? UISlider else { continue }
            mpVolumeSlider = volumeSlider
        }
        
        guard let mpVolumeSlider = mpVolumeSlider else { return }
        
        volumeParentView.addSubview(mpVolumeSlider)
        
        mpVolumeSlider.translatesAutoresizingMaskIntoConstraints = false
        mpVolumeSlider.leftAnchor.constraint(equalTo: volumeParentView.leftAnchor).isActive = true
        mpVolumeSlider.rightAnchor.constraint(equalTo: volumeParentView.rightAnchor).isActive = true
        mpVolumeSlider.centerYAnchor.constraint(equalTo: volumeParentView.centerYAnchor).isActive = true
        
        mpVolumeSlider.setThumbImage(#imageLiteral(resourceName: "slider-ball"), for: .normal)
    }
    
    func setupAirPlayButton() {
        let airPlayButton = AVRoutePickerView(frame: airPlayView.bounds)
        airPlayButton.activeTintColor = .white
        airPlayButton.tintColor = .gray
        airPlayView.backgroundColor = .clear
        airPlayView.addSubview(airPlayButton)
    }
    
    func stationDidChange() {
        albumImageView.image = nil
        manager.currentStation?.getImage { [weak self] image in
            self?.albumImageView.image = image
        }
        title = manager.currentStation?.name
        updateLabels()
        player.stop()
    }
    
    // MARK: - Player Controls (Play/Pause/Volume)
        
    @IBAction func playingPressed(_ sender: Any) {
        if player.isPlaying {
            ACWebSocketClient.shared.disconnect()
            player.stop()
        } else {
            ACWebSocketClient.shared.connect()
            player.play()
        }
    }
        
    @IBAction func nextPressed(_ sender: Any) {
        manager.setNext()
    }
    
    @IBAction func previousPressed(_ sender: Any) {
        manager.setPrevious()
    }
    
    // Update track with new artwork
    func updateTrackArtwork() {
        let status = ACWebSocketClient.shared.status
        if let artworkURL = status.artwork {
            print("loading client artwork")
            let processor = DownsamplingImageProcessor(size: albumImageView.bounds.size)
            Task {
                albumImageView.kf.indicatorType = .activity
                albumImageView.kf.setImage(with: artworkURL,
                                           options: [.processor(processor),
                                                     .scaleFactor(UIScreen.main.scale),
                                                     .transition(.fade(1))
                                           ])
                // Force app to update display
                self.view.setNeedsDisplay()
            }
            
            return
        }
        
        guard let artworkURL = status.artwork else {
            print("loading station artwork")
            manager.currentStation?.getImage { [weak self] image in
                self?.albumImageView.image = image
            }
            return
        }

        print("loading player artwork")
        let processor = DownsamplingImageProcessor(size: albumImageView.bounds.size)
        Task {
            albumImageView.kf.indicatorType = .activity
            albumImageView.kf.setImage(with: artworkURL,
                                       options: [.processor(processor),
                                                 .scaleFactor(UIScreen.main.scale),
                                                 .transition(.fade(1))
                                       ])
            
            // Force app to update display
            self.view.setNeedsDisplay()
        }
    }
    
    private func isPlayingDidChange(_ isPlaying: Bool) {
        playingButton.isSelected = isPlaying
        startNowPlayingAnimation(isPlaying)
    }
    
    func playbackStateDidChange(_ playbackState: FRadioPlayer.PlaybackState, animate: Bool) {
        
        let message: String?
        
        switch playbackState {
        case .paused:
            message = "Station Paused..."
        case .playing:
            message = nil
        case .stopped:
            message = "Station Stopped..."
        }
        
        updateLabels(with: message, animate: animate)
        isPlayingDidChange(player.isPlaying)
    }
    
    func playerStateDidChange(_ state: FRadioPlayer.State, animate: Bool) {
        
        let message: String?
        
        switch state {
        case .loading:
            if songLabel.text != ""{
                message = songLabel.text
            } else {
                message = "Station loading..."
            }
        case .urlNotSet:
            message = "Station URL not valid"
        case .readyToPlay, .loadingFinished:
            playbackStateDidChange(player.playbackState, animate: animate)
            return
        case .error:
            message = "Error playing stream"
        }
        updateLabels(with: message, animate: animate)
    }
    
    // MARK: - UI Helper Methods
    
    func optimizeForDeviceSize(size: CGSize) {
        // Adjust album size to fit iPhone 4s, 6s & 6s+
        print("height", size.height, "width", size.width)
        
        if size.width > size.height {
            print("horizontal")
            let imageHeight = self.view.bounds.height * 0.12
            albumHeightConstraint.constant = imageHeight
            print(imageHeight)
        } else {
            print("vertical")
            let imageHeight = self.view.bounds.height * 0.40
            albumHeightConstraint.constant = imageHeight
            print(imageHeight)
        }
        print(albumHeightConstraint.constant)
        view.updateConstraints()
        view.layoutIfNeeded()
    }
    
    func updateLabels(with statusMessage: String? = nil, animate: Bool = true) {
        
        guard let statusMessage = statusMessage else {
            // Radio is (hopefully) streaming properly
            self.liveDJIndicator.isHidden = false
            let status = ACWebSocketClient.shared.status
            if status.changed {
                self.liveDJIndicator.isHidden = !status.isLiveDJ
                songLabel.text = status.track
                artistLabel.text = status.artist
                releaseLabel.text = status.album
            } else {
                songLabel.text = manager.currentStation?.trackName
                artistLabel.text = manager.currentStation?.artistName
                releaseLabel.text = manager.currentStation?.releaseName
            }
            shouldAnimateSongLabel(animate)
            return
        }
        // There's a an interruption or pause in the audio queue
        print("Explicit status message \(String(describing: statusMessage))")

        // Update UI only when it's not already updated
        guard songLabel.text != statusMessage else { return }
            
        songLabel.text = statusMessage
        artistLabel.text = manager.currentStation?.name
            
        if animate {
            songLabel.animation = "flash"
            songLabel.repeatCount = 2
            songLabel.animate()
        }
    }
    
    // Animations
    
    func shouldAnimateSongLabel(_ animate: Bool) {
        // Animate if the Track has album metadata
        guard animate, player.currentMetadata != nil else { return }
        
        // songLabel animation
        songLabel.animation = "zoomIn"
        songLabel.duration = 1.5
        songLabel.damping = 1
        songLabel.animate()
    }
    
    func createNowPlayingAnimation() {
        // Setup ImageView
        nowPlayingImageView = UIImageView(image: UIImage(named: "NowPlayingBars-3"))
        nowPlayingImageView.autoresizingMask = []
        nowPlayingImageView.contentMode = UIView.ContentMode.center
        
        // Create Animation
        nowPlayingImageView.animationImages = AnimationFrames.createFrames()
        nowPlayingImageView.animationDuration = 0.7
        
        // Create Top BarButton
        let barButton = UIButton(type: .custom)
        barButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        barButton.addSubview(nowPlayingImageView)
        nowPlayingImageView.center = barButton.center
        
        let barItem = UIBarButtonItem(customView: barButton)
        self.navigationItem.rightBarButtonItem = barItem
    }
    
    func startNowPlayingAnimation(_ animate: Bool) {
        animate ? nowPlayingImageView.startAnimating() : nowPlayingImageView.stopAnimating()
    }
    
    @IBAction func infoButtonPressed(_ sender: UIButton) {
        guard let station = manager.currentStation else { return }
        delegate?.didTapInfoButton(self, station: station)
    }
    
    @IBAction func shareButtonPressed(_ sender: UIButton) {
        guard let station = manager.currentStation else { return }
        delegate?.didTapShareButton(self, station: station, artworkURL: player.currentArtworkURL)
    }
    
    @IBAction func handleCompanyButton(_ sender: Any) {
        delegate?.didTapCompanyButton(self)
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
}

extension NowPlayingViewController: StationsManagerObserver {
    func stationsManager(_ manager: StationsManager, stationDidChange station: RadioStation?) {
        stationDidChange()
    }
}
