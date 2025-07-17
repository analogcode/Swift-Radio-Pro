//
//  RadioStation.swift
//  Swift Radio
//
//  Created by Matthew Fecher on 7/4/15.
//  Copyright (c) 2015 MatthewFecher.com. All rights reserved.
//

import UIKit
import FRadioPlayer

// Radio Station

public struct RadioStation: Codable {
    
    var name: String
    var streamURL: String
    var imageURL: String
    var desc: String
    var longDesc: String
    var serverName: String
    var shortCode: String
    var defaultDJ: String
    var metadataClient: ACWebSocketClient?
    var defaultArtwork: UIImage?
    
    enum CodingKeys: String, CodingKey {
        case name, streamURL, imageURL, desc, longDesc, serverName, shortCode, defaultDJ
    }
    
    
    init(name: String, streamURL: String, imageURL: String, desc: String, longDesc: String = "", serverName: String, shortCode: String, defaultDJ: String) {
        self.name = name
        self.streamURL = streamURL
        self.imageURL = imageURL
        self.desc = desc
        self.longDesc = longDesc
        self.serverName = serverName
        self.shortCode = shortCode
        self.defaultDJ = defaultDJ
    }
}

extension RadioStation {
    var client: ACWebSocketClient { ACWebSocketClient.shared }
    
    var metadataManager: StationMetadataManager { StationMetadataManager.shared }

    var shoutout: String {
        if let metadata = metadataManager.getCurrentMetadata() {
            if let albumName = metadata.albumName, !albumName.isEmpty {
                return "I'm listening to \"\(metadata.trackName)\" by \(metadata.artistName) from \"\(albumName)\" on \(Bundle.main.appName)"
            } else {
                return "I'm listening to \"\(metadata.trackName)\" by \(metadata.artistName) on \(Bundle.main.appName)"
            }
        } else {
            // Fallback to client status
            if client.status.album.isEmpty {
                return "I'm listening to \"\(client.status.track)\" by \(client.status.artist) on \(Bundle.main.appName)"
            } else {
                return "I'm listening to \"\(client.status.track)\" by \(client.status.artist) from \"\(client.status.album)\" on \(Bundle.main.appName)"
            }
        }
    }
}

extension RadioStation: Equatable {
    
    public static func == (lhs: RadioStation, rhs: RadioStation) -> Bool {
        return (lhs.name == rhs.name) && (lhs.streamURL == rhs.streamURL) && (lhs.imageURL == rhs.imageURL) && (lhs.desc == rhs.desc) && (lhs.longDesc == rhs.longDesc)
    }
}

var imageCache: [String: UIImage] = [:]

extension RadioStation {
    func getImage(completion: @escaping (_ image: UIImage) -> Void) {
        if let cachedImage = imageCache[imageURL] {
            completion(cachedImage)
            return
        }

        if imageURL.range(of: "http") != nil, let url = URL(string: imageURL) {
            UIImage.image(from: url) { image in
                let finalImage = image ?? #imageLiteral(resourceName: "albumArt")   // TODO: pick a better default image?
                imageCache[imageURL] = finalImage
                completion(finalImage)
            }
        } else {
            let finalImage = UIImage(named: imageURL) ?? #imageLiteral(resourceName: "stationImage")
            imageCache[imageURL] = finalImage
            completion(finalImage)
        }
    }
}

extension RadioStation {
    
    var trackName: String {
        FRadioPlayer.shared.currentMetadata?.trackName ?? name
    }
    
    var artistName: String {
        FRadioPlayer.shared.currentMetadata?.artistName ?? desc
    }
    
    var releaseName: String {
        let raw = FRadioPlayer.shared.currentMetadata?.rawValue
        let parts = raw?.components(separatedBy: " - ")
        if parts?.count == 3 {
            return (parts?[1])!
        }
        return ""
    }
}
