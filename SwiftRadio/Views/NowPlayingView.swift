//
//  NowPlayingView.swift
//  SwiftRadio
//
//  Created by Fethi El Hassasna on 2023-06-25.
//  Copyright © 2023 matthewfecher.com. All rights reserved.
//

import UIKit
import NVActivityIndicatorView

class NowPlayingView: UIView {
    
    var tapHandler: (() -> Void)?
    
    private static let resetTitle = "Choose a station above to begin..."
    
    private let animationView: NVActivityIndicatorView = {
        let activityIndicatorView = NVActivityIndicatorView(frame: .zero, type: .audioEqualizer, color: .white, padding: nil)
        NSLayoutConstraint.activate([
            activityIndicatorView.widthAnchor.constraint(equalToConstant: 30),
            activityIndicatorView.heightAnchor.constraint(equalToConstant: 20)
        ])
        return activityIndicatorView
    }()
    
    private let nowPlayingButton: UIButton = {
        let button = UIButton()
        button.isEnabled = false
        button.contentHorizontalAlignment = .left
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = NowPlayingView.resetTitle
        label.font = .preferredFont(forTextStyle: .callout)
        label.textColor = .lightText
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption2)
        label.textColor = .lightText
        return label
    }()
    
    init() {
        super.init(frame: .zero)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        backgroundColor = .black.withAlphaComponent(0.1)
        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: 50)
        ])
        
        nowPlayingButton.addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        
        let dividerView = UIView()
        dividerView.backgroundColor = UIColor.darkGray.withAlphaComponent(0.8)
        dividerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(dividerView)
        
        NSLayoutConstraint.activate([
            dividerView.topAnchor.constraint(equalTo: topAnchor),
            dividerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            dividerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            dividerView.heightAnchor.constraint(equalToConstant: 0.5)
        ])
        
        let titleStackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        titleStackView.translatesAutoresizingMaskIntoConstraints = false
        titleStackView.axis = .vertical
        titleStackView.spacing = 4
        
        let stackView = UIStackView(arrangedSubviews: [titleStackView, animationView])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.alignment = .center
        
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: dividerView.bottomAnchor, constant: 8),
            stackView.rightAnchor.constraint(equalTo: layoutMarginsGuide.rightAnchor, constant: -8),
            stackView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor, constant: 8),
            stackView.leftAnchor.constraint(equalTo: layoutMarginsGuide.leftAnchor, constant: 8)
        ])
        
        addSubview(nowPlayingButton)
        
        NSLayoutConstraint.activate([
            nowPlayingButton.topAnchor.constraint(equalTo: topAnchor),
            nowPlayingButton.rightAnchor.constraint(equalTo: rightAnchor),
            nowPlayingButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            nowPlayingButton.leftAnchor.constraint(equalTo: leftAnchor)
        ])
        
        bringSubviewToFront(nowPlayingButton)
    }
    
    func startAnimating() {
        animationView.startAnimating()
    }
    
    func stopAnimating() {
        animationView.stopAnimating()
    }
    
    func reset() {
        animationView.stopAnimating()
        titleLabel.text = NowPlayingView.resetTitle
        subtitleLabel.text = nil
        nowPlayingButton.isEnabled = false
    }
    
    func update(with title: String?, subtitle: String) {
        nowPlayingButton.isEnabled = true
        
        if let title {
            titleLabel.text = title
            subtitleLabel.text = subtitle
        } else {
            titleLabel.text = subtitle
            subtitleLabel.text = "Now playing ..."
        }
    }
    
    @objc private func handleTap() {
        tapHandler?()
    }
}
