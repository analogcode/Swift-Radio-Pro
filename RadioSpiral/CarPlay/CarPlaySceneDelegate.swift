//
//  CarPlaySceneDelegate.swift
//  RadioSpiral
//
//  Created by Joe McMahon on 2025-11-11.
//  Copyright © 2025 matthewfecher.com. All rights reserved.
//

import CarPlay
import MediaPlayer

/// CarPlay scene delegate for modern CarPlay framework (iOS 14+)
/// Handles CarPlay interface setup, station browsing, and playback
///
/// This implementation replaces the deprecated MPPlayableContentManager with
/// the modern CarPlay framework (iOS 14+), providing better UX and future compatibility.
/// Uses a tab bar for modern navigation between stations and now playing.
class CarPlaySceneDelegate: NSObject, CPTemplateApplicationSceneDelegate {

    // MARK: - Properties

    var interfaceController: CPInterfaceController?
    private var stationsObservationToken: NSObjectProtocol?
    private var stationsListTemplate: CPListTemplate?
    private var nowPlayingTemplate: CPNowPlayingTemplate?

    // MARK: - CPTemplateApplicationSceneDelegate

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = interfaceController

        // Set up the root tab bar template when CarPlay connects
        let tabBarTemplate = createTabBarTemplate()
        interfaceController.setRootTemplate(tabBarTemplate, animated: false)
    }

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = nil
        self.stationsListTemplate = nil
        self.nowPlayingTemplate = nil

        // Stop observing station updates
        if let token = stationsObservationToken {
            NotificationCenter.default.removeObserver(token)
            stationsObservationToken = nil
        }
    }

    // MARK: - Tab Bar Template Creation

    /// Creates a tab bar template with stations and now playing tabs
    private func createTabBarTemplate() -> CPTabBarTemplate {
        let stationsTab = createStationsListTemplate()
        let nowPlayingTab = CPNowPlayingTemplate.shared

        self.stationsListTemplate = stationsTab
        self.nowPlayingTemplate = nowPlayingTab

        // Update now playing template immediately
        updateNowPlayingTemplate()

        let tabBar = CPTabBarTemplate(templates: [stationsTab, nowPlayingTab])
        return tabBar
    }

    // MARK: - Template Creation

    /// Creates the stations list template
    private func createStationsListTemplate() -> CPListTemplate {
        let title = "Stations"
        var listItems: [CPListItem] = []

        // Create list items for each station
        for station in StationsManager.shared.stations {
            let listItem = createStationListItem(for: station)
            listItems.append(listItem)
        }

        let section = CPListSection(items: listItems)
        let template = CPListTemplate(title: title, sections: [section])

        return template
    }

    /// Creates a list item for a single station
    private func createStationListItem(for station: RadioStation) -> CPListItem {
        let listItem = CPListItem(
            text: station.name,
            detailText: station.desc
        )

        // Set station artwork if available
        station.getImage { image in
            listItem.setImage(image)
        }

        // Handle station selection
        listItem.handler = { [weak self] item, completionHandler in
            self?.selectStation(station, completionHandler: completionHandler)
        }

        return listItem
    }

    /// Called when user selects a station
    private func selectStation(
        _ station: RadioStation,
        completionHandler: @escaping () -> Void
    ) {
        // Set the station in the manager
        StationsManager.shared.set(station: station)

        // Start playback
        FRadioPlayer.shared.play()

        // Update now playing template
        updateNowPlayingTemplate()

        // Dismiss the selection handler
        completionHandler()

        // Switch to now playing tab
        if let nowPlayingTemplate = CPNowPlayingTemplate.shared as? CPTabBarTemplate {
            // Tab bar automatically switches
        }
    }

    /// Updates the now playing template with current station info
    private func updateNowPlayingTemplate() {
        let nowPlayingTemplate = CPNowPlayingTemplate.shared
        let station = StationsManager.shared.currentStation
        let client = ACWebSocketClient.shared

        // Set station info
        nowPlayingTemplate.title = station?.name ?? "No Station"
        nowPlayingTemplate.subtitle = station?.desc

        // Set artwork
        if let station = station {
            station.getImage { image in
                nowPlayingTemplate.artworkView.image = image
            }
        }

        // Update MPNowPlayingInfoCenter for lock screen and other integrations
        updateMPNowPlayingInfo(station: station)

        // Set track info from metadata
        nowPlayingTemplate.albumArtistName = client.status.artist
        nowPlayingTemplate.albumTitle = client.status.track

        // Subscribe to metadata updates
        subscribeToMetadataUpdates()
    }

    /// Updates the MPNowPlayingInfoCenter for system integration
    private func updateMPNowPlayingInfo(station: RadioStation?) {
        var nowPlayingInfo = [String: Any]()

        if let station = station {
            nowPlayingInfo[MPMediaItemPropertyTitle] = station.name
        }

        let client = ACWebSocketClient.shared
        nowPlayingInfo[MPMediaItemPropertyArtist] = client.status.artist
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = client.status.album
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = 0 // Unknown for streaming

        if let artwork = client.status.artwork {
            station?.getImage { image in
                let artworkItem = MPMediaItemArtwork(boundsSize: image.size) { _ in
                    return image
                }
                nowPlayingInfo[MPMediaItemPropertyArtwork] = artworkItem
                MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
            }
        } else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        }
    }

    /// Subscribes to metadata updates from WebSocket client
    private func subscribeToMetadataUpdates() {
        // Use the client's subscriber mechanism to update CarPlay when metadata changes
        ACWebSocketClient.shared.addSubscriber { [weak self] status in
            self?.updateMPNowPlayingInfo(station: StationsManager.shared.currentStation)
        }
    }
}
