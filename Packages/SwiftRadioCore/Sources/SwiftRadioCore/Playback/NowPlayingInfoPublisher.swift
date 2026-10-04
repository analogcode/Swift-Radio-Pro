//
//  NowPlayingInfoPublisher.swift
//  SwiftRadioCore
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import MediaPlayer
import UIKit

/// Replaces lock-screen metadata atomically, removing stale live/file timing keys.
@MainActor public final class NowPlayingInfoPublisher {
    private let publish: @MainActor ([String: Any]?) -> Void

    public convenience init() {
        self.init(publish: { MPNowPlayingInfoCenter.default().nowPlayingInfo = $0 })
    }

    init(publish: @escaping @MainActor ([String: Any]?) -> Void) { self.publish = publish }

    /// Removes the system media session instead of leaving an empty lock-screen card.
    public func clear() { publish(nil) }

    public func update(title: String, artist: String, artwork: UIImage?, isLive: Bool,
                       elapsed: TimeInterval, duration: TimeInterval, rate: Float) {
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: title,
            MPMediaItemPropertyArtist: artist,
            MPNowPlayingInfoPropertyIsLiveStream: isLive,
            MPNowPlayingInfoPropertyPlaybackRate: rate
        ]
        if let artwork {
            info[MPMediaItemPropertyArtwork] = // MediaPlayer calls this handler on its own queue: keep it nonisolated (@Sendable) and
            // capture only the Sendable UIImage.
            MPMediaItemArtwork(boundsSize: artwork.size) { @Sendable _ in artwork }
        }
        if !isLive {
            info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsed
            info[MPMediaItemPropertyPlaybackDuration] = duration
        }
        publish(info)
    }
}
