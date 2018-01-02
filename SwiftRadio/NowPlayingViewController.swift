//
//  NowPlayingViewController.swift
//  Swift Radio
//
//  Created by Matthew Fecher on 7/22/15.
//  Copyright (c) 2015 MatthewFecher.com. All rights reserved.
//

import UIKit
import MediaPlayer

//*****************************************************************
// NowPlayingViewController
//*****************************************************************

class NowPlayingViewController: UIViewController {

    // MARK: - IB UI
    
    @IBOutlet weak var albumHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var albumImageView: SpringImageView!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var playingButton: UIButton!
    @IBOutlet weak var songLabel: SpringLabel!
    @IBOutlet weak var stationDescLabel: UILabel!
    @IBOutlet weak var volumeParentView: UIView!
    
    // MARK: - Properties
    
    var currentStation: RadioStation!
    var newStation = true
    var nowPlayingImageView: UIImageView!
    let radioPlayer = FRadioPlayer.shared
    var currentTrack = Track()
    var mpVolumeSlider: UISlider?

    //*****************************************************************
    // MARK: - ViewDidLoad
    //*****************************************************************
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup Player
        playingButton.isSelected = radioPlayer.isPlaying
        
        // Set AlbumArtwork Constraints
        optimizeForDeviceSize()

        // Set View Title
        self.title = currentStation.name
        
        // Create Now Playing BarItem
        createNowPlayingAnimation()
        
        // Set UI
        albumImageView.image = currentTrack.artworkImage
        stationDescLabel.text = currentStation.desc
        stationDescLabel.isHidden = currentTrack.artworkLoaded
        
        // Check for station change
        if newStation {
            stationDidChange()
        } else {
            playerStateDidChange(radioPlayer.state)
            playingButton.isSelected = radioPlayer.isPlaying
            startNowPlayingAnimation(radioPlayer.isPlaying)
        }
        
        // Setup volumeSlider
        setupVolumeSlider()
    }
    
    //*****************************************************************
    // MARK: - Setup
    //*****************************************************************
    
    func setupVolumeSlider() {
        // Note: This slider implementation uses a MPVolumeView
        // The volume slider only works in devices, not the simulator.
        for subview in MPVolumeView().subviews {
            guard let volumeSlider = subview as? UISlider else { continue }
            mpVolumeSlider = volumeSlider
        }
        
        guard let mpVolumeSlider = mpVolumeSlider else { return }
        
        volumeParentView.addSubview(mpVolumeSlider)
        mpVolumeSlider.frame = volumeParentView.bounds
        mpVolumeSlider.setThumbImage(#imageLiteral(resourceName: "slider-ball"), for: .normal)
    }
    
    func stationDidChange() {
        radioPlayer.radioURL = URL(string: currentStation.streamURL)
    }
    
    //*****************************************************************
    // MARK: - Player Controls (Play/Pause/Volume)
    //*****************************************************************
    
    @IBAction func togglePlaying() {
        radioPlayer.togglePlaying()
    }
    
    @IBAction func stopPressed(_ sender: Any) {
        radioPlayer.stop()
        updateLabels(with: "Station Stopped...")
    }
    
    func play() {
        updateLabels()
    }
    
    func pause() {
        updateLabels(with: "Station Paused...")
    }
    
    //*****************************************************************
    // MARK: - Load station/track
    //*****************************************************************
    
    func load(station: RadioStation?, track: Track, isNewStation: Bool) {
        guard let station = station else { return }
        
        currentStation = station
        currentTrack = track
        newStation = isNewStation
    }
    
    func updateTrackMetadata(with track: Track) {
        
        currentTrack.artist = track.artist
        currentTrack.title = track.title
        
        updateLabels()
        
        // Animate if the Track has album metadata
        guard currentTrack.title != currentStation.name else { return }
        
        // songLabel animation
        songLabel.animation = "zoomIn"
        songLabel.duration = 1.5
        songLabel.damping = 1
        songLabel.animate()
    }
    
    // Update track with new artwork
    func updateTrackArtwork(with track: Track) {
        
        // Update track struct
        currentTrack.artworkImage = track.artworkImage
        currentTrack.artworkLoaded = track.artworkLoaded
        
        albumImageView.image = currentTrack.artworkImage
        
        if track.artworkLoaded {
            // Animate artwork
            albumImageView.animation = "wobble"
            albumImageView.duration = 2
            albumImageView.animate()
            stationDescLabel.isHidden = true
        } else {
            stationDescLabel.isHidden = false
        }
        
        // Force app to update display
        view.setNeedsDisplay()
    }
    
    func isPlayingDidChange(_ isPlaying: Bool) {
        isPlaying ? play() : pause()
        playingButton.isSelected = isPlaying
        startNowPlayingAnimation(isPlaying)
    }
    
    //*****************************************************************
    // MARK: - UI Helper Methods
    //*****************************************************************
    
    func optimizeForDeviceSize() {
        
        // Adjust album size to fit iPhone 4s, 6s & 6s+
        let deviceHeight = self.view.bounds.height
        
        if deviceHeight == 480 {
            albumHeightConstraint.constant = 106
            view.updateConstraints()
        } else if deviceHeight == 667 {
            albumHeightConstraint.constant = 230
            view.updateConstraints()
        } else if deviceHeight > 667 {
            albumHeightConstraint.constant = 260
            view.updateConstraints()
        }
    }
    
    // TODO: Should be refactored
    func updateLabels(with statusMessage: String = "") {

        if statusMessage != "" {
            // There's a an interruption or pause in the audio queue
            
            // Update UI only when it's not aleary updated
            guard songLabel.text != statusMessage else { return }
            songLabel.text = statusMessage
            artistLabel.text = currentStation.name
            
            // songLabel animate
            songLabel.animation = "flash"
            songLabel.repeatCount = 3
            songLabel.animate()
            
        } else {
            // Radio is (hopefully) streaming properly
            
            // Update UI only when it's not aleary updated
            guard songLabel.text != currentTrack.title else { return }
            
            songLabel.text = currentTrack.title
            artistLabel.text = currentTrack.artist
        }
    }
    
    func playerStateDidChange(_ state: FRadioPlayerState) {
        
        let message: String
        
        switch state {
        case .loading:
            message = "Loading Station ..."
        case .urlNotSet:
            message = "Station URL not valide"
        case .readyToPlay, .loadingFinished:
            message = ""
        case .error:
            message = "Error Playing"
        }
        
        updateLabels(with: message)
    }
    
    func createNowPlayingAnimation() {
        
        // Setup ImageView
        nowPlayingImageView = UIImageView(image: UIImage(named: "NowPlayingBars-3"))
        nowPlayingImageView.autoresizingMask = []
        nowPlayingImageView.contentMode = UIViewContentMode.center
        
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
    
    //*****************************************************************
    // MARK: - Segue
    //*****************************************************************
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "InfoDetail", let infoController = segue.destination as? InfoDetailViewController else { return }
        infoController.currentStation = currentStation
    }
    
    @IBAction func infoButtonPressed(_ sender: UIButton) {
        performSegue(withIdentifier: "InfoDetail", sender: self)
    }
    
    @IBAction func shareButtonPressed(_ sender: UIButton) {
        let songToShare = "I'm listening to \(currentTrack.title) on \(currentStation.name) via Swift Radio Pro"
        let activityViewController = UIActivityViewController(activityItems: [songToShare, currentTrack.artworkImage!], applicationActivities: nil)
        present(activityViewController, animated: true, completion: nil)
    }
}
