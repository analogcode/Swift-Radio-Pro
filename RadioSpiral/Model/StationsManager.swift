//
//  StationsManager.swift
//  SwiftRadio
//
//  Created by Fethi El Hassasna on 2022-11-02.
//  Copyright © 2022 matthewfecher.com. All rights reserved.
//

import UIKit
import FRadioPlayer
import MediaPlayer
import Combine

protocol StationsManagerObserver: AnyObject {
    func stationsManager(_ manager: StationsManager, stationsDidUpdate stations: [RadioStation])
    func stationsManager(_ manager: StationsManager, stationDidChange station: RadioStation?)
}

extension StationsManagerObserver {
    func stationsManager(_ manager: StationsManager, stationsDidUpdate stations: [RadioStation]) {}
}

class StationsManager {
    
    static let shared = StationsManager()
    
    private(set) var stations: [RadioStation] = [] {
        didSet {
            notifiyObservers { observer in
                observer.stationsManager(self, stationsDidUpdate: stations)
            }
        }
    }
    
    private(set) var currentStation: RadioStation? {
        didSet {
            notifiyObservers { observer in
                observer.stationsManager(self, stationDidChange: currentStation)
            }
            
            resetArtwork(with: currentStation)
            
            // Connect to new station's metadata
            if let station = currentStation {
                metadataManager.connectToStation(station)
            } else {
                metadataManager.disconnectCurrentStation()
            }
        }
    }
        
    var searchedStations: [RadioStation] = []
    
    private var observations = [ObjectIdentifier : Observation]()
    private let player = FRadioPlayer.shared
    private let metadataManager = StationMetadataManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        self.player.addObserver(self)
        setupMetadataObserver()
    }
    
    func fetch(_ completion: StationsCompletion? = nil) {
        DataManager.getStation { [weak self] result in
            guard case .success(let stations) = result, self?.stations != stations else {
                completion?(result)
                return
            }
            
            self?.stations = stations
            
            // Reset everything if the new stations list doesn't have the current station
            if let currentStation = self?.currentStation, self?.stations.firstIndex(of: currentStation) == nil {
                self?.reset()
            }
            
            completion?(result)
        }
    }
    
    func set(station: RadioStation?) {
        guard let station = station else {
            reset()
            return
        }
        
        currentStation = station
        player.radioURL = URL(string: station.streamURL)
    }
    
    func setNext() {
        guard let index = getIndex(of: currentStation) else { return }
        let station = (index + 1 == stations.count) ? stations[0] : stations[index + 1]
        currentStation = station
        player.radioURL = URL(string: station.streamURL)
    }
    
    func setPrevious() {
        guard let index = getIndex(of: currentStation), let station = (index == 0) ? stations.last : stations[index - 1] else { return }
        currentStation = station
        player.radioURL = URL(string: station.streamURL)
    }
    
    // Exists because with Azuracast, resuming from stop/pause is not working
    // consistently, but "previous" or "next" DOES properly restart play.
    // Will add this into the play() function and see if it helps.
    func reloadCurrent() {
        guard let index = getIndex(of: currentStation) else { return }
        currentStation = stations[index]
        player.radioURL = URL(string: currentStation!.streamURL)
    }
    
    func updateSearch(with filter: String) {
        searchedStations.removeAll(keepingCapacity: false)
        searchedStations = stations.filter { $0.name.range(of: filter, options: [.caseInsensitive]) != nil }
    }
    
    private func reset() {
        currentStation = nil
        player.radioURL = nil
    }
    
    private func getIndex(of station: RadioStation?) -> Int? {
        guard let station = station, let index = stations.firstIndex(of: station) else { return nil }
        return index
    }
    
    private func setupMetadataObserver() {
        // Subscribe to metadata changes from the unified metadata manager
        metadataManager.subscribeToMetadataChanges { [weak self] metadata in
            DispatchQueue.main.async {
                self?.handleMetadataUpdate(metadata)
            }
        }
    }
    
    private func handleMetadataUpdate(_ metadata: UnifiedMetadata?) {
        updateLockScreen(with: metadata)
    }
}

// MARK: - StationsManager Observation

extension StationsManager {
    
    private struct Observation {
        weak var observer: StationsManagerObserver?
    }
    
    func addObserver(_ observer: StationsManagerObserver) {
        let id = ObjectIdentifier(observer)
        observations[id] = Observation(observer: observer)
    }
    
    func removeObserver(_ observer: StationsManagerObserver) {
        let id = ObjectIdentifier(observer)
        observations.removeValue(forKey: id)
    }
    
    private func notifiyObservers(with action: (_ observer: StationsManagerObserver) -> Void) {
        for (id, observation) in observations {
            guard let observer = observation.observer else {
                observations.removeValue(forKey: id)
                continue
            }
            
            action(observer)
        }
    }
}

// MARK: - MPNowPlayingInfoCenter (Lock screen)

extension StationsManager {
    
    private func resetArtwork(with station: RadioStation?) {
        
        guard let station = station else {
            updateLockScreen(with: nil)
            return
        }
        
        station.getImage { [weak self] image in
            self?.updateLockScreen(with: nil)
        }
    }
    
    private func updateLockScreen(with metadata: UnifiedMetadata?) {
        let nowPLayingInfoCenter = MPNowPlayingInfoCenter.default()
        var nowPlayingInfo = nowPLayingInfoCenter.nowPlayingInfo ?? [String : Any]()
        if let metadata = metadata {
            nowPlayingInfo[MPMediaItemPropertyArtist] = metadata.artistName
            nowPlayingInfo[MPMediaItemPropertyTitle] = metadata.trackName
            if let albumName = metadata.albumName {
                nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = albumName
            }
            if let duration = metadata.duration {
                nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
            }
            if let artworkURL = metadata.artworkURL {
                URLSession.shared.dataTask(with: artworkURL) { [weak self] data, response, error in
                    if let error = error {
                        print("[LockScreen] Error downloading artwork: \(error)")
                    }
                    if let data = data, let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size, requestHandler: { _ in
                                return image
                            })
                            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
                        }
                    } else {
                        print("[LockScreen] Failed to decode artwork, falling back to station icon")
                        if let station = self?.currentStation {
                            station.getImage { fallbackImage in
                                DispatchQueue.main.async {
                                    nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: fallbackImage.size, requestHandler: { _ in
                                        return fallbackImage
                                    })
                                    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
                                }
                            }
                        }
                    }
                }.resume()
                return // Only set nowPlayingInfo after artwork is ready
            }
        }
        // If no artworkURL, set nowPlayingInfo immediately
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    // Legacy method for backward compatibility
    func updateLockscreenStatus(status: ACStreamStatus) {
        let nowPLayingInfoCenter = MPNowPlayingInfoCenter.default()
        var nowPlayingInfo = nowPLayingInfoCenter.nowPlayingInfo ?? [String : Any]()
        nowPlayingInfo[MPMediaItemPropertyArtist] = status.artist
        nowPlayingInfo[MPMediaItemPropertyTitle] = status.track
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = status.album
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = status.duration
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
}

// MARK: - FRadioPlayerObserver

extension StationsManager: FRadioPlayerObserver {
    
    func radioPlayer(_ player: FRadioPlayer, metadataDidChange metadata: FRadioPlayer.Metadata?) {
        // Trigger metadata update in the unified metadata manager
        metadataManager.triggerMetadataUpdate()
    }
    
    func radioPlayer(_ player: FRadioPlayer, artworkDidChange artworkURL: URL?) {
        // Trigger metadata update in the unified metadata manager
        metadataManager.triggerMetadataUpdate()
    }
}
