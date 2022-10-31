//
//  RadioPlayer.swift
//  SwiftRadio
//
//  Created by Fethi El Hassasna on 2018-01-05.
//  Copyright © 2018 matthewfecher.com. All rights reserved.
//

import UIKit
import Spring
import FRadioPlayer

//*****************************************************************
// RadioPlayerDelegate: Sends FRadioPlayer and Station/Track events
//*****************************************************************

protocol RadioPlayerDelegate: AnyObject {
    func playerStateDidChange(_ playerState: FRadioPlayer.State)
    func playbackStateDidChange(_ playbackState: FRadioPlayer.PlaybackState)
    func trackDidUpdate(_ track: Track?)
    func trackArtworkDidUpdate(_ track: Track?)
}

//*****************************************************************
// RadioPlayer: App Radio Player
//*****************************************************************

class RadioPlayer {
    
    weak var delegate: RadioPlayerDelegate?
    
    let player = FRadioPlayer.shared
    
    var station: RadioStation? {
        didSet { resetTrack(with: station) }
    }
    
    private(set) var track: Track?
    
    init() {
        player.addObserver(self)
    }
    
    func resetRadioPlayer() {
        station = nil
        track = nil
        player.radioURL = nil
    }
    
    //*****************************************************************
    // MARK: - Track loading/updates
    //*****************************************************************
    
    // Update the track with an artist name and track name
    func updateTrackMetadata(artistName: String, trackName: String) {
        if track == nil {
            track = Track(title: trackName, artist: artistName)
        } else {
            track?.title = trackName
            track?.artist = artistName
        }
        
        delegate?.trackDidUpdate(track)
    }
    
    // Update the track artwork with a UIImage
    func updateTrackArtwork(with image: UIImage, artworkLoaded: Bool) {
        track?.artworkImage = image
        track?.artworkLoaded = artworkLoaded
        delegate?.trackArtworkDidUpdate(track)
    }
    
    // Reset the track metadata and artwork to use the current station infos
    func resetTrack(with station: RadioStation?) {
        guard let station = station else { track = nil; return }
        updateTrackMetadata(artistName: station.desc, trackName: station.name)
        resetArtwork(with: station)
    }
    
    // Reset the track Artwork to current station image
    func resetArtwork(with station: RadioStation?) {
        guard let station = station else { track = nil; return }
        getStationImage(from: station) { image in
            self.updateTrackArtwork(with: image, artworkLoaded: false)
        }
    }
    
    //*****************************************************************
    // MARK: - Private helpers
    //*****************************************************************
    
    private func getStationImage(from station: RadioStation, completionHandler: @escaping (_ image: UIImage) -> ()) {
        
        if station.imageURL.range(of: "http") != nil {
            // load current station image from network
            ImageLoader.sharedLoader.imageForUrl(urlString: station.imageURL) { (image, stringURL) in
                completionHandler(image ?? #imageLiteral(resourceName: "albumArt"))
            }
        } else {
            // load local station image
            let image = UIImage(named: station.imageURL) ?? #imageLiteral(resourceName: "albumArt")
            completionHandler(image)
        }
    }
}

extension RadioPlayer: FRadioPlayerObserver {
    
    func radioPlayer(_ player: FRadioPlayer, playerStateDidChange state: FRadioPlayer.State) {
        delegate?.playerStateDidChange(state)
    }
    
    func radioPlayer(_ player: FRadioPlayer, playbackStateDidChange state: FRadioPlayer.PlaybackState) {
        delegate?.playbackStateDidChange(state)
    }
    
    func radioPlayer(_ player: FRadioPlayer, itemDidChange url: URL?) {
        // Not implemented
    }
    
    func radioPlayer(_ player: FRadioPlayer, metadataDidChange metadata: FRadioPlayer.Metadata?) {
        
        guard
            let artistName = metadata?.artistName, !artistName.isEmpty,
            let trackName = metadata?.trackName, !trackName.isEmpty else {
                resetTrack(with: station)
                return
        }
        
        updateTrackMetadata(artistName: artistName, trackName: trackName)
    }
    
    func radioPlayer(_ player: FRadioPlayer, artworkDidChange artworkURL: URL?) {
        guard let artworkURL = artworkURL else { resetArtwork(with: station); return }
        
        ImageLoader.sharedLoader.imageForUrl(urlString: artworkURL.absoluteString) { (image, stringURL) in
            guard let image = image else { self.resetArtwork(with: self.station); return }
            self.updateTrackArtwork(with: image, artworkLoaded: true)
        }
    }
}
