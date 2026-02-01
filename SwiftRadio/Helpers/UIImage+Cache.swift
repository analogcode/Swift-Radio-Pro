//
//  UIImage+Cache.swift
//  SwiftRadio
//
//  Created by Fethi El Hassasna on 2022-11-01.
//  Copyright © 2022 matthewfecher.com. All rights reserved.
//

import UIKit

extension UIImage {

    static func image(from url: URL?, completion: @escaping (_ image: UIImage?) -> Void) {
        guard let url else {
            completion(nil)
            return
        }
        Task {
            let image = await NetworkService.fetchImage(from: url)
            await MainActor.run { completion(image) }
        }
    }
}
