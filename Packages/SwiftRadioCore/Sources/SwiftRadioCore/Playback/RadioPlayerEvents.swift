//
//  RadioPlayerEvents.swift
//  SwiftRadioCore
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import Foundation

/// Application-owned engine events, delivered synchronously on the main actor.
@MainActor public protocol RadioPlayerEvents: AnyObject {
    func playerStateDidChange(_ state: RadioPlayerState)
    func playbackStateDidChange(_ state: PlayerService.State)
    func metadataDidChange(artist: String?, track: String?)
    func artworkDidChange(_ url: URL?)
    func durationDidChange(_ duration: TimeInterval)
    func playTimeDidChange(_ elapsed: TimeInterval, duration: TimeInterval)
}
