//
//  ShareActivity.swift
//  SwiftRadio
//
//  Created by Fethi El Hassasna on 2019-08-20.
//  Copyright © 2019 matthewfecher.com. All rights reserved.
//

import UIKit

struct ShareActivity {
    
    static func activityController(station: RadioStation, artworkURL: URL?, sourceView: UIView, _ completion: @escaping (UIActivityViewController) -> Void) {
                
        getImage(station: station, artworkURL: artworkURL) { image in
            let shareImage = generateImage(from: image, station: station)
            
            let activityViewController = UIActivityViewController(activityItems: [station.shoutout, shareImage], applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceRect = CGRect(x: sourceView.center.x, y: sourceView.center.y, width: 0, height: 0)
            activityViewController.popoverPresentationController?.sourceView = sourceView
            activityViewController.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
            
            activityViewController.completionWithItemsHandler = {(activityType: UIActivity.ActivityType?, completed: Bool, returnedItems:[Any]?, error: Error?) in
                if completed {
                    // do something on completion if you want
                }
            }
            
            completion(activityViewController)
        }
    }
    
    private static func getImage(station: RadioStation, artworkURL: URL?, _ completion: @escaping (UIImage?) -> Void) {
        if let artworkURL = artworkURL {
            UIImage.image(from: artworkURL) { completion($0) }
        } else {
            station.getImage { completion($0) }
        }
    }
    
    private static func generateImage(from image: UIImage?, station: RadioStation) -> UIImage {
        let logoShareView = LogoShareView.instanceFromNib()
        
        logoShareView.shareSetup(albumArt: image ?? #imageLiteral(resourceName: "albumArt"), radioShoutout: station.shoutout, trackTitle: station.trackName, trackArtist: station.artistName)
                
        let renderer = UIGraphicsImageRenderer(size: logoShareView.bounds.size)
        let shareImage = renderer.image { ctx in
            logoShareView.drawHierarchy(in: logoShareView.bounds, afterScreenUpdates: true)
        }
        
        return shareImage
    }
}
