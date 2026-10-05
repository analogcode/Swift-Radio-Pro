//
//  AudioSessionConfigurator.swift
//  SwiftRadioCore
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import AVFAudio
import OSLog

/// Owns the playback category and activates the session only when audio is about to start.
public enum AudioSessionConfigurator {
    /// Only a non-mixable session can own lock-screen, Control Center and CarPlay Now Playing and
    /// receive headset buttons. Playback already supports AirPlay and Bluetooth A2DP;
    /// explicit allowAirPlay is only valid for playAndRecord and is rejected on devices.
    public static func categoryOptions(mixesWithOthers: Bool = false) -> AVAudioSession.CategoryOptions {
        var options: AVAudioSession.CategoryOptions = []
        if mixesWithOthers { options.insert(.mixWithOthers) }
        return options
    }

    /// Activating at launch or on scene activation would stop other apps' audio just by opening
    /// this one, so `PlayerService` awaits this before it lets the engine start. The category is
    /// re-applied every time because the vendor engine sets its own when it is created. The work
    /// runs off the main actor: `setActive(true)` blocks while the system arbitrates with other
    /// sessions. Failures are logged and rethrown so the player can report them.
    public static func activateForPlayback(mixesWithOthers: Bool = false) async throws {
        let options = categoryOptions(mixesWithOthers: mixesWithOthers)
        do {
            try await Task.detached(priority: .userInitiated) {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.playback, mode: .default, options: options)
                try session.setActive(true)
            }.value
        } catch {
            Logger(subsystem: "SwiftRadioCore", category: "AudioSession")
                .error("Audio activation failed: \(error.localizedDescription)")
            throw error
        }
    }
}
