//
//  InfoDetailViewController.swift
//  Swift Radio
//
//  Created by Matthew Fecher on 7/9/15.
//  Copyright (c) 2015 MatthewFecher.com. All rights reserved.
//

import UIKit

class InfoDetailViewController: UIViewController {
    
    @IBOutlet weak var stationImageView: UIImageView!
    @IBOutlet weak var stationNameLabel: UILabel!
    @IBOutlet weak var stationDescLabel: UILabel!
    @IBOutlet weak var stationLongDescTextView: UITextView!
    @IBOutlet weak var okayButton: UIButton!
    
    var currentStation: RadioStation!
    var downloadTask: URLSessionDownloadTask?

    //*****************************************************************
    // MARK: - ViewDidLoad
    //*****************************************************************
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupStationText()
        setupStationLogo()
    }

    deinit {
        // Be a good citizen.
        downloadTask?.cancel()
        downloadTask = nil
    }
    
    //*****************************************************************
    // MARK: - UI Helpers
    //*****************************************************************
    
    func setupStationText() {
        
        // Display Station Name & Short Desc
        stationNameLabel.text = currentStation.stationName
        stationDescLabel.text = currentStation.stationDesc
        
        // Display Station Long Desc
        if currentStation.stationLongDesc == "" {
            loadDefaultText()
        } else {
            stationLongDescTextView.text = currentStation.stationLongDesc
        }
    }
    
    func loadDefaultText() {
        // Add your own default ext
        stationLongDescTextView.text = "You are listening to Swift Radio. This is a sweet open source project. Tell your friends, swiftly!"
    }
    
    func setupStationLogo() {
        
        // Display Station Image/Logo
        let imageURL = currentStation.stationImageURL
        
        if imageURL.range(of: "http") != nil {
            // Get station image from the web, iOS should cache the image
            if let url = URL(string: currentStation.stationImageURL) {
                downloadTask = stationImageView.loadImageWithURL(url: url) { _ in }
            }
            
        } else if imageURL != "" {
            // Get local station image
            stationImageView.image = UIImage(named: imageURL)
            
        } else {
            // Use default image if station image not found
            stationImageView.image = UIImage(named: "stationImage")
        }
        
        // Apply shadow to Station Image
        stationImageView.applyShadow()
    }
    
    //*****************************************************************
    // MARK: - IBActions
    //*****************************************************************
    
    @IBAction func okayButtonPressed(_ sender: UIButton) {
        _ = navigationController?.popViewController(animated: true)
    }
    
}
