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

    // Station loading configuration
    // Priority: useConfigClient → useLocalStations → stationsURL
    static let useConfigClient = true  // Use dynamic ConfigClient for stations
    static let useLocalStations = false  // Fall back to local JSON if enabled
    static let stationsURL = "https://raw.githubusercontent.com/joemcmahon/radiospiral-config/master/stations.json"

    // Set this to "true" to enable the search bar
    static let searchable = false

    // Set this to "false" to show the next/previous player buttons
    static let hideNextPreviousButtons = true

    // Contact infos
    static let website = "https://radiospiral.net"
    static let email = "radio@pemungkah.com"
    static let emailSubject = "\(Bundle.main.appName) App Q"
}

