//
//  AppDelegate.swift
//  Swift Radio
//
//  Created by Matthew Fecher on 7/2/15.
//  Copyright (c) 2015 MatthewFecher.com. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    weak var stationsViewController: StationsViewController?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // MPNowPlayingInfoCenter
        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        // Make status bar white
        UINavigationBar.appearance().barStyle = .black
        
        // FRadioPlayer config
        FRadioPlayer.shared.isAutoPlay = true
        FRadioPlayer.shared.enableArtwork = true
        FRadioPlayer.shared.artworkSize = 600
        
        // Get weak ref of StationsViewController
        if let navigationController = window?.rootViewController as? UINavigationController {
            stationsViewController = navigationController.viewControllers.first as? StationsViewController
        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
       
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
  
        
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        
        UIApplication.shared.endReceivingRemoteControlEvents()
        
    }
    
    // MARK: - Remote Controls

    override func remoteControlReceived(with event: UIEvent?) {
        super.remoteControlReceived(with: event)
        
        guard let event = event, event.type == .remoteControl else { return }
        
        switch event.subtype {
        case .remoteControlPlay:
            FRadioPlayer.shared.play()
        case .remoteControlPause:
            FRadioPlayer.shared.pause()
        case .remoteControlTogglePlayPause:
            FRadioPlayer.shared.togglePlaying()
        case .remoteControlNextTrack:
            stationsViewController?.didPressNextButton()
        case .remoteControlPreviousTrack:
            stationsViewController?.didPressPreviousButton()
        default:
            break
        }
    }
}

