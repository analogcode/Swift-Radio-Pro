//
//  Bundle+appName.swift
//  SwiftRadio
//
//  Created by Fethi El Hassasna on 2022-11-29.
//  Copyright © 2022 matthewfecher.com. All rights reserved.
//

import Foundation

extension Bundle {
    var appName: String {
        object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ??
        object(forInfoDictionaryKey: "CFBundleName") as? String ??
        ""
    }
}
