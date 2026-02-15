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
import Combine
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
    private let metadataManager = StationMetadataManager.shared
    
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
    private var metadataCallback: MetadataChangeCallback?
    private var lastStatusMessage: String?
    private var wasPlaying = false
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - ViewDidLoad
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.largeTitleDisplayMode = .never
        if manager.stations.count < 2 {
            navigationItem.hidesBackButton = true
        }
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
        
        // Subscribe to unified metadata changes
        metadataCallback = { [weak self] metadata in
            self?.handleMetadataUpdate(metadata)
        }
        metadataManager.subscribeToMetadataChanges(metadataCallback!)

        // Observe connection state for audio restart after WiFi recovery.
        // Use removeDuplicates + scan to detect transitions TO .connected
        // from a non-connected state. Only restart the audio player -
        // do NOT call reloadCurrent() as that triggers connectToStation()
        // via currentStation didSet, creating a feedback loop.
        metadataManager.$connectionState
            .removeDuplicates()
            .scan((MetadataConnectionState.disconnected, MetadataConnectionState.disconnected)) { previous, current in
                (previous.1, current)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (previous, current) in
                guard let self = self else { return }
                if current == .connected && previous != .connected && self.wasPlaying {
                    self.player.radioURL = URL(string: self.manager.currentStation?.streamURL ?? "")
                    self.player.play()
                } else if previous == .connected && current != .connected && self.wasPlaying {
                    // Stop AVPlayer to prevent aggressive internal retries while offline.
                    // wasPlaying stays true so audio restarts on recovery.
                    self.player.stop()
                }
            }
            .store(in: &cancellables)

        isPlayingDidChange(player.isPlaying)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { _ in
            print("rotating")
            self.optimizeForDeviceSize(size: size)
        })
    }
    
    func handleMetadataUpdate(_ metadata: UnifiedMetadata?) {
        guard let metadata = metadata else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Update UI with unified metadata
            self.artistLabel.text = metadata.artistName
            self.songLabel.text = metadata.trackName
            self.releaseLabel.text = metadata.albumName ?? ""
            self.djName.text = metadata.djName ?? ""
            
            // Update live DJ indicator
            self.liveDJIndicator.isHidden = !metadata.isLiveDJ
            
            // Update artwork
            if let artworkURL = metadata.artworkURL {
                let processor = DownsamplingImageProcessor(size: self.albumImageView.bounds.size)
                self.albumImageView.kf.indicatorType = .activity
                self.albumImageView.kf.setImage(with: artworkURL,
                                               options: [.processor(processor),
                                                         .scaleFactor(UIScreen.main.scale),
                                                         .transition(.fade(1))
                                               ])
            } else {
                // Fallback to station artwork
                self.manager.currentStation?.getImage { [weak self] image in
                    self?.albumImageView.image = image
                }
            }
        }
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
        // Remove only the previous UI metadata subscriber, not all subscribers
        if let callback = metadataCallback {
            metadataManager.unsubscribeFromMetadataChanges(callback)
        }
        metadataCallback = { [weak self] metadata in
            self?.handleMetadataUpdate(metadata)
        }
        metadataManager.subscribeToMetadataChanges(metadataCallback!)
    }
    
    // MARK: - Player Controls (Play/Pause/Volume)
        
    @IBAction func playingPressed(_ sender: Any) {
        if player.isPlaying {
            wasPlaying = false
            player.stop()
        } else {
            wasPlaying = true
            manager.reloadCurrent()  // Reconnect to stream
            player.play()
            updateLabels()
        }
    }
        
    @IBAction func nextPressed(_ sender: Any) {
        manager.setNext()
        updateLabels()
    }
    
    @IBAction func previousPressed(_ sender: Any) {
        manager.setPrevious()
        updateLabels()
    }
    
    // Update track with new artwork
    func updateTrackArtwork() {
        // Artwork updates are now handled by the unified metadata system
        // This method is kept for backward compatibility but delegates to metadata manager
        if let metadata = metadataManager.getCurrentMetadata(), let artworkURL = metadata.artworkURL {
            let processor = DownsamplingImageProcessor(size: albumImageView.bounds.size)
            Task {
                albumImageView.kf.indicatorType = .activity
                albumImageView.kf.setImage(with: artworkURL,
                                           options: [.processor(processor),
                                                     .scaleFactor(UIScreen.main.scale),
                                                     .transition(.fade(1))
                                           ])
            }
        } else {
            if manager.currentStation == nil { return }
            if manager.currentStation?.defaultArtwork != nil {
                self.albumImageView.image = manager.currentStation?.defaultArtwork
            } else {
                manager.currentStation?.getImage { [weak self] image in
                    self?.albumImageView.image = image
                }
            }
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
            var imageHeight: CGFloat
            //if size.height < 750 {
            if  UIDevice.current.userInterfaceIdiom != .pad {
                imageHeight = self.view.bounds.height * 0.12
                if imageHeight < 100 {
                    imageHeight = 0.00
                }
            } else {
                imageHeight = self.view.bounds.height * 0.40
            }
            
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
            // Radio is (hopefully) streaming properly - use unified metadata
            if let metadata = metadataManager.getCurrentMetadata() {
                self.liveDJIndicator.isHidden = !metadata.isLiveDJ
                if !metadata.trackName.isEmpty {
                    songLabel.text = metadata.trackName
                    artistLabel.text = metadata.artistName
                    releaseLabel.text = metadata.albumName ?? ""
                }
            }
            
            shouldAnimateSongLabel(animate)
            return
        }
        
        // Debounce: Only update if the message is different
        if statusMessage == lastStatusMessage {
            // Optionally, print debug info here
            return
        }
        lastStatusMessage = statusMessage
        
        // Update UI only when it's not already updated
        guard songLabel.text != "" else { return }
            
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
        // Animate if the Track has metadata
        guard animate, metadataManager.getCurrentMetadata() != nil else { return }
        
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
        let artworkURL = metadataManager.getCurrentMetadata()?.artworkURL ?? player.currentArtworkURL
        delegate?.didTapShareButton(self, station: station, artworkURL: artworkURL)
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
