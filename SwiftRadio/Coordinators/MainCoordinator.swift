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
        let loaderVC = LoaderController()
        loaderVC.delegate = self
        navigationController.setViewControllers([loaderVC], animated: false)
    }

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    // MARK: - Shared

    func openEmail(to email: String, from coordinator: AboutCoordinator) {
        guard let aboutVC = coordinator.navigationController.viewControllers.first as? AboutViewController else { return }
        guard MFMailComposeViewController.canSendMail() else {
            aboutVC.showSendMailErrorAlert()
            return
        }

        let mailComposer = MFMailComposeViewController()
        mailComposer.mailComposeDelegate = coordinator
        mailComposer.setToRecipients([email])
        mailComposer.setSubject(Config.emailSubject)
        mailComposer.setMessageBody("", isHTML: false)
        aboutVC.present(mailComposer, animated: true)
    }

    func openAbout() {
        let modalNav = UINavigationController()
        let aboutCoordinator = AboutCoordinator(navigationController: modalNav)
        aboutCoordinator.parentCoordinator = self
        aboutCoordinator.start()
        childCoordinators.append(aboutCoordinator)
        navigationController.present(modalNav, animated: true)
    }

    func openWebsite(url: URL, from viewController: UIViewController) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    func share(_ text: String, from viewController: UIViewController) {
        let activityViewController = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let popoverController = activityViewController.popoverPresentationController {
            popoverController.sourceView = viewController.view
            popoverController.sourceRect = CGRect(x: viewController.view.bounds.midX, y: viewController.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        viewController.present(activityViewController, animated: true)
    }
}

// MARK: - LoaderControllerDelegate

extension MainCoordinator: LoaderControllerDelegate {
    func didFinishLoading(_ controller: LoaderController, stations: [RadioStation]) {
        let stationsVC = StationsViewController()
        stationsVC.delegate = self
        navigationController.setViewControllers([stationsVC], animated: false)
    }
}

// MARK: - StationsViewControllerDelegate

extension MainCoordinator: StationsViewControllerDelegate {

    func pushNowPlayingController(_ stationsViewController: StationsViewController, newStation: Bool) {
        let nowPlayingController = NowPlayingViewController()
        nowPlayingController.delegate = self
        nowPlayingController.isNewStation = newStation
        navigationController.pushViewController(nowPlayingController, animated: true)
    }

    func presentAbout(_ stationsViewController: StationsViewController) {
        openAbout()
    }
}

// MARK: - NowPlayingViewControllerDelegate

extension MainCoordinator: NowPlayingViewControllerDelegate {

    func didSelectBottomSheetOption(_ option: BottomSheetViewController.Option, from controller: NowPlayingViewController) {
        guard let station = StationsManager.shared.currentStation else { return }
        BottomSheetHandler.handle(option, station: station, from: controller)
    }

    func didTapCompanyButton(_ nowPlayingViewController: NowPlayingViewController) {
        openAbout()
    }
}
