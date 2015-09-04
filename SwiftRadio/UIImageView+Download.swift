//
//  UIImageView+AlbumArtDownload.swift
//  Swift Radio
//
//  Created by Matthew Fecher on 3/31/15.
//  Copyright (c) 2015 MatthewFecher.com. All rights reserved.
//

import UIKit

extension UIImageView {
    
    func loadImageWithURL(url: NSURL, callback:(UIImage) -> ()) -> NSURLSessionDownloadTask {
        let session = NSURLSession.sharedSession()
        
        let downloadTask = session.downloadTaskWithURL(url, completionHandler: {
            [weak self] url, response, error in
            
            if error == nil && url != nil {
                if let data = NSData(contentsOfURL: url!) {
                    if let image = UIImage(data: data) {
                        
                        dispatch_async(dispatch_get_main_queue()) {
                            
                            if let strongSelf = self {
                                strongSelf.image = image
                                callback(image)
                            }
                        }
                    }
                }
            }
        })
        
        downloadTask.resume()
        return downloadTask
    }
}


