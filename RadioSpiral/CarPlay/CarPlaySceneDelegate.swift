//
//  CarPlaySceneDelegate.swift
//  RadioSpiral
//
//  Created on 2025-11-11.
//

import CarPlay
import MediaPlayer
import FRadioPlayer

/// CarPlay scene delegate for modern CarPlay framework (iOS 14+)
/// Handles CarPlay interface setup, station browsing, and playback
@objc public class CarPlaySceneDelegate: NSObject, CPTemplateApplicationSceneDelegate {

    // MARK: - Properties

    var interfaceController: CPInterfaceController?
    private var stationsListTemplate: CPListTemplate?

    // MARK: - CPTemplateApplicationSceneDelegate

    @objc public func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = interfaceController

        // Set up the stations list as the root template when CarPlay connects
        // The currently playing info is shown through MPNowPlayingInfoCenter (system media controls)
        let stationsTemplate = createStationsListTemplate()
        self.stationsListTemplate = stationsTemplate
        interfaceController.setRootTemplate(stationsTemplate, animated: false)
    }

    @objc public func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = nil
        self.stationsListTemplate = nil
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

        // Update now playing info for CarPlay display
        updateMPNowPlayingInfo(station: station)

        // Note: Audio playback is managed by the phone app's audio session
        // CarPlay UI just controls what's already playing on the phone

        // Dismiss the selection handler
        completionHandler()
    }

    /// Updates the MPNowPlayingInfoCenter for system integration
    private func updateMPNowPlayingInfo(station: RadioStation?) {
        var nowPlayingInfo = [String: Any]()

        if let station = station {
            nowPlayingInfo[MPMediaItemPropertyTitle] = station.name
        }

        let client = ACWebSocketClient.shared
        nowPlayingInfo[MPMediaItemPropertyArtist] = client.status.artist
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = client.status.track
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = 0 // Unknown for streaming

        if let station = station {
            station.getImage { image in
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
}
