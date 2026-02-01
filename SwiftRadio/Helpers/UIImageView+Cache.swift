//
//  UIImageView+Cache.swift
//  SwiftRadio
//
//  Created by Fethi El Hassasna on 2022-11-01.
//  Copyright © 2022 matthewfecher.com. All rights reserved.
//

import UIKit

extension UIImageView {

    func load(url: URL, placeholder: UIImage? = nil) {
        self.image = placeholder
        Task {
            guard let image = await NetworkService.fetchImage(from: url) else { return }
            self.image = image
        }
    }
}
