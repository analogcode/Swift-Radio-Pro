//
//  PlayerArtworkTests.swift
//  SwiftRadioCoreTests
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import MediaPlayer
import Testing
import UIKit
@testable import SwiftRadioCore

/// Prevents late artwork and removed selections from leaving stale lock-screen content.
@MainActor struct PlayerArtworkTests {
    @Test func identityGuardsAndImmediateStationFallback() throws {
        var info: [String: Any]? = [:]
        let engine = FakeRadioPlayer()
        let service = PlayerService(player: engine, nowPlaying: NowPlayingInfoPublisher(publish: { info = $0 }),
                                    remoteCommands: RemoteCommandsController(handler: FakeRemoteCommandHandler()),
                                    activateAudioSession: nil)
        let stations = try RadioStationTests.fixtures()
        let stationArt = try #require(UIImage(named: "Fixtures/station", in: .module, compatibleWith: nil))
        let trackArt = try #require(UIImage(named: "Fixtures/placeholder", in: .module, compatibleWith: nil))
        let firstURL = URL(string: "https://example.com/first")!
        let secondURL = URL(string: "https://example.com/second")!
        service.updateStation(stations[1])
        service.load(url: URL(string: stations[1].streamURL)!)
        service.updateArtwork(stationArt, for: stations[0].id, artworkURL: nil)
        #expect(info?[MPMediaItemPropertyArtwork] == nil)
        service.updateArtwork(stationArt, for: stations[1].id, artworkURL: nil)
        engine.observer?.metadataDidChange(artist: "Artist", track: "Track") // A lookup needs a track.
        engine.observer?.artworkDidChange(secondURL)
        service.updateArtwork(trackArt, for: stations[1].id, artworkURL: firstURL)
        var artwork = try #require(info?[MPMediaItemPropertyArtwork] as? MPMediaItemArtwork)
        #expect(artwork.bounds.size == stationArt.size)
        service.updateArtwork(trackArt, for: stations[1].id, artworkURL: secondURL)
        artwork = try #require(info?[MPMediaItemPropertyArtwork] as? MPMediaItemArtwork)
        #expect(artwork.bounds.size == trackArt.size)
        engine.observer?.artworkDidChange(nil)
        artwork = try #require(info?[MPMediaItemPropertyArtwork] as? MPMediaItemArtwork)
        #expect(artwork.bounds.size == stationArt.size)
        engine.observer?.metadataDidChange(artist: "Old Artist", track: "Old Track")
        service.stop()
        service.updateStation(nil)
        // nil removes the system media session; an empty dictionary would leave a blank card.
        #expect(info == nil)
        engine.observer?.metadataDidChange(artist: "Late Artist", track: "Late Track")
        #expect(info == nil, "A late engine callback must not recreate a removed lock-screen session")
    }

    /// Inject a stale event despite the supported engine's lookup-generation guard. The app's
    /// station/metadata identity checks must also prevent station A's cover from landing on B.
    @Test func lateVendorArtworkAfterAStationSwitchIsDropped() throws {
        var info: [String: Any]?
        let engine = FakeRadioPlayer(fidelity: .vendor)
        let service = PlayerService(player: engine, nowPlaying: NowPlayingInfoPublisher(publish: { info = $0 }),
                                    remoteCommands: RemoteCommandsController(handler: FakeRemoteCommandHandler()),
                                    activateAudioSession: nil)
        let stations = try RadioStationTests.fixtures()
        let stationArt = try #require(UIImage(named: "Fixtures/station", in: .module, compatibleWith: nil))
        let trackArt = try #require(UIImage(named: "Fixtures/placeholder", in: .module, compatibleWith: nil))
        let lateURL = URL(string: "https://example.com/a-cover")!
        let currentURL = URL(string: "https://example.com/b-cover")!
        service.updateStation(stations[0])
        service.load(url: URL(string: stations[0].streamURL)!)
        engine.observer?.metadataDidChange(artist: "A Artist", track: "A Track") // Starts A's lookup.

        service.updateStation(stations[1])
        service.load(url: URL(string: stations[1].streamURL)!)
        service.updateArtwork(stationArt, for: stations[1].id, artworkURL: nil)
        engine.observer?.artworkDidChange(lateURL) // A's lookup answers after the switch.
        #expect(service.artworkURL == nil)
        service.updateArtwork(trackArt, for: stations[1].id, artworkURL: lateURL)
        var artwork = try #require(info?[MPMediaItemPropertyArtwork] as? MPMediaItemArtwork)
        #expect(artwork.bounds.size == stationArt.size)

        engine.observer?.metadataDidChange(artist: "B Artist", track: "B Track")
        engine.observer?.artworkDidChange(currentURL)
        #expect(service.artworkURL == currentURL)
        service.updateArtwork(trackArt, for: stations[1].id, artworkURL: currentURL)
        artwork = try #require(info?[MPMediaItemPropertyArtwork] as? MPMediaItemArtwork)
        #expect(artwork.bounds.size == trackArt.size)
    }

    /// Accepted artwork belongs to the station that was current when it arrived, even if a new
    /// selection has not replaced the track metadata yet.
    @Test func acceptedArtworkIsKeyedToItsStation() throws {
        var info: [String: Any]?
        let engine = FakeRadioPlayer()
        let service = PlayerService(player: engine, nowPlaying: NowPlayingInfoPublisher(publish: { info = $0 }),
                                    remoteCommands: RemoteCommandsController(handler: FakeRemoteCommandHandler()),
                                    activateAudioSession: nil)
        let stations = try RadioStationTests.fixtures()
        let stationArt = try #require(UIImage(named: "Fixtures/station", in: .module, compatibleWith: nil))
        let trackArt = try #require(UIImage(named: "Fixtures/placeholder", in: .module, compatibleWith: nil))
        let url = URL(string: "https://example.com/a-cover")!
        service.updateStation(stations[0])
        engine.observer?.metadataDidChange(artist: "A Artist", track: "A Track")
        engine.observer?.artworkDidChange(url)
        service.updateStation(stations[1]) // Selection moved; B's load has not cleared A's track yet.
        service.updateArtwork(stationArt, for: stations[1].id, artworkURL: nil)
        service.updateArtwork(trackArt, for: stations[1].id, artworkURL: url)
        let artwork = try #require(info?[MPMediaItemPropertyArtwork] as? MPMediaItemArtwork)
        #expect(artwork.bounds.size == stationArt.size)
    }
}
