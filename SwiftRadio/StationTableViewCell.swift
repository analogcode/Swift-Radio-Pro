//
//  StationTableViewCell.swift
//  Swift Radio
//
//  Created by Matthew Fecher on 4/4/15.
//  Copyright (c) 2015 MatthewFecher.com. All rights reserved.
//

import UIKit

class StationTableViewCell: UITableViewCell {

    @IBOutlet weak var stationNameLabel: UILabel!
    @IBOutlet weak var stationDescLabel: UILabel!
    @IBOutlet weak var stationImageView: UIImageView!
    
    var downloadTask: URLSessionDownloadTask?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // set stationImageView shadow
        stationImageView.applyShadow()
        
        // set table selection color
        let selectedView = UIView(frame: CGRect.zero)
        selectedView.backgroundColor = UIColor(red: 78/255, green: 82/255, blue: 93/255, alpha: 0.6)
        selectedBackgroundView  = selectedView
    }

    func configureStationCell(station: RadioStation) {
        
        // Configure the cell...
        stationNameLabel.text = station.name
        stationDescLabel.text = station.desc
        
        let imageURL = station.imageURL as NSString
        
            if imageURL.contains("http"), let url = URL(string: station.imageURL) {
                
                stationImageView.loadImageWithURL(url: url) { (image) in
                    // station image loaded
                }
            } else if imageURL != "" {
                stationImageView.image = UIImage(named: imageURL as String)
           
            } else {
                stationImageView.image = UIImage(named: "stationImage")
            }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        downloadTask?.cancel()
        downloadTask = nil
        stationNameLabel.text  = nil
        stationDescLabel.text  = nil
        stationImageView.image = nil
    }
}
