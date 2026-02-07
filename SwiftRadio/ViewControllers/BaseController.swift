//
//  BaseController.swift
//  SwiftRadio
//
//  Created by Fethi El Hassasna on 2022-12-03.
//  Copyright © 2022 matthewfecher.com. All rights reserved.
//

import UIKit

class BaseController: UIViewController {
    
    let gradientBackgroundView: GradientBackgroundView = {
        let view = GradientBackgroundView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override func loadView() {
        super.loadView()
        setupViews()
    }
    
    func setupViews() {
        view.addSubview(gradientBackgroundView)

        NSLayoutConstraint.activate([
            gradientBackgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            gradientBackgroundView.rightAnchor.constraint(equalTo: view.rightAnchor),
            gradientBackgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            gradientBackgroundView.leftAnchor.constraint(equalTo: view.leftAnchor)
        ])
    }
}
