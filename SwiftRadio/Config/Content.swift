//
//  Content.swift
//  Swift Radio
//
//  Created by Fethi El Hassasna on 2025-01-26.
//  Copyright © 2025 matthewfecher.com. All rights reserved.
//

import Foundation

struct Content {
    struct About {
        static let title = "About Swift Radio"

        static let headerText = """
        **Swift Radio** is a fully featured, open-source radio station app written entirely in **Swift**. \
        It provides robust, professional functionality out of the box, \
        complete with **Apple CarPlay** support, making it the perfect foundation \
        for **building** or **customizing** your own streaming radio experience.
        """

        static let footerAuthors = "Fethi El Hassasna & Matt Fecher"
        static let footerCopyright = "Swift Radio"

        struct Sections {
            static let features = "Features"
            static let contact = "Contact"
            static let support = "Support"
            static let credits = "Credits"
            static let legal = "Legal"
            static let version = "Version"
        }

        static let feedback = ("Feedback", "We value your input! Please take a moment to provide feedback")
        static let shareText = "Check out Swift Radio!"
        static let license = ("License", "MIT License")
    }

    struct Contributors {
        static let title = "Contributors"
    }

    struct Libraries {
        static let title = "Libraries"
    }

    struct Features {
        static let title = "Features"

        static let swiftCodebase = ("Swift Codebase", "Entirely written in Swift with a clean and modern structure.")
        static let carPlay = ("Apple CarPlay Support", "Lets users control their radio playback directly from their CarPlay dashboard.")
        static let customizableUI = ("Customizable UI", "Includes a flexible interface that you can easily personalize with your own theme and branding.")
        static let albumArt = ("Album Art & Metadata", "Displays track information and album covers to enhance the listening experience.")
        static let lockScreen = ("Lock Screen & Control Center Integration", "Shows artwork and track info on the lock screen, and provides convenient controls without opening the app.")
        static let multipleStations = ("Multiple Stations Setup", "Comes with a straightforward station list manager that supports multiple streaming URLs.")
        static let easySetup = ("Easy Project Setup", "Ready to run right out of the box, and you can adjust key settings in a single configuration file.")
    }
}
