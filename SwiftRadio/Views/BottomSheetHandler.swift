//
//  BottomSheetHandler.swift
//  SwiftRadio
//
//  Created by Fethi El Hassasna on 2024-01-14.
//  Copyright © 2024 matthewfecher.com. All rights reserved.
//

import UIKit
import FRadioPlayer

class BottomSheetHandler {
    static func handle(_ option: BottomSheetViewController.Option,
                       station: RadioStation,
                       from viewController: UIViewController) {
        switch option {
        case .info:
            let infoController = InfoDetailViewController(station: station)
            viewController.navigationController?.pushViewController(infoController, animated: true)
            
        case .share(let image):
            ShareActivity.activityController(image: image,
                                             station: station,
                                             sourceView: viewController.view) { controller in
                viewController.present(controller, animated: true)
            }
            
        case .website:
            if let website = station.website, let websiteURL = URL(string: website) {
                UIApplication.shared.open(websiteURL)
            }
            
        case .openInMusic(let url):
            if let url {
                UIApplication.shared.open(url)
            }
        }
    }
}

