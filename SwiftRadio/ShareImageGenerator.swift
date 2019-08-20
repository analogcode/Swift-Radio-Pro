//
//  ShareImageCreator.swift
//  SwiftRadio
//
//  Created by Fethi El Hassasna on 2019-08-20.
//  Copyright © 2019 matthewfecher.com. All rights reserved.
//

import UIKit

class ShareImageGenerator {
    
    private let radioShoutout: String
    private let track: Track
    
    init(radioShoutout: String, track: Track) {
        self.radioShoutout = radioShoutout
        self.track = track
    }
    
    func generate() -> UIImage {
        let logoShareView = LogoShareView.instanceFromNib()
        let songToShare = radioShoutout
        
        logoShareView.shareSetup(albumArt: track.artworkImage ?? #imageLiteral(resourceName: "albumArt"), radioShoutout: songToShare, trackTitle: track.title, trackArtist: track.artist)
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: logoShareView.frame.width, height: logoShareView.frame.height), true, 0)
        logoShareView.drawHierarchy(in: logoShareView.frame, afterScreenUpdates: true)
        let shareImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return shareImage ?? track.artworkImage ?? #imageLiteral(resourceName: "albumArt")
    }
}
