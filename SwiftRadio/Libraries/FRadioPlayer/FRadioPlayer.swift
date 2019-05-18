//
//  FRadioPlayer.swift
//  FRadioPlayer
//
//  Created by Fethi El Hassasna on 2017-11-11.
//  Copyright © 2017 Fethi El Hassasna (@fethica). All rights reserved.
//

import AVFoundation

// MARK: - FRadioPlayingState

/**
 `FRadioPlayingState` is the Player playing state enum
 */

@objc public enum FRadioPlaybackState: Int {
    
    /// Player is playing
    case playing
    
    /// Player is paused
    case paused
    
    /// Player is stopped
    case stopped
    
    /// Return a readable description
    public var description: String {
        switch self {
        case .playing: return "Player is playing"
        case .paused: return "Player is paused"
        case .stopped: return "Player is stopped"
        }
    }
}

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
     - parameter state: FRadioPlaybackState
     */
    func radioPlayer(_ player: FRadioPlayer, playbackStateDidChange state: FRadioPlaybackState)
    
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
     - parameter artworkURL: URL for the artwork from iTunes
     */
    @objc optional func radioPlayer(_ player: FRadioPlayer, artworkDidChange artworkURL: URL?)
}

// MARK: - FRadioPlayer

/**
 FRadioPlayer is a wrapper around AVPlayer to handle internet radio playback.
 */

open class FRadioPlayer: NSObject {
    
    // MARK: - Properties
    
    /// Returns the singleton `FRadioPlayer` instance.
    public static let shared = FRadioPlayer()
    
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
    
    /// Check if the player is playing
    open var isPlaying: Bool {
        switch playbackState {
        case .playing:
            return true
        case .stopped, .paused:
            return false
        }
    }
    
    /// Player current state of type `FRadioPlayerState`
    open private(set) var state = FRadioPlayerState.urlNotSet {
        didSet {
            guard oldValue != state else { return }
            delegate?.radioPlayer(self, playerStateDidChange: state)
        }
    }
    
    /// Playing state of type `FRadioPlaybackState`
    open private(set) var playbackState = FRadioPlaybackState.stopped {
        didSet {
            guard oldValue != playbackState else { return }
            delegate?.radioPlayer(self, playbackStateDidChange: playbackState)
        }
    }
    
    // MARK: - Private properties
    
    /// AVPlayer
    private var player: AVPlayer?
    
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
    
    /// Reachability for network interruption handling
    private let reachability = Reachability()!
    
    /// Current network connectivity
    private var isConnected = false
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        
        // Enable bluetooth playback
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(AVAudioSession.Category.playback, mode: AVAudioSession.Mode.default, options: [.defaultToSpeaker, .allowBluetooth, .allowAirPlay])
        
        // Notifications
        setupNotifications()
        
        // Check for headphones
        checkHeadphonesConnection(outputs: AVAudioSession.sharedInstance().currentRoute.outputs)
        
        // Reachability config
        try? reachability.startNotifier()
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged(note:)), name: .reachabilityChanged, object: reachability)
        isConnected = reachability.connection != .none
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
        playbackState = .playing
    }
    
    /**
     Trigger the pause function of the radio player
     
     */
    open func pause() {
        guard let player = player else { return }
        player.pause()
        playbackState = .paused
    }
    
    /**
     Trigger the stop function of the radio player
     
     */
    open func stop() {
        guard let player = player else { return }
        player.replaceCurrentItem(with: nil)
        timedMetadataDidChange(rawValue: nil)
        playbackState = .stopped
    }
    
    /**
     Toggle isPlaying state
     
     */
    open func togglePlaying() {
        isPlaying ? pause() : play()
    }
    
    // MARK: - Private helpers
    
    private func radioURLDidChange(with url: URL?) {
        resetPlayer()
        guard let url = url else { state = .urlNotSet; return }
        
        state = .loading
        
        preparePlayer(with: AVAsset(url: url)) { (success, asset) in
            guard success, let asset = asset else {
                self.resetPlayer()
                self.state = .error
                return
            }
            self.setupPlayer(with: asset)
        }
    }
    
    private func setupPlayer(with asset: AVAsset) {
        if player == nil {
            player = AVPlayer()
            //Removes black screen when connecting to appleTV
            player?.allowsExternalPlayback = false
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

    private func reloadItem() {
        player?.replaceCurrentItem(with: nil)
        player?.replaceCurrentItem(with: playerItem)
    }
    
    private func resetPlayer() {
        stop()
        playerItem = nil
        lastPlayerItem = nil
        player = nil
    }
    
    deinit {
        resetPlayer()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Notifications
    
    private func setupNotifications() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(handleInterruption), name: AVAudioSession.interruptionNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(handleRouteChange), name: AVAudioSession.routeChangeNotification, object: nil)
    }
    
    // MARK: - Responding to Interruptions
    
    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                return
        }
        
        switch type {
        case .began:
            DispatchQueue.main.async { self.pause() }
        case .ended:
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { break }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            DispatchQueue.main.async { options.contains(.shouldResume) ? self.play() : self.pause() }
        @unknown default:
            break
        }
    }
    
    @objc func reachabilityChanged(note: Notification) {
        
        guard let reachability = note.object as? Reachability else { return }
        
        // Check if the internet connection was lost
        if reachability.connection != .none, !isConnected {
            checkNetworkInterruption()
        }
        
        isConnected = reachability.connection != .none
    }
    
    // Check if the playback could keep up after a network interruption
    private func checkNetworkInterruption() {
        guard
            let item = playerItem,
            !item.isPlaybackLikelyToKeepUp,
            reachability.connection != .none else { return }
        
        player?.pause()
        
        // Wait 1 sec to recheck and make sure the reload is needed
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
            if !item.isPlaybackLikelyToKeepUp { self.reloadItem() }
            self.isPlaying ? self.player?.play() : self.player?.pause()
        }
    }
    
    // MARK: - Responding to Route Changes
    
    private func checkHeadphonesConnection(outputs: [AVAudioSessionPortDescription]) {
        for output in outputs where output.portType == .headphones {
            headphonesConnected = true
            break
        }
        headphonesConnected = false
    }
    
    @objc private func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
            let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
            let reason = AVAudioSession.RouteChangeReason(rawValue:reasonValue) else { return }
        
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
                
                if player?.status == AVPlayer.Status.readyToPlay {
                    self.state = .readyToPlay
                } else if player?.status == AVPlayer.Status.failed {
                    self.state = .error
                }
                
            case "playbackBufferEmpty":
                
                if item.isPlaybackBufferEmpty {
                    self.state = .loading
                    self.checkNetworkInterruption()
                }
                
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
