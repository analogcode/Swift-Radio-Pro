//
//  MainCoordinator.swift
//  SwiftRadio
//
//  Created by Fethi El Hassasna on 2022-11-23.
//  Copyright © 2022 matthewfecher.com. All rights reserved.
//

import UIKit
import MessageUI

class MainCoordinator: NavigationCoordinator {
    var childCoordinators: [Coordinator] = []
    let navigationController: UINavigationController
    
    func start() {
        let stationsVC = Storyboard.viewController as StationsViewController
        stationsVC.delegate = self
        navigationController.setViewControllers([stationsVC], animated: false)
    }
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    // MARK: - Shared
    
    func openWebsite() {
        // TODO: Move URL to config
        // Use your own website URL here
        guard let url = URL(string: "https://github.com/analogcode/") else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    func openEmail(in viewController: UIViewController & MFMailComposeViewControllerDelegate) {
        // TODO: Move infos to config
        // Use your own email address & subject
        let receipients = ["matthew.fecher@gmail.com"]
        let subject = "From Swift Radio App"
        let messageBody = ""
        
        let configuredMailComposeViewController = viewController.configureMailComposeViewController(recepients: receipients, subject: subject, messageBody: messageBody)
        
        if viewController.canSendMail {
            viewController.present(configuredMailComposeViewController, animated: true, completion: nil)
        } else {
            viewController.showSendMailErrorAlert()
        }
    }
    
    func openAbout(in viewController: UIViewController) {
        let aboutController = Storyboard.viewController as AboutViewController
        aboutController.delegate = self
        viewController.present(aboutController, animated: true)
    }
}

// MARK: - StationsViewControllerDelegate

extension MainCoordinator: StationsViewControllerDelegate {
    
    func pushNowPlayingController(_ stationsViewController: StationsViewController, newStation: Bool) {
        let nowPlayingController = Storyboard.viewController as NowPlayingViewController
        nowPlayingController.delegate = self
        nowPlayingController.isNewStation = newStation
        navigationController.pushViewController(nowPlayingController, animated: true)
    }
    
    func presentPopUpMenuController(_ stationsViewController: StationsViewController) {
        let popUpMenuController = Storyboard.viewController as PopUpMenuViewController
        popUpMenuController.delegate = self
        navigationController.present(popUpMenuController, animated: true)
    }
}

// MARK: - NowPlayingViewControllerDelegate

extension MainCoordinator: NowPlayingViewControllerDelegate {
    func didTapInfoButton(_ nowPlayingViewController: NowPlayingViewController, station: RadioStation) {
        let infoController = Storyboard.viewController as InfoDetailViewController
        infoController.currentStation = station
        navigationController.pushViewController(infoController, animated: true)
    }
    
    func didTapCompanyButton(_ nowPlayingViewController: NowPlayingViewController) {
        openAbout(in: nowPlayingViewController)
    }
}

// MARK: - PopUpMenuViewControllerDelegate

extension MainCoordinator: PopUpMenuViewControllerDelegate {
    
    func didTapWebsiteButton(_ popUpMenuViewController: PopUpMenuViewController) {
        openWebsite()
    }
    
    func didTapAboutButton(_ popUpMenuViewController: PopUpMenuViewController) {
        openAbout(in: popUpMenuViewController)
    }
}

// MARK: - PopUpMenuViewControllerDelegate

extension MainCoordinator: AboutViewControllerDelegate {
    func didTapEmailButton(_ aboutViewController: AboutViewController) {
        openEmail(in: aboutViewController)
    }
    
    func didTapWebsiteButton(_ aboutViewController: AboutViewController) {
        openWebsite()
    }
}
