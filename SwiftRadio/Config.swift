//
//  SwiftRadio-Settings.swift
//  Swift Radio
//
//  Created by Matthew Fecher on 7/2/15.
//  Copyright (c) 2015 MatthewFecher.com. All rights reserved.
//

import UIKit

struct Config {
    
    static let debugLog = true

    // If this is set to "true", it will use the JSON file in the app
    // Set it to "false" to use the JSON file at the stationDataURL
    static let useLocalStations = true
    static let stationsURL = "https://fethica.com/assets/swift-radio/stations.json"

    // Set this to "true" to enable the search bar
    static let searchable = false

    // Set this to "false" to show the next/previous player buttons
    static let hideNextPreviousButtons = false
    
    // Contact infos
    static let website = "https://github.com/analogcode/Swift-Radio-Pro"
    static let email = "contact@fethica.com"
    static let emailSubject = "From \(Bundle.main.appName) App"

    struct Libraries {
        static let items: [LibraryItem] = [
            LibraryItem(owner: "analogcode", repo: "Swift-Radio-Pro"),
            LibraryItem(owner: "fethica", repo: "FRadioPlayer"),
            LibraryItem(owner: "MengTo", repo: "Spring"),
            LibraryItem(owner: "ninjaprox", repo: "NVActivityIndicatorView"),
        ]
    }

    struct Features {
        static let items: [FeatureItem] = [
            FeatureItem(title: Content.Features.swiftCodebase.0, subtitle: Content.Features.swiftCodebase.1, icon: "swift"),
            FeatureItem(title: Content.Features.carPlay.0, subtitle: Content.Features.carPlay.1, icon: "car.fill"),
            FeatureItem(title: Content.Features.customizableUI.0, subtitle: Content.Features.customizableUI.1, icon: "paintbrush"),
            FeatureItem(title: Content.Features.albumArt.0, subtitle: Content.Features.albumArt.1, icon: "music.note.list"),
            FeatureItem(title: Content.Features.lockScreen.0, subtitle: Content.Features.lockScreen.1, icon: "lock.circle"),
            FeatureItem(title: Content.Features.multipleStations.0, subtitle: Content.Features.multipleStations.1, icon: "radio"),
            FeatureItem(title: Content.Features.easySetup.0, subtitle: Content.Features.easySetup.1, icon: "checkmark.seal.fill"),
        ]
    }

    struct About {
        static let sections: [InfoSection] = [
            InfoSection(title: Content.About.Sections.features, items: [
                .features()
            ]),
            InfoSection(title: Content.About.Sections.contact, items: [
                .email(address: Config.email),
                .link(title: Content.About.feedback.0, subtitle: Content.About.feedback.1, url: "https://fethica.com/#contact")
            ]),
            InfoSection(title: Content.About.Sections.support, items: [
                .rateApp(appID: "YOUR_APP_ID"),
                .share(text: Content.About.shareText)
            ]),
            InfoSection(title: Content.About.Sections.credits, items: [
                .libraries(),
                .credits(owner: "analogcode", repo: "Swift-Radio-Pro")
            ]),
            InfoSection(title: Content.About.Sections.legal, items: [
                .link(title: Content.About.license.0, subtitle: Content.About.license.1, url: "https://raw.githubusercontent.com/analogcode/Swift-Radio-Pro/refs/heads/master/LICENSE")
            ]),
            InfoSection(title: Content.About.Sections.version, items: [
                .version()
            ])
        ]
    }
}

