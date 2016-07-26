//
//  SwiftRadio-Settings.swift
//  Swift Radio
//
//  Created by Matthew Fecher on 7/2/15.
//  Copyright (c) 2015 MatthewFecher.com. All rights reserved.
//


enum CoverApi : String {
    case iTunes = "iTunes"
    case lastFm = "LastFm"
    case spotify = "Spotify"
}

import Foundation

//**************************************
// GENERAL SETTINGS
//**************************************

// Display Comments
let kDebugLog = true

//**************************************
// STATION JSON
//**************************************

// If this is set to "true", it will use the JSON file in the app
// Set it to "false" to use the JSON file at the stationDataURL

let useLocalStations = true
let stationDataURL   = "http://yoururl.com/json/stations.json"

//**************************************
// SEARCH BAR
//**************************************

// Set this to "true" to enable the search bar
let searchable = false

//**************************************
// LASTFM API
//**************************************

// Use LastFM, iTunes API or Spotify API 
// Spotify has use restrictions, please read https://developer.spotify.com/developer-terms-of-use/
let coverApi = CoverApi.lastFm

// IF YOU USE LASTFM, PLEASE USE YOUR OWN KEY
// Visit: http://www.last.fm/api

let lastFmApiKey    = "9a267c245324cfa4f887366d497d3dd3"
let lastFmApiSecret = "f1191864d7ae71e580b89238129768b8"

