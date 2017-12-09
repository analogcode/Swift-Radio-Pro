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
// Protocol
// Updates the StationsViewController when the track changes
//*****************************************************************

protocol NowPlayingViewControllerDelegate: class {
    func songMetaDataDidUpdate(track: Track)
    func artworkDidUpdate(track: Track)
    func trackPlayingToggled(track: Track)
}

//*****************************************************************
// NowPlayingViewController
//*****************************************************************

class NowPlayingViewController: UIViewController {

    @IBOutlet weak var albumHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var albumImageView: SpringImageView!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var songLabel: SpringLabel!
    @IBOutlet weak var stationDescLabel: UILabel!
    @IBOutlet weak var volumeParentView: UIView!
    @IBOutlet weak var slider = UISlider()
    
    var currentStation: RadioStation!
    var justBecameActive = false
    var newStation = true
    var nowPlayingImageView: UIImageView!
    let radioPlayer = FRadioPlayer.shared
    var track: Track!
    var mpVolumeSlider = UISlider()
    
    weak var delegate: NowPlayingViewControllerDelegate?
    
    //*****************************************************************
    // MARK: - ViewDidLoad
    //*****************************************************************
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup Player
        radioPlayer.delegate = self
        
        // Setup handoff functionality - GH
        setupUserActivity()
        
        // Set AlbumArtwork Constraints
        optimizeForDeviceSize()

        // Set View Title
        self.title = currentStation.stationName
        
        // Create Now Playing BarItem
        createNowPlayingAnimation()
        
        // Notification for when app becomes active
        NotificationCenter.default.addObserver(self,
            selector: #selector(NowPlayingViewController.didBecomeActiveNotificationReceived),
            name: Notification.Name("UIApplicationDidBecomeActiveNotification"),
            object: nil)
        
        // Check for station change
        if newStation {
            track = Track()
            stationDidChange()
        } else {
            updateLabels()
            albumImageView.image = track.artworkImage
            
            if !track.isPlaying {
                pausePressed()
            } else {
                nowPlayingImageView.startAnimating()
            }
        }
        
