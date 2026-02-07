//
//  MainCoordinator.swift
//  SwiftRadio
//
//  Created by Fethi El Hassasna on 2022-11-23.
//  Copyright © 2022 matthewfecher.com. All rights reserved.
//

import UIKit
import MessageUI
import SafariServices
import LNPopupController

class MainCoordinator: NavigationCoordinator {
    var childCoordinators: [Coordinator] = []
    let navigationController: UINavigationController

    private lazy var nowPlayingViewController: NowPlayingViewController = {
        let vc = NowPlayingViewController()
        vc.delegate = self
        return vc
    }()

    private var isPopupBarPresented = false

    func start() {
        let loaderVC = LoaderController()
        loaderVC.delegate = self
        navigationController.setViewControllers([loaderVC], animated: false)
    }

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    // MARK: - Popup Bar

    func presentPopupBarIfNeeded() {
        guard !isPopupBarPresented else { return }
        navigationController.popupBar.barStyle = .prominent
        navigationController.popupBar.tintColor = Config.tintColor
        navigationController.popupBar.progressViewStyle = .bottom
        navigationController.popupContentView.popupCloseButtonStyle = .chevron
        navigationController.presentPopupBar(withContentViewController: nowPlayingViewController, animated: true)
        isPopupBarPresented = true
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

    func didSelectStation(_ station: RadioStation, from stationsViewController: StationsViewController) {
        let isNewStation = station != StationsManager.shared.currentStation
        if isNewStation {
            StationsManager.shared.set(station: station)
            presentPopupBarIfNeeded()
        } else {
            navigationController.openPopup(animated: true)
        }
    }

    func didTapNowPlaying(_ stationsViewController: StationsViewController) {
        navigationController.openPopup(animated: true)
    }

    func presentAbout(_ stationsViewController: StationsViewController) {
        openAbout()
    }
}

// MARK: - NowPlayingViewControllerDelegate

extension MainCoordinator: NowPlayingViewControllerDelegate {

    func didSelectBottomSheetOption(_ option: BottomSheetViewController.Option, from controller: NowPlayingViewController) {
        guard let station = StationsManager.shared.currentStation else { return }

        switch option {
        case .info:
            let infoController = InfoDetailViewController(station: station)
            navigationController.pushViewController(infoController, animated: true)
            navigationController.closePopup(animated: true)
        case .website:
            if let website = station.website, let url = URL(string: website) {
                let safariVC = SFSafariViewController(url: url)
                navigationController.closePopup(animated: true, completion: { [weak self] in
                    self?.navigationController.present(safariVC, animated: true)
                })
            }
        default:
            BottomSheetHandler.handle(option, station: station, from: controller)
        }
    }

    func didTapCompanyButton(_ nowPlayingViewController: NowPlayingViewController) {
        openAbout()
    }
}
