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
    func playableContentManager(_ contentManager: MPPlayableContentManager, didUpdate context: MPPlayableContentManagerContext) {
        print("did update context")
    }
    
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
        
        // Indicate user selection by index
        if indexPath.count > 0, indexPath[0] == 1 {
            carplayPlaylist.load(type: .list) { error in
                completionHandler(error)
            }
        }else{
            // load default stations
            carplayPlaylist.load(type: .station) { error in
                completionHandler(error)
            }
        }
    }
}

extension AppDelegate: MPPlayableContentDataSource {
    
    func numberOfChildItems(at indexPath: IndexPath) -> Int {
        // Returns multiple tab sections
        if indexPath.indices.count == 0 {
            return 2
        }
        
        // Returns actual number of stations
        return carplayPlaylist.stations.count
    }
    
    func contentItem(at indexPath: IndexPath) -> MPContentItem? {
        if indexPath == [1] {
            // Tab section 1
            let item = MPContentItem(identifier: "Favorites")
            item.title = "Favorites"
            item.isContainer = true
            item.isPlayable = false
            item.artwork = MPMediaItemArtwork(boundsSize: #imageLiteral(resourceName: "favorites").size, requestHandler: { _ -> UIImage in
                return #imageLiteral(resourceName: "favorites")
            })
            return item
        } else if indexPath == [0] {
            // Tab section 2
            let item = MPContentItem(identifier: "Sample Stations")
            item.title = "Sample Stations"
            item.isContainer = true
            item.isPlayable = false
            item.artwork = MPMediaItemArtwork(boundsSize: #imageLiteral(resourceName: "playlists").size, requestHandler: { _ -> UIImage in
                return #imageLiteral(resourceName: "playlists")
            })
            return item
        }else if indexPath.count > 1, indexPath.item < carplayPlaylist.stations.count {
            
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
