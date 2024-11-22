//
//  LoaderController.swift
//  SwiftRadio
//
//  Created by Fethi El Hassasna on 2022-12-03.
//  Copyright © 2022 matthewfecher.com. All rights reserved.
//

import UIKit

protocol LoaderControllerDelegate: AnyObject {
    func didFinishLoading(_ controller: LoaderController, stations: [RadioStation])
}

class LoaderController: BaseController {
    
    weak var delegate: LoaderControllerDelegate?
    
    private let manager = StationsManager.shared
    
    private let activityIndicatorView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .white)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let errorTitleLabel: UILabel = {
        let label = UILabel()
        label.accessibilityIdentifier = "errorTitleLabel"
        label.textAlignment = .center
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        label.numberOfLines = 0
        label.text = "Something went wrong!"
        return label
    }()
    
    private let errorMessageLabel: UILabel = {
        let label = UILabel()
        label.accessibilityIdentifier = "errorMessageLabel"
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = UIFont.preferredFont(forTextStyle: .footnote)
        return label
    }()
    
    private let stackView: UIStackView = {
        let view = UIStackView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .vertical
        view.alignment = .center
        view.spacing = 16
        return view
    }()
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        fetchStations()
    }
    
    private func handle(_ error: Error) {
        stackView.isHidden = false
        errorMessageLabel.text = error.localizedDescription
    }
    
    private func fetchStations() {
        stackView.isHidden = true
        activityIndicatorView.startAnimating()
        
        manager.fetch { [weak self] result in
            guard let self = self else { return }
            
            self.activityIndicatorView.stopAnimating()
            
            switch result {
            case .success(let stations):
                self.delegate?.didFinishLoading(self, stations: stations)
            case .failure(let error):
                self.handle(error)
            }
        }
    }
    
    override func setupViews() {
        super.setupViews()
        
        // Logo Image
        let logoImage = UIImage(named: "logo")
        let logoImageView = UIImageView(image: logoImage)
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(logoImageView)
        
        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // Activity Indicator
        view.addSubview(activityIndicatorView)
        
        NSLayoutConstraint.activate([
            activityIndicatorView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicatorView.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 32)
        ])
        
        // Retry button
        let retryButton = UIButton(type: .system)
        retryButton.setTitle("Try again", for: .normal)
        retryButton.addTarget(self, action: #selector(handleRetry), for: .touchUpInside)
        
        // Stack view
        stackView.addArrangedSubview(errorTitleLabel)
        stackView.addArrangedSubview(errorMessageLabel)
        stackView.addArrangedSubview(retryButton)
        
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 32),
            stackView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7)
        ])
    }
    
    @objc private func handleRetry() {
        fetchStations()
    }
}
