//
//  FRadioPlayer.swift
//  FRadioPlayerDemo
//
//  Created by Fethi El Hassasna on 2017-11-11.
//  Copyright © 2017 Fethi El Hassasna. All rights reserved.
//

import AVFoundation

// MARK: - FRadioPlayerState

/**
 `FRadioPlayerState` is the Player status enum
 */

@objc public enum FRadioPlayerState: Int {
    
    /// URL not set
    case urlNotSet
    
    /// Player is ready to play
    case readyToPlay
    
    /// Player is loading
    case loading
    
    /// The loading has finished
    case loadingFinished
    
    /// Error with playing
    case error
    
    /// Return a readable description
    public var description: String {
        switch self {
        case .urlNotSet: return "URL is not set"
        case .readyToPlay: return "Ready to play"
        case .loading: return "Loading"
        case .loadingFinished: return "Loading finished"
        case .error: return "Error"
        }
    }
}

// MARK: - FRadioPlayerDelegate

/**
 The `FRadioPlayerDelegate` protocol defines methods you can implement to respond to playback events associated with an `FRadioPlayer` object.
 */

@objc public protocol FRadioPlayerDelegate: class {
    /**
     Called when player changes state
     
     - parameter player: FRadioPlayer
     - parameter state: FRadioPlayerState
     */
    func radioPlayer(_ player: FRadioPlayer, playerStateDidChange state: FRadioPlayerState)
    
    /**
     Called when the player changes the playing state
     
     - parameter player: FRadioPlayer
     - parameter playing: Bool value
     */
    @objc optional func radioPlayer(_ player: FRadioPlayer, player isPlaying: Bool)
    
    /**
     Called when player changes the current player item
     
     - parameter player: FRadioPlayer
     - parameter url: Radio URL
     */
    @objc optional func radioPlayer(_ player: FRadioPlayer, itemDidChange url: URL?)
    
    /**
     Called when player item changes the timed metadata value, it uses (separatedBy: " - ") to get the artist/song name, if you want more control over the raw metadata, consider using `metadataDidChange rawValue` instead
     
     - parameter player: FRadioPlayer
     - parameter artistName: The artist name
     - parameter trackName: The track name
     */
    @objc optional func radioPlayer(_ player: FRadioPlayer, metadataDidChange artistName: String?, trackName: String?)
    
    /**
     Called when player item changes the timed metadata value
     
     - parameter player: FRadioPlayer
     - parameter rawValue: metadata raw value
     */
    @objc optional func radioPlayer(_ player: FRadioPlayer, metadataDidChange rawValue: String?)
    
    /**
     Called when the player gets the artwork for the playing song
     
     - parameter player: FRadioPlayer
     - parameter artURL: URL for the artwork from iTunes
     */
    @objc optional func radioPlayer(_ player: FRadioPlayer, artworkDidChange artURL: URL?)
}

// MARK: - FRadioPlayer

/**
 FRadioPlayer is a wrapper around AVPlayer to handle internet radio playback.
 */

open class FRadioPlayer: NSObject {
    
    // MARK: - Properties
    
    /// Returns the singleton `FRadioPlayer` instance.
    open static let shared = FRadioPlayer()
    
    /**
     The delegate object for the `FRadioPlayer`.
     Implement the methods declared by the `FRadioPlayerDelegate` object to respond to user interactions and the player output.
     */
    open weak var delegate: FRadioPlayerDelegate?
    
    /// The player current radio URL
    open var radioURL: URL? {
        didSet {
            radioURLDidChange(with: radioURL)
        }
    }
    
    /// The player starts playing when the radioURL property gets set. (default == true)
    open var isAutoPlay = true
    
    /// Enable fetching albums artwork from the iTunes API. (default == true)
    open var enableArtwork = true
    
    /// Artwork image size. (default == 100 | 100x100)
    open var artworkSize = 100
    
    /// Read only property to get the current AVPlayer rate.
    open var rate: Float? {
        return player?.rate
    }
    
