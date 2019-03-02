//
//  AppDelegate+CarPlay.swift
//  SwiftRadio
//
//  Created by Fethi El Hassasna on 2019-02-02.
//  Copyright © 2019 matthewfecher.com. All rights reserved.
//

import Foundation
import MediaPlayer

extension AppDelegate {
    
    func setupCarPlay() {
        playableContentManager = MPPlayableContentManager.shared()
        
        playableContentManager?.delegate = self
        playableContentManager?.dataSource = self
        
        stationsViewController?.setupRemoteCommandCenter()
        stationsViewController?.updateLockScreen(with: nil)
    }
}

extension AppDelegate: MPPlayableContentDelegate {
    
    func playableContentManager(_ contentManager: MPPlayableContentManager, initiatePlaybackOfContentItemAt indexPath: IndexPath, completionHandler: @escaping (Error?) -> Void) {
        
        DispatchQueue.main.async {            
            if indexPath.count == 2 {
                let station = self.carplayPlaylist.stations[indexPath[1]]
                self.stationsViewController?.selectFromCarPlay(station)
            }
            completionHandler(nil)
            
            #if targetEnvironment(simulator)
                // Workaround to make the Now Playing working on the simulator:
                // Source: https://stackoverflow.com/questions/52818170/handling-playback-events-in-carplay-with-mpnowplayinginfocenter
                UIApplication.shared.endReceivingRemoteControlEvents()
                UIApplication.shared.beginReceivingRemoteControlEvents()
            #endif
        }
    }
    
    func beginLoadingChildItems(at indexPath: IndexPath, completionHandler: @escaping (Error?) -> Void) {
        carplayPlaylist.load { error in
            completionHandler(error)
        }
    }
}

extension AppDelegate: MPPlayableContentDataSource {
    
    func numberOfChildItems(at indexPath: IndexPath) -> Int {
        if indexPath.indices.count == 0 {
            return 1
        }
        
        return carplayPlaylist.stations.count
    }
    
    func contentItem(at indexPath: IndexPath) -> MPContentItem? {
        
        if indexPath.count == 1 {
            // Tab section
            let item = MPContentItem(identifier: "Stations")
            item.title = "Stations"
            item.isContainer = true
            item.isPlayable = false
            item.artwork = MPMediaItemArtwork(boundsSize: #imageLiteral(resourceName: "carPlayTab").size, requestHandler: { _ -> UIImage in
                return #imageLiteral(resourceName: "carPlayTab")
            })
            return item
        } else if indexPath.count == 2, indexPath.item < carplayPlaylist.stations.count {
            
            // Stations section
            let station = carplayPlaylist.stations[indexPath.item]
            
            let item = MPContentItem(identifier: "\(station.name)")
            item.title = station.name
            item.subtitle = station.desc
            item.isPlayable = true
            item.isStreamingContent = true
            
            if station.imageURL.contains("http") {
                ImageLoader.sharedLoader.imageForUrl(urlString: station.imageURL) { image, _ in
                    DispatchQueue.main.async {
                        guard let image = image else { return }
                        item.artwork = MPMediaItemArtwork(boundsSize: image.size, requestHandler: { _ -> UIImage in
                            return image
                        })
                    }
                }
            } else {
                if let image = UIImage(named: station.imageURL) ?? UIImage(named: "stationImage") {
                    item.artwork = MPMediaItemArtwork(boundsSize: image.size, requestHandler: { _ -> UIImage in
                        return image
                    })
                }
            }
            
            return item
        } else {
            return nil
        }
    }
}
