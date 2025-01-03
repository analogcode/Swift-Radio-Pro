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

struct RadioStation: Codable {
    
    var name: String
    var streamURL: String
    var imageURL: String
    var desc: String
    var longDesc: String
    
    init(name: String, streamURL: String, imageURL: String, desc: String, longDesc: String = "") {
        self.name = name
        self.streamURL = streamURL
        self.imageURL = imageURL
        self.desc = desc
        self.longDesc = longDesc
    }
}

extension RadioStation {
    var client: ACWebSocketClient { ACWebSocketClient.shared }

    var shoutout: String {
        if client.status.album.isEmpty {
            "I'm listening to \"\(client.status.track)\" by \(client.status.artist) on \(Bundle.main.appName)"
        } else {
            "I'm listening to \"\(client.status.track)\" by \(client.status.artist) from \"\(client.status.album)\" on \(Bundle.main.appName)"
        }
    }
}

extension RadioStation: Equatable {
    
    static func == (lhs: RadioStation, rhs: RadioStation) -> Bool {
        return (lhs.name == rhs.name) && (lhs.streamURL == rhs.streamURL) && (lhs.imageURL == rhs.imageURL) && (lhs.desc == rhs.desc) && (lhs.longDesc == rhs.longDesc)
    }
}

extension RadioStation {
    func getImage(completion: @escaping (_ image: UIImage) -> Void) {
        
        if imageURL.range(of: "http") != nil, let url = URL(string: imageURL) {
            // load current station image from network
            UIImage.image(from: url) { image in
                completion(image ?? #imageLiteral(resourceName: "stationImage"))
            }
        } else {
            // load local station image
            let image = UIImage(named: imageURL) ?? #imageLiteral(resourceName: "stationImage")
            completion(image)
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
