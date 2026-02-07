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
    
    @MainActor
    func fetch() async throws {
        let stations = try await NetworkService.fetchStations()
        guard self.stations != stations else { return }
        self.stations = stations
        if let currentStation, !stations.contains(currentStation) { reset() }
    }

    func fetch(_ completion: ((Result<[RadioStation], Error>) -> Void)? = nil) {
        Task { @MainActor in
            do {
                try await fetch()
                completion?(.success(stations))
            } catch {
                completion?(.failure(error))
            }
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
            updateLockScreen(with: nil)
            return
        }
        
        station.getImage { [weak self] image in
            self?.updateLockScreen(with: image)
        }
    }
    
    private func updateLockScreen(with artworkImage: UIImage?) {
        
        // Define Now Playing Info
        var nowPlayingInfo = [String : Any]()
        
        if let image = artworkImage {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size, requestHandler: { size -> UIImage in
                return image
            })
        }
        
        if let artistName = currentStation?.artistName {
            nowPlayingInfo[MPMediaItemPropertyArtist] = artistName
        }
        
        if let trackName = currentStation?.trackName {
            nowPlayingInfo[MPMediaItemPropertyTitle] = trackName
        }
        
        let isLive = player.duration == 0

        if isLive {
            nowPlayingInfo[MPNowPlayingInfoPropertyIsLiveStream] = true
        } else {
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentTime
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = player.duration
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player.rate
        }

        // Set the metadata
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        AudioSetupService.shared.updateLiveCommands(isLive: isLive)
    }
}

// MARK: - FRadioPlayerObserver

extension StationsManager: FRadioPlayerObserver {
    
    func radioPlayer(_ player: FRadioPlayer, metadataDidChange metadata: FRadioPlayer.Metadata?) {
        resetArtwork(with: currentStation)
    }
    
    func radioPlayer(_ player: FRadioPlayer, artworkDidChange artworkURL: URL?) {
        guard let artworkURL else {
            resetArtwork(with: currentStation)
            return
        }

        Task { [weak self] in
            guard let image = await NetworkService.fetchImage(from: artworkURL) else {
                await MainActor.run { self?.resetArtwork(with: self?.currentStation) }
                return
            }
            await MainActor.run { self?.updateLockScreen(with: image) }
        }
    }
}
