//
//  UIImageView+AlbumArtDownload.swift
//  Swift Radio
//
//  Created by Matthew Fecher on 3/31/15.
//  Copyright (c) 2015 MatthewFecher.com. All rights reserved.
//

import UIKit

extension UIImageView {
    
    func loadImageWithURL(_ url: URL, callback:@escaping (UIImage) -> ()) -> URLSessionDownloadTask {
        let session = URLSession.shared
        
        let downloadTask = session.downloadTask(with: url, completionHandler: {
            [weak self] url, response, error in
            
            if error == nil && url != nil {
                if let data = try? Data(contentsOf: url!) {
                    if let image = UIImage(data: data) {
                        
                        DispatchQueue.main.async {
                            
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


