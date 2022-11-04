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
        
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // set ImageView shadow
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
        
        station.getImage { [weak self] image in
            self?.stationImageView.image = image
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        stationNameLabel.text  = nil
        stationDescLabel.text  = nil
        stationImageView.image = nil
    }
}
