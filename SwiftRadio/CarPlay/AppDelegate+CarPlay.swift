//  AppDelegate+CarPlay.swift
//  SwiftRadio
//
//  Created by Fethi El Hassasna on 2019-02-02.
//  Modified by ChatGPT on 2023-03-10.
//  Copyright © 2019 matthewfecher.com. All rights reserved.
//

import Foundation
import MediaPlayer

// MARK: - CarPlay Setup

extension AppDelegate {
    
    private lazy var playableContentManager: MPPlayableContentManager = {
        let manager = MPPlayableContentManager.shared()
        manager.delegate = self
        manager.dataSource = self
        StationsManager.shared.addObserver(self)
        return manager
    }()
    
    private var contentCache: [IndexPath: MPContentItem] = [:]
}

// MARK: - MPPlayableContentDelegate

extension AppDelegate: MPPlayableContentDelegate {
    
    func playableContentManager(_ contentManager: MPPlayableContentManager, initiatePlaybackOfContentItemAt indexPath: IndexPath, completionHandler: @escaping (Error?) -> Void) {
        
        DispatchQueue.main.async {
            if indexPath.count == 2 {
                let station = StationsManager.shared.stations[indexPath[1]]
                StationsManager.shared.set(station: station)
                MPPlayableContentManager.shared().nowPlayingIdentifiers = [station.name]
            }
            completionHandler(nil)
        }
    }
    
    func beginLoadingChildItems(at indexPath: IndexPath, completionHandler: @escaping (Error?) -> Void) {
        if let cachedItem = contentCache[indexPath] {
            // Return cached item if it exists
            if let stationItem = cachedItem as? StationItem, let station = stationItem.station {
                // If the cached item is a StationItem, make sure the station image is up to date
                station.getImage { [weak self] image in
                    guard let self = self else { return }
                    stationItem.artwork = MPMediaItemArtwork(boundsSize: image.size) { _ -> UIImage in
                        return image
                    }
                    self.contentCache[indexPath] = stationItem
                    completionHandler(nil)
                }
            } else {
                completionHandler(nil)
            }
        } else {
            StationsManager.shared.fetch { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let stations):
                    let items = stations.map { station -> StationItem in
                        let item = StationItem(station: station)
                        self.contentCache[IndexPath(item: items.count, section: 1)] = item
                        return item
                    }
                    let container = ContainerItem(title: "Stations", children: items)
                    self.contentCache[indexPath] = container
                    completionHandler(nil)
                case .failure(let error):
                    completionHandler(error)
                }
            }
        }
    }
}

// MARK: - MPPlayableContentDataSource

extension AppDelegate: MPPlayableContentDataSource {
    
    func numberOfChildItems(at indexPath: IndexPath) -> Int {
        if indexPath.indices.count == 0 {
            return 1
        }
        
        return StationsManager.shared.stations.count
    }
    
    func contentItem(at indexPath: IndexPath) -> MPContentItem? {
        
        if let cachedItem = contentCache[indexPath] {
            return cachedItem
        }
        
        if indexPath.count == 1 {
            // Tab section
            let item = ContainerItem(title: "Stations", children: [])
            item.artwork = MPMediaItemArtwork(boundsSize: #imageLiteral(resourceName: "carPlayTab").size, requestHandler: { _ -> UIImage in
                return #imageLiteral(resourceName: "carPlayTab")
            })
            contentCache[indexPath] = item

            // Stations section
            let station = StationsManager.shared.stations[indexPath.item]

            let item = MPContentItem(identifier: "\(station.name)")
            item.title = station.name
            item.subtitle = station.desc
            item.isPlayable = true
            item.isStreamingContent = true
            station.getImage { image in
                item.artwork = MPMediaItemArtwork(boundsSize: image.size) { _ -> UIImage in
                    return image
                }
            }
            return item
        } else {
            return nil
        }
    }
}

// MARK: - StationsManagerObserver

extension AppDelegate: StationsManagerObserver {

    func stationsManager(_ manager: StationsManager, stationsDidUpdate stations: [RadioStation]) {
        playableContentManager.reloadData()
    }

    func stationsManager(_ manager: StationsManager, stationDidChange station: RadioStation?) {
        if let station = station {
            playableContentManager.nowPlayingIdentifiers = [station.name]
        } else {
            playableContentManager.nowPlayingIdentifiers = []
        }
    }
}
