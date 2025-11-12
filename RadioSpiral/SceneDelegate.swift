//
//  SceneDelegate.swift
//  RadioSpiral
//
//  Created on 2025-11-11.
//

import UIKit
import FRadioPlayer

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var coordinator: MainCoordinator?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        // Create the window
        window = UIWindow(windowScene: windowScene)

        // Create coordinator and navigation controller
        let navigationController = UINavigationController()
        coordinator = MainCoordinator(navigationController: navigationController)

        // Set root view controller
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()

        // Start the coordinator
        coordinator?.start()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        ACWebSocketClient.shared.connect()
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // Only disconnect websocket if audio is NOT playing
        if !FRadioPlayer.shared.isPlaying {
            ACWebSocketClient.shared.disconnect()
        }
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
    }
}
