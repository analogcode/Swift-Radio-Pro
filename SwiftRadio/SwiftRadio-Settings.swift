//
//  SwiftRadio-Settings.swift
//  Swift Radio
//
//  Created by Matthew Fecher on 7/2/15.
//  Copyright (c) 2015 MatthewFecher.com. All rights reserved.
//

import Foundation
import UIKit

// MARK: - GENERAL SETTINGS

// Display Comments
let kDebugLog = true

// MARK: - STATION JSON

// If this is set to "true", it will use the JSON file in the app
// Set it to "false" to use the JSON file at the stationDataURL

let useLocalStations = true
let stationDataURL   = "https://fethica.com/assets/swift-radio/stations.json"

// MARK: - SEARCH BAR

// Set this to "true" to enable the search bar
let searchable = false

// MARK: - NEXT / PREVIOUS BUTTONS

// Set this to "false" to show the next/previous player buttons
let hideNextPreviousButtons = true