    // MARK: - Private properties
    
    /// AVPlayer
    private var player: AVPlayer?
    
    /// Player state of type `FRadioPlayerState`
    private var state = FRadioPlayerState.urlNotSet {
        didSet {
            guard oldValue != state else { return }
            delegate?.radioPlayer(self, playerStateDidChange: state)
        }
    }
    
    /// Check is playing state
    private var isPlaying: Bool = false {
        didSet {
            delegate?.radioPlayer?(self, player: isPlaying)
        }
    }
    
    /// Last player item
    private var lastPlayerItem: AVPlayerItem?
    
    /// Check for headphones, used to handle audio route change
    private var headphonesConnected: Bool = false
    
    /// Default player item
    private var playerItem: AVPlayerItem? {
        didSet {
            playerItemDidChange()
        }
    }
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        
        // Enable bluetooth playback
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(AVAudioSessionCategoryPlayback, with: [.defaultToSpeaker, .allowBluetooth])
        
        // Notifications
        setupNotifications()
        
        // Check for headphones
        checkHeadphonesConnection(outputs: AVAudioSession.sharedInstance().currentRoute.outputs)
    }
    
    // MARK: - Control Methods
    
    /**
     Trigger the play function of the radio player
     
     */
    open func play() {
        guard let player = player else { return }
        if player.currentItem == nil, playerItem != nil {
            player.replaceCurrentItem(with: playerItem)
        }
        
        player.play()
        isPlaying = true
    }
    
    /**
     Trigger the pause function of the radio player
     
     */
    open func pause() {
        guard let player = player else { return }
        player.pause()
        isPlaying = false
    }
    
    /**
     Trigger the stop function of the radio player
     
     */
    open func stop() {
        guard let player = player else { return }
        player.replaceCurrentItem(with: nil)
        timedMetadataDidChange(rawValue: nil)
        isPlaying = false
    }
    
    // MARK: - Private helpers
    
    private func radioURLDidChange(with url: URL?) {
        guard let url = url else {
            state = .urlNotSet
            stop()
            return
        }
        
        state = .loading
        
        preparePlayer(with: AVAsset(url: url)) { (success, asset) in
            guard success, let asset = asset else {
                self.state = .error
                return
            }
            self.setupPlayer(with: asset)
        }
    }
    
    private func setupPlayer(with asset: AVAsset) {
        if player == nil {
            player = AVPlayer()
        }
        
        playerItem = AVPlayerItem(asset: asset)
    }
    
    /** Reset all player item observers and create new ones
     
     */
    private func playerItemDidChange() {
        
        guard lastPlayerItem != playerItem else { return }
        
        if let item = lastPlayerItem {
            pause()
            
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: item)
            item.removeObserver(self, forKeyPath: "status")
            item.removeObserver(self, forKeyPath: "playbackBufferEmpty")
            item.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
            item.removeObserver(self, forKeyPath: "timedMetadata")
        }
        
        lastPlayerItem = playerItem
        timedMetadataDidChange(rawValue: nil)
        
        if let item = playerItem {
            
            item.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.new, context: nil)
            item.addObserver(self, forKeyPath: "playbackBufferEmpty", options: NSKeyValueObservingOptions.new, context: nil)
            item.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: NSKeyValueObservingOptions.new, context: nil)
            item.addObserver(self, forKeyPath: "timedMetadata", options: NSKeyValueObservingOptions.new, context: nil)
            
            player?.replaceCurrentItem(with: item)
            if isAutoPlay { play() }
        }
        
        delegate?.radioPlayer?(self, itemDidChange: radioURL)
    }
    
    /** Prepare the player from the passed AVAsset
     
     */
    private func preparePlayer(with asset: AVAsset?, completionHandler: @escaping (_ isPlayable: Bool, _ asset: AVAsset?)->()) {
        guard let asset = asset else {
            completionHandler(false, nil)
            return
        }
        
        let requestedKey = ["playable"]
        
        asset.loadValuesAsynchronously(forKeys: requestedKey) {
            
            DispatchQueue.main.async {
                var error: NSError?
                
                let keyStatus = asset.statusOfValue(forKey: "playable", error: &error)
                if keyStatus == AVKeyValueStatus.failed || !asset.isPlayable {
                    completionHandler(false, nil)
                    return
                }
                
                completionHandler(true, asset)
            }
        }
    }
    
    private func timedMetadataDidChange(rawValue: String?) {
        let parts = rawValue?.components(separatedBy: " - ")
        delegate?.radioPlayer?(self, metadataDidChange: parts?.first, trackName: parts?.last)
        delegate?.radioPlayer?(self, metadataDidChange: rawValue)
        shouldGetArtwork(for: rawValue, enableArtwork)
    }
    
    private func shouldGetArtwork(for rawValue: String?, _ enabled: Bool) {
        guard enabled else { return }
        guard let rawValue = rawValue else {
            self.delegate?.radioPlayer?(self, artworkDidChange: nil)
            return
        }
        
        FRadioAPI.getArtwork(for: rawValue, size: artworkSize, completionHandler: { [unowned self] artworlURL in
            DispatchQueue.main.async {
                self.delegate?.radioPlayer?(self, artworkDidChange: artworlURL)
            }
        })
    }
    
    private func resetPlayer() {
        radioURL = nil
        playerItem = nil
        lastPlayerItem = nil
        player?.replaceCurrentItem(with: nil)
        player = nil
    }
    
    deinit {
        resetPlayer()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Notifications
    
    private func setupNotifications() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(handleInterruption), name: .AVAudioSessionInterruption, object: nil)
        notificationCenter.addObserver(self, selector: #selector(handleRouteChange), name: .AVAudioSessionRouteChange, object: nil)
    }
    
    // Responding to Interruptions
    
    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSessionInterruptionType(rawValue: typeValue) else {
                return
        }
        
        switch type {
        case .began:
            DispatchQueue.main.async { self.pause() }
        case .ended:
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { break }
            let options = AVAudioSessionInterruptionOptions(rawValue: optionsValue)
            DispatchQueue.main.async { options.contains(.shouldResume) ? self.play() : self.pause() }
        }
    }
    
    // Responding to Route Changes
    
    private func checkHeadphonesConnection(outputs: [AVAudioSessionPortDescription]) {
        for output in outputs where output.portType == AVAudioSessionPortHeadphones {
            headphonesConnected = true
            break
        }
        headphonesConnected = false
    }
    
    @objc private func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
            let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
            let reason = AVAudioSessionRouteChangeReason(rawValue:reasonValue) else { return }
        
        switch reason {
        case .newDeviceAvailable:
            checkHeadphonesConnection(outputs: AVAudioSession.sharedInstance().currentRoute.outputs)
        case .oldDeviceUnavailable:
            guard let previousRoute = userInfo[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription else { return }
            checkHeadphonesConnection(outputs: previousRoute.outputs);
            DispatchQueue.main.async { self.headphonesConnected ? () : self.pause() }
        default: break
        }
    }
    
    // MARK: - KVO
    
    /// :nodoc:
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if let item = object as? AVPlayerItem, let keyPath = keyPath, item == self.playerItem {
            
            switch keyPath {
                
            case "status":
                
                if player?.status == AVPlayerStatus.readyToPlay {
                    self.state = .readyToPlay
                } else if player?.status == AVPlayerStatus.failed {
                    self.state = .error
                }
                
            case "playbackBufferEmpty":
                
                if item.isPlaybackBufferEmpty { self.state = .loading }
                
            case "playbackLikelyToKeepUp":
                
                self.state = item.isPlaybackLikelyToKeepUp ? .loadingFinished : .loading
            
            case "timedMetadata":
                let rawValue = item.timedMetadata?.first?.value as? String
                timedMetadataDidChange(rawValue: rawValue)
                
            default:
                break
            }
        }
    }
}
