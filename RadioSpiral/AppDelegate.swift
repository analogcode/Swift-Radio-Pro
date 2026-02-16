//
//  AppDelegate.swift
//  Swift Radio
//
//  Created by Matthew Fecher on 7/2/15.
//  Copyright (c) 2015 MatthewFecher.com. All rights reserved.
//

import UIKit
import MediaPlayer
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // AzuraCast WebSocket debug - disable by default
        ACWebSocketClient.shared.debug(to: 0)

        // AudioSession & RemotePlay
        activateAudioSession()
        setupRemoteCommandCenter()
        UIApplication.shared.beginReceivingRemoteControlEvents()

        // Make status bar white
        UINavigationBar.appearance().barStyle = .black
        UINavigationBar.appearance().tintColor = .white
        UINavigationBar.appearance().prefersLargeTitles = true

        return true
    }

    // MARK: - UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Return the appropriate scene configuration based on the session role
        let roleString = connectingSceneSession.role.rawValue

        if roleString.contains("CPTemplate") {
            // CarPlay scene - use CarPlaySceneDelegate
            let delegateClass = NSClassFromString("RadioSpiral.CarPlaySceneDelegate")
            let config = UISceneConfiguration(name: "CarPlay Configuration", sessionRole: connectingSceneSession.role)
            config.delegateClass = delegateClass
            return config
        } else {
            // Phone/window scene - use SceneDelegate
            let config = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
            config.delegateClass = SceneDelegate.self
            return config
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        ACWebSocketClient.shared.disconnect()
        UIApplication.shared.endReceivingRemoteControlEvents()
    }
    
    // MARK: - Remote Controls
    
    private func setupRemoteCommandCenter() {
        // Get the shared MPRemoteCommandCenter
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // Add handler for Play Command
        commandCenter.playCommand.addTarget { event in
            StationsManager.shared.reloadCurrent()
            RadioPlayer.shared.play()
            return .success
        }
        
        // Add handler for Pause Command
        commandCenter.pauseCommand.addTarget { event in
            RadioPlayer.shared.stop()
            return .success
        }
        
        // Add handler for Toggle Command
        commandCenter.togglePlayPauseCommand.addTarget { event in
            if RadioPlayer.shared.isPlaying {
                RadioPlayer.shared.stop()
            } else {
                RadioPlayer.shared.play()
            }
            return .success
        }
        
        // Add handler for Next Command
        commandCenter.nextTrackCommand.addTarget { event in
            StationsManager.shared.setNext()
            return .success
        }
        
        // Add handler for Previous Command
        commandCenter.previousTrackCommand.addTarget { event in
            StationsManager.shared.setPrevious()
            return .success
        }
    }
    
    // MARK: - Activate Audio Session
    
    private func activateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let error {
            if Config.debugLog {
                print("audioSession could not be activated: \(error.localizedDescription)")
            }
        }
    }
}