        // Setup slider
        setupVolumeSlider()
        
    }
    
    @objc func didBecomeActiveNotificationReceived() {
        // View became active
        updateLabels()
        justBecameActive = true
        updateAlbumArtwork()
    }
    
    deinit {
        // Be a good citizen
        NotificationCenter.default.removeObserver(self,
            name: Notification.Name("UIApplicationDidBecomeActiveNotification"),
            object: nil)
        NotificationCenter.default.removeObserver(self,
            name: Notification.Name.AVAudioSessionInterruption,
            object: AVAudioSession.sharedInstance())
    }
    
    //*****************************************************************
    // MARK: - Setup
    //*****************************************************************
    
    func setupVolumeSlider() {
        // Note: This slider implementation uses a MPVolumeView
        // The volume slider only works in devices, not the simulator.
        volumeParentView.backgroundColor = UIColor.clear
        let volumeView = MPVolumeView(frame: volumeParentView.bounds)
        for view in volumeView.subviews {
            let uiview: UIView = view as UIView
            if (uiview.description as NSString).range(of: "MPVolumeSlider").location != NSNotFound {
                mpVolumeSlider = (uiview as! UISlider)
            }
        }
        
        let thumbImageNormal = UIImage(named: "slider-ball")
        slider?.setThumbImage(thumbImageNormal, for: .normal)
        
    }
    
    func stationDidChange() {
        
        radioPlayer.radioURL = URL(string: currentStation.stationStreamURL)
        
        updateLabels(statusMessage: "Loading Station...")
        
        // songLabel animate
        songLabel.animation = "flash"
        songLabel.repeatCount = 3
        songLabel.animate()
        
        resetAlbumArtwork()
        
        track.isPlaying = true
    }
    
    //*****************************************************************
    // MARK: - Player Controls (Play/Pause/Volume)
    //*****************************************************************
    
    @IBAction func playPressed() {
        track.isPlaying = true
        playButtonEnable(enabled: false)
        radioPlayer.play()
        updateLabels()
        
        // songLabel Animation
        songLabel.animation = "flash"
        songLabel.animate()
        
        // Start NowPlaying Animation
        nowPlayingImageView.startAnimating()
        
        // Update StationsVC
        self.delegate?.trackPlayingToggled(track: self.track)
    }
    
    @IBAction func pausePressed() {
        track.isPlaying = false
        
        playButtonEnable()
        
        radioPlayer.pause()
        updateLabels(statusMessage: "Station Paused...")
        nowPlayingImageView.stopAnimating()
        
        // Update StationsVC
        self.delegate?.trackPlayingToggled(track: self.track)
    }
    
    @IBAction func volumeChanged(_ sender:UISlider) {
        mpVolumeSlider.value = sender.value
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
    
    func updateLabels(statusMessage: String = "") {
        
        if statusMessage != "" {
            // There's a an interruption or pause in the audio queue
            songLabel.text = statusMessage
            artistLabel.text = currentStation.stationName
            
        } else {
            // Radio is (hopefully) streaming properly
            if track != nil {
                songLabel.text = track.title
                artistLabel.text = track.artist
            }
        }
        
        // Hide station description when album art is displayed or on iPhone 4
        if track.artworkLoaded {
            stationDescLabel.isHidden = true
        } else {
            stationDescLabel.isHidden = false
            stationDescLabel.text = currentStation.stationDesc
        }
    }
    
    func playButtonEnable(enabled: Bool = true) {
        if enabled {
            playButton.isEnabled = true
            pauseButton.isEnabled = false
            track.isPlaying = false
        } else {
            playButton.isEnabled = false
            pauseButton.isEnabled = true
            track.isPlaying = true
        }
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
        let barButton = UIButton(type: UIButtonType.custom)
        barButton.frame = CGRect(x: 0,y: 0,width: 40,height: 40);
        barButton.addSubview(nowPlayingImageView)
        nowPlayingImageView.center = barButton.center
        
        let barItem = UIBarButtonItem(customView: barButton)
        self.navigationItem.rightBarButtonItem = barItem
        
    }
    
    func startNowPlayingAnimation() {
        nowPlayingImageView.startAnimating()
    }
    
    //*****************************************************************
    // MARK: - Album Art
    //*****************************************************************
    
    func resetAlbumArtwork() {
        track.artworkLoaded = false
        track.artworkURL = currentStation.stationImageURL
        updateAlbumArtwork()
        stationDescLabel.isHidden = false
    }
    
    func updateAlbumArtwork() {
        track.artworkLoaded = false
        if track.artworkURL.range(of: "http") != nil {
            
            // Hide station description
            DispatchQueue.main.async(execute: {
                //self.albumImageView.image = nil
                self.stationDescLabel.isHidden = false
            })
            
            // Attempt to download album art from an API
            if let url = URL(string: track.artworkURL) {
                
                self.albumImageView.loadImageWithURL(url: url) { (image) in
                    
                    // Update track struct
                    self.track.artworkImage = image
                    self.track.artworkLoaded = true
                    
                    // Turn off network activity indicator
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        
                    // Animate artwork
                    self.albumImageView.animation = "wobble"
                    self.albumImageView.duration = 2
                    self.albumImageView.animate()
                    self.stationDescLabel.isHidden = true

                    // Update lockscreen
                    self.updateLockScreen()
                    
                    // Call delegate function that artwork updated
                    self.delegate?.artworkDidUpdate(track: self.track)
                }
            }
            
            // Hide the station description to make room for album art
            if track.artworkLoaded && !self.justBecameActive {
                self.stationDescLabel.isHidden = true
                self.justBecameActive = false
            }
            
        } else if track.artworkURL != "" {
            // Local artwork
            self.albumImageView.image = UIImage(named: track.artworkURL)
            track.artworkImage = albumImageView.image
            track.artworkLoaded = true
            
            // Call delegate function that artwork updated
            self.delegate?.artworkDidUpdate(track: self.track)
            
        } else {
            // No Station or API art found, use default art
            self.albumImageView.image = UIImage(named: "albumArt")
            track.artworkImage = albumImageView.image
        }
        
        // Force app to update display
        self.view.setNeedsDisplay()
    }
    
    //*****************************************************************
    // MARK: - Segue
    //*****************************************************************
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "InfoDetail" {
            let infoController = segue.destination as! InfoDetailViewController
            infoController.currentStation = currentStation
        }
    }
    
    @IBAction func infoButtonPressed(_ sender: UIButton) {
        performSegue(withIdentifier: "InfoDetail", sender: self)
    }
    
    @IBAction func shareButtonPressed(_ sender: UIButton) {
        let songToShare = "I'm listening to \(track.title) on \(currentStation.stationName) via Swift Radio Pro"
        let activityViewController = UIActivityViewController(activityItems: [songToShare, track.artworkImage!], applicationActivities: nil)
        present(activityViewController, animated: true, completion: nil)
    }
    
    //*****************************************************************
    // MARK: - MPNowPlayingInfoCenter (Lock screen)
    //*****************************************************************
    
    func updateLockScreen() {
        
        // Update notification/lock screen
        let albumArtwork = MPMediaItemArtwork(image: track.artworkImage!)
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyArtist: track.artist,
            MPMediaItemPropertyTitle: track.title,
            MPMediaItemPropertyArtwork: albumArtwork
        ]
    }
    
    override func remoteControlReceived(with receivedEvent: UIEvent?) {
        super.remoteControlReceived(with: receivedEvent)
        
        if receivedEvent!.type == UIEventType.remoteControl {
            
            switch receivedEvent!.subtype {
            case .remoteControlPlay:
                playPressed()
            case .remoteControlPause:
                pausePressed()
            default:
                break
            }
        }
    }
    
    //*****************************************************************
    // MARK: - Handoff Functionality - GH
    //*****************************************************************
    
    func setupUserActivity() {
        let activity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb ) //"com.graemeharrison.handoff.googlesearch" //NSUserActivityTypeBrowsingWeb
        userActivity = activity
        let url = "https://www.google.com/search?q=\(self.artistLabel.text!)+\(self.songLabel.text!)"
        let urlStr = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        let searchURL : URL = URL(string: urlStr!)!
        activity.webpageURL = searchURL
        userActivity?.becomeCurrent()
    }
    
    override func updateUserActivityState(_ activity: NSUserActivity) {
        let url = "https://www.google.com/search?q=\(self.artistLabel.text!)+\(self.songLabel.text!)"
        let urlStr = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        let searchURL : URL = URL(string: urlStr!)!
        activity.webpageURL = searchURL
        super.updateUserActivityState(activity)
    }
}

