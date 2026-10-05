//
//  AppDelegate.swift
//  Swift Radio
//
//  Created by Matthew Fecher on 7/2/15.
//  Copyright (c) 2015 MatthewFecher.com. All rights reserved.
//

import UIKit
#if CarPlay
import CarPlay
#endif

/// Initializes the shared composition and routes CarPlay scenes alongside SwiftUI's phone scene.
@MainActor final class AppDelegate: UIResponder, UIApplicationDelegate {
    let environment = AppEnvironment.shared

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UINavigationBar.appearance().barStyle = .black
        UINavigationBar.appearance().tintColor = Config.tintColor
        UINavigationBar.appearance().prefersLargeTitles = true
        return true
    }

#if CarPlay
    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        if connectingSceneSession.role == .carTemplateApplication {
            let config = UISceneConfiguration(name: "CarPlay Configuration", sessionRole: connectingSceneSession.role)
            config.delegateClass = CarPlaySceneDelegate.self
            return config
        }
        // Leave delegateClass unset so SwiftUI supplies its own phone scene delegate.
        return UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
    }
#endif
}
