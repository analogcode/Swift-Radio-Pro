//
//  SwiftRadioApp.swift
//  Swift Radio
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import SwiftUI

/// Boots the phone UI with the same composition used by the CarPlay scene.
@main @MainActor struct SwiftRadioApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appDelegate.environment.stations)
                .environment(appDelegate.environment.player)
                .environment(\.artworkLoader, appDelegate.environment.artwork)
                .tint(Color(uiColor: Config.tintColor))
        }
    }
}
