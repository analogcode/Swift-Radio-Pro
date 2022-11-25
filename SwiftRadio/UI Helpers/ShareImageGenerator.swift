//
//  ShareImageCreator.swift
//  SwiftRadio
//
//  Created by Fethi El Hassasna on 2019-08-20.
//  Copyright © 2019 matthewfecher.com. All rights reserved.
//

import UIKit

class ShareImageGenerator {
    
    private let station: RadioStation
    
    init(station: RadioStation) {
        self.station = station
    }
    
    func generate(with artworkImage: UIImage?) -> UIImage {
        let logoShareView = LogoShareView.instanceFromNib()
        
        logoShareView.shareSetup(albumArt: artworkImage ?? #imageLiteral(resourceName: "albumArt"), radioShoutout: station.shoutout, trackTitle: station.trackName, trackArtist: station.artistName)
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: logoShareView.frame.width, height: logoShareView.frame.height), true, 0)
        logoShareView.drawHierarchy(in: logoShareView.frame, afterScreenUpdates: true)
        let shareImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return shareImage ?? artworkImage ?? #imageLiteral(resourceName: "albumArt")
    }
}
