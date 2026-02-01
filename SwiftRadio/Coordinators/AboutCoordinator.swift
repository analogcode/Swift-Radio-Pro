//
//  AboutCoordinator.swift
//  SwiftRadio
//
//  Created by Fethi El Hassasna on 2025-01-31.
//  Copyright © 2025 matthewfecher.com. All rights reserved.
//

import UIKit
import MessageUI

class AboutCoordinator: NSObject, NavigationCoordinator {
    var childCoordinators: [Coordinator] = []
    let navigationController: UINavigationController
    weak var parentCoordinator: MainCoordinator?

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        let aboutVC = AboutViewController()
        aboutVC.delegate = self
        navigationController.setViewControllers([aboutVC], animated: false)
    }
}

// MARK: - AboutViewControllerDelegate

extension AboutCoordinator: AboutViewControllerDelegate {
    func aboutViewController(_ controller: AboutViewController, didSelectItem item: InfoItem) {
        switch item {
        case .features:
            let featuresVC = FeaturesViewController()
            navigationController.pushViewController(featuresVC, animated: true)

        case .libraries:
            let librariesVC = LibrariesViewController()
            navigationController.pushViewController(librariesVC, animated: true)

        case .credits(_, _, let owner, let repo, _):
            let contributorsVC = ContributorsViewController(owner: owner, repo: repo)
            navigationController.pushViewController(contributorsVC, animated: true)

        case .link(_, _, let urlString, _):
            if let url = URL(string: urlString) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }

        case .email(_, _, let address, _):
            parentCoordinator?.openEmail(to: address, from: self)

        case .share(_, let text, _):
            guard let aboutVC = navigationController.viewControllers.first as? AboutViewController else { return }
            parentCoordinator?.share(text, from: aboutVC)

        case .rateApp(_, let appID, _):
            if let url = URL(string: "itms-apps://itunes.apple.com/app/id\(appID)") {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }

        case .version:
            break
        }
    }
}

// MARK: - MFMailComposeViewControllerDelegate

extension AboutCoordinator: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult,
                               error: Error?) {
        controller.dismiss(animated: true)
    }
}
