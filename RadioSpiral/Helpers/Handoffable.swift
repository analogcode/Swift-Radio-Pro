//
//  Handoffable.swift
//  SwiftRadio
//
//  Created by Fethi El Hassasna on 2022-11-24.
//  Copyright © 2022 matthewfecher.com. All rights reserved.
//

import UIKit
import FRadioPlayer

protocol Handoffable: UIResponder {}

extension Handoffable {
    
    func setupHandoffUserActivity() {
        userActivity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        userActivity?.becomeCurrent()
    }
    
    func updateHandoffUserActivity(_ activity: NSUserActivity?, station: RadioStation?) {
        guard let activity = activity else { return }
        
        defer { updateUserActivityState(activity) }
        
        let metadataManager = StationMetadataManager.shared
        var track: String
        var artist: String
        
        if let metadata = metadataManager.getCurrentMetadata(), !metadata.trackName.isEmpty && !metadata.artistName.isEmpty {
            track = metadata.trackName
            artist = metadata.artistName
        } else {
            guard let metadata = FRadioPlayer.shared.currentMetadata, let artistName = metadata.artistName, let trackName = metadata.trackName else {
                activity.webpageURL = nil
                return
            }
            track = trackName
            artist = artistName
        }
        
        activity.webpageURL = getHandoffURL(artistName: artist, trackName: track)
    }
    
    private func getHandoffURL(artistName: String, trackName: String) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "google.com"
        components.path = "/search"
        components.queryItems = [URLQueryItem]()
        components.queryItems?.append(URLQueryItem(name: "q", value: "\(artistName) \(trackName)"))
        return components.url
    }
}
