//
//  StationTableViewCell.swift
//  SwiftRadio
//
//  Created by Fethi El Hassasna on 2023-06-24.
//  Copyright © 2023 matthewfecher.com. All rights reserved.
//

import UIKit
import NVActivityIndicatorView

class StationTableViewCell: UITableViewCell {
    
    let stationImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        // Let stack view manage size
        imageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        imageView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        imageView.setContentCompressionResistancePriority(.required, for: .vertical)
        return imageView
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .title3)
        label.numberOfLines = 0 // Allow multi-line titles if needed
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .footnote)
        label.numberOfLines = 0 // Allow multi-line descriptions
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text  = nil
        subtitleLabel.text  = nil
        stationImageView.image = nil
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        
        selectionStyle = .default
        
        let vStackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        vStackView.spacing = 8
        vStackView.axis = .vertical
        vStackView.translatesAutoresizingMaskIntoConstraints = false
        
        let hStackView = UIStackView(arrangedSubviews: [stationImageView, vStackView])
        hStackView.spacing = 12 // Add padding between image and labels
        hStackView.axis = .horizontal
        hStackView.alignment = .center
        hStackView.isLayoutMarginsRelativeArrangement = true
        hStackView.layoutMargins = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        hStackView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(hStackView)
        
        NSLayoutConstraint.activate([
            hStackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            hStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            hStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            hStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
        ])
        // Optionally, constrain image view to a max size
        stationImageView.heightAnchor.constraint(lessThanOrEqualToConstant: 75).isActive = true
        stationImageView.widthAnchor.constraint(lessThanOrEqualToConstant: 110).isActive = true
    }
}

extension StationTableViewCell {
    func configureStationCell(station: RadioStation) {
        
        // Configure the cell...
        titleLabel.text = station.name
        subtitleLabel.text = station.desc
        
        station.getImage { [weak self] image in
            self?.stationImageView.image = image
        }
    }
}
