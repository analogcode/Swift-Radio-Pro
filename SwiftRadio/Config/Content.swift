//
//  Content.swift
//  Swift Radio
//
//  Created by Fethi El Hassasna on 2025-01-26.
//  Copyright © 2025 matthewfecher.com. All rights reserved.
//
//  All user-facing strings are backed by Localizable.xcstrings.
//  To update text or add translations, edit the String Catalog in Xcode.
//

import Foundation

struct Content {
    struct About {
        static let title = String(localized: "about.title")
        static let headerText = String(localized: "about.headerText")
        static let footerAuthors = String(localized: "about.footerAuthors")
        static let footerCopyright = String(localized: "about.footerCopyright")

        struct Sections {
            static let features = String(localized: "about.sections.features")
            static let contact = String(localized: "about.sections.contact")
            static let support = String(localized: "about.sections.support")
            static let credits = String(localized: "about.sections.credits")
            static let legal = String(localized: "about.sections.legal")
            static let version = String(localized: "about.sections.version")
        }

        static let feedback = (String(localized: "about.feedback.title"), String(localized: "about.feedback.message"))
        static let shareText = String(localized: "about.shareText")
        static let license = (String(localized: "about.license.title"), String(localized: "about.license.detail"))
    }

    struct Contributors {
        static let title = String(localized: "contributors.title")
    }

    struct Libraries {
        static let title = String(localized: "libraries.title")
    }

    struct Stations {
        static let title = String(localized: "stations.title")
        static let loadingMessage = String(localized: "stations.loadingMessage")
    }

    struct Loader {
        static let errorTitle = String(localized: "loader.errorTitle")
        static let retryButton = String(localized: "loader.retryButton")
    }

    struct StationDetail {
        static let title = String(localized: "stationDetail.title")
        static let visitWebsite = String(localized: "stationDetail.visitWebsite")
        static let defaultDescription = String(localized: "stationDetail.defaultDescription")
    }

    struct BottomSheet {
        static let aboutStation = String(localized: "bottomSheet.aboutStation")
        static let shareNowPlaying = String(localized: "bottomSheet.shareNowPlaying")
        static let stationWebsite = String(localized: "bottomSheet.stationWebsite")
        static let playInMusicApp = String(localized: "bottomSheet.playInMusicApp")
    }

    struct Player {
        static let liveBadge = String(localized: "player.liveBadge")
    }

    struct Common {
        static let ok = String(localized: "common.ok")
        static let couldNotSendEmail = String(localized: "common.couldNotSendEmail")
        static let emailErrorMessage = String(localized: "common.emailErrorMessage")
        static let noDescription = String(localized: "common.noDescription")
        static let commitsFormat = String(localized: "common.commitsFormat")
    }

    struct Features {
        static let title = String(localized: "features.title")

        static let swiftCodebase = (String(localized: "features.swiftCodebase.title"), String(localized: "features.swiftCodebase.description"))
        static let carPlay = (String(localized: "features.carPlay.title"), String(localized: "features.carPlay.description"))
        static let customizableUI = (String(localized: "features.customizableUI.title"), String(localized: "features.customizableUI.description"))
        static let albumArt = (String(localized: "features.albumArt.title"), String(localized: "features.albumArt.description"))
        static let lockScreen = (String(localized: "features.lockScreen.title"), String(localized: "features.lockScreen.description"))
        static let multipleStations = (String(localized: "features.multipleStations.title"), String(localized: "features.multipleStations.description"))
        static let easySetup = (String(localized: "features.easySetup.title"), String(localized: "features.easySetup.description"))
    }
}
