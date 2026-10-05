//
//  UITestRadioPlayer.swift
//  Swift Radio
//
//  Created on 2026-09-23.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

#if DEBUG
import Foundation
import SwiftRadioCore

/// Deterministic transport at the existing engine boundary, excluded from Release builds.
/// Catalog, stores, navigation, controls and vendor animation views remain production code.
@MainActor final class UITestRadioPlayer: RadioPlaying {
    private weak var observer: (any RadioPlayerEvents)?
    private var loadTask: Task<Void, Never>?
    private(set) var isPlaying = false
    private(set) var duration: TimeInterval?
    var currentMetadata: (artist: String?, track: String?)? {
        ("Swift Radio UI Test Artist", "A deliberately long now playing title to verify continuous marquee scrolling")
    }
    var radioURL: URL? {
        didSet {
            loadTask?.cancel()
            isPlaying = false
            duration = radioURL?.pathExtension == "mp3" ? 180 : 0
            guard radioURL != nil else { return }
            observer?.playerStateDidChange(.loading)
            loadTask = Task { [weak self] in
                try? await Task.sleep(for: .milliseconds(700))
                guard !Task.isCancelled, let self else { return }
                observer?.durationDidChange(duration ?? 0)
                observer?.metadataDidChange(artist: currentMetadata?.artist, track: currentMetadata?.track)
                observer?.playerStateDidChange(.readyToPlay)
                play()
            }
        }
    }
    func addObserver(_ observer: any RadioPlayerEvents) { self.observer = observer }
    func play() { isPlaying = true; observer?.playbackStateDidChange(.playing) }
    func pause() { isPlaying = false; observer?.playbackStateDidChange(.paused) }
    func stop() {
        loadTask?.cancel()
        isPlaying = false
        observer?.playbackStateDidChange(.stopped)
    }
    func togglePlaying() { isPlaying ? pause() : play() }
    func seek(to seconds: TimeInterval, completion: @escaping @MainActor @Sendable () -> Void) {
        // A stale time event before completion reproduces the AVPlayer seek race.
        observer?.playTimeDidChange(0, duration: duration ?? 0)
        Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(250))
            guard let self else { return }
            // FRadioPlayer 0.4 preserves transport; PlayerService owns resume-on-scrub.
            completion()
            observer?.playTimeDidChange(seconds, duration: duration ?? 0)
        }
    }
}
#endif
