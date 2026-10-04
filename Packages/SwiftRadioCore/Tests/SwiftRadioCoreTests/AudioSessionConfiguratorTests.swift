//
//  AudioSessionConfiguratorTests.swift
//  SwiftRadioCoreTests
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import AVFAudio
import Testing
@testable import SwiftRadioCore

/// Guards the category options that decide whether the app can own Now Playing.
struct AudioSessionConfiguratorTests {
    @Test func playbackCategoryIsNonMixableByDefault() {
        let options = AudioSessionConfigurator.categoryOptions()
        #expect(!options.contains(.mixWithOthers))
        // Playback supports these routes implicitly; allowAirPlay is invalid for this category.
        #expect(options.isEmpty)
    }

    @Test func mixingIsAnExplicitOptIn() {
        let options = AudioSessionConfigurator.categoryOptions(mixesWithOthers: true)
        #expect(options.contains(.mixWithOthers))
        #expect(options == [.mixWithOthers])
    }
}
