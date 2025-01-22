//
//  AlbumArtworkView.swift
//  SwiftRadio
//
//  Created by Fethi El Hassasna on 2024-01-13.
//  Copyright 2024 matthewfecher.com. All rights reserved.
//

import UIKit
import Spring

class AlbumArtworkView: UIView {
    
    // TODO: Add desc label
    
    // Corner radius
    private let cornerRadius: CGFloat = 4
    
    // Add background image view
    private let backgroundImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        return view
    }()
    
    // Add blur effect view
    private let blurEffectView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .prominent)
        let view = UIVisualEffectView(effect: blurEffect)
        return view
    }()
    
    private let imageView: SpringImageView = {
        let view = SpringImageView()
        // Keep aspectFit but adjust constraints
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        return view
    }()
    
    // Keep track of aspect ratio constraint
    private var aspectRatioConstraint: NSLayoutConstraint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setImage(_ image: UIImage?) {
        imageView.image = image
        backgroundImageView.image = image
        updateAspectRatio(for: image)
    }
    
    func animate() {
        imageView.animation = "wobble"
        imageView.duration = 2
        imageView.animate()
    }
    
    private func updateAspectRatio(for image: UIImage?) {
        // Remove existing aspect ratio constraint if any
        aspectRatioConstraint?.isActive = false
        
        guard let image = image else { return }
        
        // Create new aspect ratio constraint based on image dimensions
        let aspect = image.size.width / image.size.height
        aspectRatioConstraint = imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor, multiplier: aspect)
        aspectRatioConstraint?.isActive = true
    }
    
    private func setupViews() {
        // Configure corner radius for all views
        layer.cornerRadius = cornerRadius
        layer.masksToBounds = true
        backgroundImageView.layer.cornerRadius = cornerRadius
        blurEffectView.layer.cornerRadius = cornerRadius
        imageView.layer.cornerRadius = cornerRadius
        
        // Use containerView to constrain the image
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(imageView)
        
        let stackView = UIStackView(arrangedSubviews: [containerView])
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add background views first
        addSubview(backgroundImageView)
        addSubview(blurEffectView)
        addSubview(stackView)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        blurEffectView.translatesAutoresizingMaskIntoConstraints = false
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Background image view constraints
            backgroundImageView.topAnchor.constraint(equalTo: topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Blur effect view constraints
            blurEffectView.topAnchor.constraint(equalTo: topAnchor),
            blurEffectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurEffectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurEffectView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Stack view constraints
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Container view constraints
            containerView.widthAnchor.constraint(equalTo: containerView.heightAnchor),
            
            // Center imageView in containerView
            imageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            // Make imageView fill containerView while maintaining aspect ratio
            imageView.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor),
            imageView.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor),
            imageView.topAnchor.constraint(greaterThanOrEqualTo: containerView.topAnchor),
            imageView.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor),
            
            // Make imageView width equal to containerView width (priority optional)
            imageView.widthAnchor.constraint(equalTo: containerView.widthAnchor).with { $0.priority = .defaultHigh }
        ])
    }
}
