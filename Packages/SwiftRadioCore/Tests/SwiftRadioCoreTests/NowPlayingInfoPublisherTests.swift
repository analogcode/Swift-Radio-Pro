//
//  NowPlayingInfoPublisherTests.swift
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

/// Verifies live/file transitions replace stale timing keys without global side effects.
@MainActor struct NowPlayingInfoPublisherTests {
    @Test func liveAndFileDictionaries() {
        var info: [String: Any] = [:]
        let publisher = NowPlayingInfoPublisher(publish: { info = $0 ?? [:] })
        publisher.update(title: "File", artist: "Artist", artwork: nil, isLive: false, elapsed: 42, duration: 180, rate: 0)
        #expect(info[MPMediaItemPropertyPlaybackDuration] as? Double == 180)
        #expect(info[MPNowPlayingInfoPropertyElapsedPlaybackTime] as? Double == 42)
        #expect(info[MPNowPlayingInfoPropertyPlaybackRate] as? Float == 0)
        publisher.update(title: "Live", artist: "Station", artwork: nil, isLive: true, elapsed: 0, duration: 0, rate: 1)
        #expect(info[MPNowPlayingInfoPropertyIsLiveStream] as? Bool == true)
        #expect(info[MPMediaItemPropertyPlaybackDuration] == nil)
        #expect(info[MPNowPlayingInfoPropertyElapsedPlaybackTime] == nil)
        publisher.update(title: "File", artist: "Artist", artwork: nil, isLive: false, elapsed: 0, duration: 90, rate: 1)
        #expect(info[MPNowPlayingInfoPropertyIsLiveStream] as? Bool == false)
        #expect(info[MPMediaItemPropertyPlaybackDuration] as? Double == 90)
    }

    @Test func clearRemovesSystemMetadata() {
        var info: [String: Any]?
        let publisher = NowPlayingInfoPublisher(publish: { info = $0 })
        publisher.update(title: "Station", artist: "Description", artwork: nil,
                         isLive: true, elapsed: 0, duration: 0, rate: 1)
        #expect(info != nil)
        publisher.clear()
        #expect(info == nil)
    }

    /// Each update publishes a whole new dictionary: nothing from the previous item may survive,
    /// or a live stream would keep a file's scrubber and a track without art would keep old art.
    @Test func everyUpdateReplacesTheWholeDictionary() throws {
        var info: [String: Any]?
        let publisher = NowPlayingInfoPublisher(publish: { info = $0 })
        let art = try #require(UIImage(named: "Fixtures/station", in: .module, compatibleWith: nil))
        publisher.update(title: "File", artist: "Artist", artwork: art, isLive: false, elapsed: 42, duration: 180, rate: 1)
        #expect(Set(try #require(info).keys) == [MPMediaItemPropertyTitle, MPMediaItemPropertyArtist,
                                                  MPNowPlayingInfoPropertyIsLiveStream, MPNowPlayingInfoPropertyPlaybackRate,
                                                  MPMediaItemPropertyArtwork, MPNowPlayingInfoPropertyElapsedPlaybackTime,
                                                  MPMediaItemPropertyPlaybackDuration])
        publisher.update(title: "Live", artist: "Station", artwork: nil, isLive: true, elapsed: 42, duration: 180, rate: 1)
        #expect(Set(try #require(info).keys) == [MPMediaItemPropertyTitle, MPMediaItemPropertyArtist,
                                                  MPNowPlayingInfoPropertyIsLiveStream, MPNowPlayingInfoPropertyPlaybackRate])
        #expect(info?[MPMediaItemPropertyTitle] as? String == "Live")
    }

    @Test func artworkIsReplacedNotKept() throws {
        var info: [String: Any]?
        let publisher = NowPlayingInfoPublisher(publish: { info = $0 })
        let station = try #require(UIImage(named: "Fixtures/station", in: .module, compatibleWith: nil))
        let track = try #require(UIImage(named: "Fixtures/placeholder", in: .module, compatibleWith: nil))
        publisher.update(title: "T", artist: "A", artwork: station, isLive: true, elapsed: 0, duration: 0, rate: 1)
        var artwork = try #require(info?[MPMediaItemPropertyArtwork] as? MPMediaItemArtwork)
        #expect(artwork.image(at: station.size) === station)
        publisher.update(title: "T", artist: "A", artwork: track, isLive: true, elapsed: 0, duration: 0, rate: 1)
        artwork = try #require(info?[MPMediaItemPropertyArtwork] as? MPMediaItemArtwork)
        #expect(artwork.image(at: track.size) === track)
        publisher.update(title: "T", artist: "A", artwork: nil, isLive: true, elapsed: 0, duration: 0, rate: 1)
        #expect(info?[MPMediaItemPropertyArtwork] == nil)
    }
}
