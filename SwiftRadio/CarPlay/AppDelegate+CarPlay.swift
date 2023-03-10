extension AppDelegate {
    
    func setupCarPlay() {
        playableContentManager = MPPlayableContentManager.shared()
        playableContentManager?.delegate = self
        playableContentManager?.dataSource = self
        
        StationsManager.shared.addObserver(self)
    }
}

extension AppDelegate: MPPlayableContentDelegate {
    
    func playableContentManager(_ contentManager: MPPlayableContentManager, initiatePlaybackOfContentItemAt indexPath: IndexPath, completionHandler: @escaping (Error?) -> Void) {
        
        DispatchQueue.main.async {
            guard indexPath.count == 2 else {
                completionHandler(nil)
                return
            }
            
            let station = StationsManager.shared.stations[indexPath[1]]
            StationsManager.shared.set(station: station)
            MPPlayableContentManager.shared().nowPlayingIdentifiers = [station.name]
            completionHandler(nil)
        }
    }
    
    func beginLoadingChildItems(at indexPath: IndexPath, completionHandler: @escaping (Error?) -> Void) {
        StationsManager.shared.fetch { result in
            guard case .failure(let error) = result else {
                completionHandler(nil)
                return
            }
            
            completionHandler(error)
        }
    }
}

extension AppDelegate: MPPlayableContentDataSource {
    
    func numberOfChildItems(at indexPath: IndexPath) -> Int {
        guard indexPath.indices.count != 0 else {
            return 1
        }
        
        return StationsManager.shared.stations.count
    }
    
    func contentItem(at indexPath: IndexPath) -> MPContentItem? {
        
        guard indexPath.count == 2, indexPath.item < StationsManager.shared.stations.count else {
            if indexPath.count == 1 {
                let item = MPContentItem(identifier: "Stations")
                item.title = "Stations"
                item.isContainer = true
                item.isPlayable = false
                item.artwork = MPMediaItemArtwork(boundsSize: #imageLiteral(resourceName: "carPlayTab").size, requestHandler: { _ -> UIImage in
                    return #imageLiteral(resourceName: "carPlayTab")
                })
                return item
            }
            return nil
        }
        
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
    }
}

extension AppDelegate: StationsManagerObserver {
    
    func stationsManager(_ manager: StationsManager, stationsDidUpdate stations: [RadioStation]) {
        playableContentManager?.reloadData()
    }
    
    func stationsManager(_ manager: StationsManager, stationDidChange station: RadioStation?) {
        guard let station = station else {
            playableContentManager?.nowPlayingIdentifiers = []
            return
        }
        
        playableContentManager?.nowPlayingIdentifiers = [station.name]
    }
}
