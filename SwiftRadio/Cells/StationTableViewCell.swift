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
        NSLayoutConstraint.activate([
            imageView.heightAnchor.constraint(equalToConstant: 75),
            imageView.widthAnchor.constraint(equalToConstant: 110)
        ])
        return imageView
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .title3)
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .footnote)
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
        hStackView.spacing = 8
        hStackView.axis = .horizontal
        hStackView.alignment = .center
        hStackView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(hStackView)
        
        NSLayoutConstraint.activate([
            hStackView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            hStackView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            hStackView.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
            hStackView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor)
        ])
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