extension NowPlayingViewController: FRadioPlayerDelegate {
    
    func radioPlayer(_ player: FRadioPlayer, playerStateDidChange state: FRadioPlayerState) {

    }
    
    func radioPlayer(_ player: FRadioPlayer, player isPlaying: Bool) {

    }
    
    func radioPlayer(_ player: FRadioPlayer, metadataDidChange artistName: String?, trackName: String?) {
        
        // TODO: refactor to separate function
        // Reset label/artwork to it's initial state
        resetAlbumArtwork()
        artistLabel.text = currentStation.stationDesc
        songLabel.text = currentStation.stationName
        
        // TODO: Should listen to Track didSet
        track.artist = artistName ?? currentStation.stationDesc
        track.title = trackName ?? currentStation.stationName
        
        if track.title != currentStation.stationName {
            artistLabel.text = self.track.artist
            songLabel.text = self.track.title
            updateUserActivityState(self.userActivity!)
            
            // songLabel animation
            songLabel.animation = "zoomIn"
            songLabel.duration = 1.5
            songLabel.damping = 1
            songLabel.animate()
            
            // Query API for album art
            resetAlbumArtwork()
            updateLockScreen()
            
            delegate?.songMetaDataDidUpdate(track: self.track)
        }
    }
    
    func radioPlayer(_ player: FRadioPlayer, itemDidChange url: URL?) {

    }
    
    func radioPlayer(_ player: FRadioPlayer, metadataDidChange rawValue: String?) {
        startNowPlayingAnimation()
    }
    
    func radioPlayer(_ player: FRadioPlayer, artworkDidChange artworkURL: URL?) {
        
        guard let artworkURL = artworkURL else {
            resetAlbumArtwork()
            return
        }
        
        track.artworkURL = artworkURL.absoluteString
        track.artworkLoaded = true
        updateAlbumArtwork()
    }
    
    
}
