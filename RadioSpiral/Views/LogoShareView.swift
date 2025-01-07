//
//  LogoShareView.swift
//  SwiftRadio
//
//  Created by Cameron Mcleod on 2019-07-12.
//  Copyright © 2019 matthewfecher.com. All rights reserved.
//

import UIKit

class LogoShareView: UIView {
    
    @IBOutlet weak var albumArtImageView: UIImageView!
    @IBOutlet weak var radioShoutoutLabel: UILabel!
    @IBOutlet weak var trackTitleLabel: UILabel!
    @IBOutlet weak var trackArtistLabel: UILabel!
    @IBOutlet weak var logoImageView: UIImageView!
    
    class func instanceFromNib() -> LogoShareView {
        return UINib(nibName: "LogoShareView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! LogoShareView
    }
    
    func shareSetup(albumArt : UIImage, radioShoutout: String, trackTitle: String, trackArtist: String) {
        let client = ACWebSocketClient.shared
        Task {
            self.albumArtImageView.kf.setImage(with: client.status.artwork)
        }
        self.radioShoutoutLabel.text = radioShoutout
        self.trackTitleLabel.text = client.status.track
        self.trackArtistLabel.text = client.status.artist
        self.logoImageView.image = UIImage(named: "logo")
    }
}
