//
//  InfoSection.swift
//  Swift Radio
//
//  Created by Fethi El Hassasna on 2025-01-26.
//  Copyright © 2025 matthewfecher.com. All rights reserved.
//

import Foundation

struct FeatureItem {
    let title: String
    let subtitle: String
    let icon: String // SF Symbol name
}

struct LibraryItem {
    let owner: String
    let repo: String
}

struct InfoSection {
    let title: String
    let items: [InfoItem]
    var isEnabled: Bool = true
}

enum InfoItem {
    // Navigation (pushes to a screen)
    case features(title: String = "Features", icon: String? = nil)
    case libraries(title: String = "Open Source Libraries", subtitle: String? = nil, icon: String? = nil)
    case credits(title: String = "Contributors", subtitle: String? = "Special Thanks", owner: String, repo: String, icon: String? = nil)

    // External actions
    case link(title: String, subtitle: String? = nil, url: String, icon: String? = nil)
    case email(title: String = "Email", subtitle: String? = nil, address: String, icon: String? = nil)
    case rateApp(title: String = "Rate the App", appID: String, icon: String? = nil)
    case share(title: String = "Share the App", text: String, icon: String? = nil)

    // Display only
    case version(title: String = "App Version", icon: String? = nil)

    var title: String {
        switch self {
        case .features(let title, _): return title
        case .libraries(let title, _, _): return title
        case .credits(let title, _, _, _, _): return title
        case .link(let title, _, _, _): return title
        case .email(let title, _, _, _): return title
        case .rateApp(let title, _, _): return title
        case .share(let title, _, _): return title
        case .version(let title, _): return title
        }
    }

    var subtitle: String? {
        switch self {
        case .libraries(_, let subtitle, _): return subtitle
        case .credits(_, let subtitle, _, _, _): return subtitle
        case .link(_, let subtitle, _, _): return subtitle
        case .email(_, let subtitle, let address, _): return subtitle ?? address
        case .version:
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
            let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
            return "\(version) (\(build))"
        default: return nil
        }
    }

    var icon: String? {
        let customIcon: String?
        switch self {
        case .features(_, let icon): customIcon = icon
        case .libraries(_, _, let icon): customIcon = icon
        case .credits(_, _, _, _, let icon): customIcon = icon
        case .link(_, _, _, let icon): customIcon = icon
        case .email(_, _, _, let icon): customIcon = icon
        case .rateApp(_, _, let icon): customIcon = icon
        case .share(_, _, let icon): customIcon = icon
        case .version(_, let icon): customIcon = icon
        }
        return customIcon ?? defaultIcon
    }

    private var defaultIcon: String {
        switch self {
        case .features: return "list.bullet"
        case .libraries: return "book"
        case .credits: return "heart"
        case .link: return "globe"
        case .email: return "envelope"
        case .rateApp: return "star"
        case .share: return "square.and.arrow.up"
        case .version: return "info"
        }
    }
}
