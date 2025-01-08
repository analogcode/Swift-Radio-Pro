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
        }
    }
    
    var searchedStations: [RadioStation] = []
    
    private var observations = [ObjectIdentifier : Observation]()
    private let player = FRadioPlayer.shared
    
    private init() {
        self.player.addObserver(self)
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
            print("no station")
            updateLockScreen(with: nil)
            return
        }
        
        station.getImage { [weak self] image in
            print("station set")
            self?.updateLockScreen(with: image)
        }
    }
    
    private func updateLockScreen(with artworkImage: UIImage?) {
        
        // Define Now Playing Info
        var nowPlayingInfo = [String : Any]()
        
        if let url = ACWebSocketClient.shared.status.artwork {
            print("artwork is available")
            let v = UIImageView()
            Task {
                var image: UIImage?
                print("loading cover")
                await v.kf.setImage(with: url)
                await image = v.image
                print("cover loaded")
                return image
            }
        } else if let image = artworkImage {
            print("using station artwork")
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size, requestHandler: { size -> UIImage in
                return image
            })
        }
        
        if ACWebSocketClient.shared.status.artist != "" {
            print("should be setting artist")
            nowPlayingInfo[MPMediaItemPropertyArtist] = ACWebSocketClient.shared.status.artist
        }
        
        if ACWebSocketClient.shared.status.track != "" {
            print("should eb setting track")
            nowPlayingInfo[MPMediaItemPropertyArtist] = ACWebSocketClient.shared.status.track
        }
        print(nowPlayingInfo)
        
        // Set the metadata
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    func updateLockscreenStatus(status: ACStreamStatus) {
        var nowPlayingInfo = [String : Any]()
        nowPlayingInfo[MPMediaItemPropertyArtist] = status.artist
        nowPlayingInfo[MPMediaItemPropertyTitle] = status.track
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = status.album
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = status.duration
        nowPlayingInfo[MPMediaItemPropertyArtwork] = UIImage(named: "AppIcon")
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
}

// MARK: - FRadioPlayerObserver

extension StationsManager: FRadioPlayerObserver {
    
    func radioPlayer(_ player: FRadioPlayer, metadataDidChange metadata: FRadioPlayer.Metadata?) {
        let status = ACWebSocketClient.shared.status
        if !status.artist.isEmpty {
            self.updateLockscreenStatus(status: status)
        }
    }
    
    func radioPlayer(_ player: FRadioPlayer, artworkDidChange artworkURL: URL?) {
        self.updateLockscreenStatus(status: ACWebSocketClient.shared.status)
    }
}
