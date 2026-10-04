//
//  FakeRadioPlayer.swift
//  SwiftRadioCoreTests
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import Foundation
@testable import SwiftRadioCore

/// Records transport commands and exposes all six application-owned event callbacks.
///
/// `.recording` only records calls. `.vendor` also reproduces what FRadioPlayer 0.4.0 does
/// synchronously inside those calls, so ordering bugs show up against the real engine's shape:
/// - `play`/`pause`/`stop` emit `playbackStateDidChange` re-entrantly, only when the value changes,
///   and do nothing without a stream (the vendor has no `AVPlayer` until `radioURL` is set);
/// - setting `radioURL` stops the old item, resets the duration and autoplays the new one;
/// - `stop()` on a live stream clears the metadata;
/// - `seek` preserves transport and always completes on the main actor, including with no duration;
/// - interruption resumption requires a prior playing intent and no intervening user command.
/// Automatic vendor seek completions are asynchronous; pending completions are test-controlled.
@MainActor final class FakeRadioPlayer: RadioPlaying {
    enum Fidelity: CaseIterable, Sendable { case recording, vendor }

    let fidelity: Fidelity
    var radioURL: URL? {
        didSet {
            loadedURLs.append(radioURL)
            guard fidelity == .vendor else { return }
            if hasStream { stop() }
            hasStream = radioURL != nil
            if (duration ?? 0) != 0 { announceDuration(0) }
            if radioURL == nil {
                observer?.playerStateDidChange(.urlNotSet)
            } else {
                observer?.playerStateDidChange(.loading)
                play() // The production adapter turns on isAutoPlay.
            }
        }
    }
    var isPlaying = false
    var duration: TimeInterval?
    var currentMetadata: (artist: String?, track: String?)?
    weak var observer: (any RadioPlayerEvents)?
    private(set) var calls: [String] = []
    /// Every `radioURL` assignment, including a test's own sentinel writes.
    private(set) var loadedURLs: [URL?] = []
    private(set) var soughtTime: TimeInterval?
    var completesSeeksImmediately = true
    var pendingSeeks: [@MainActor @Sendable () -> Void] = []
    private var playbackState: PlayerService.State = .stopped
    /// The vendor's `AVPlayer` exists from a non-nil `radioURL` until the next reset.
    private var hasStream = false
    private var resumeAfterInterruption: Bool?

    init(fidelity: Fidelity = .recording) { self.fidelity = fidelity }

    func play() {
        resumeAfterInterruption = nil
        calls.append("play")
        guard fidelity == .vendor else { isPlaying = true; return }
        guard hasStream else { return }
        setPlaybackState(.playing)
    }
    func pause() {
        resumeAfterInterruption = nil
        calls.append("pause")
        guard fidelity == .vendor else { isPlaying = false; return }
        guard hasStream else { return }
        setPlaybackState(.paused)
    }
    func stop() {
        resumeAfterInterruption = nil
        calls.append("stop")
        guard fidelity == .vendor else { isPlaying = false; return }
        guard hasStream else { return }
        if (duration ?? 0) == 0 { observer?.metadataDidChange(artist: nil, track: nil) }
        setPlaybackState(.stopped)
    }
    func togglePlaying() { calls.append("toggle"); isPlaying.toggle() }
    func seek(to seconds: TimeInterval, completion: @escaping @MainActor @Sendable () -> Void) {
        if fidelity == .recording || (duration ?? 0) > 0 { soughtTime = seconds }
        if completesSeeksImmediately {
            if fidelity == .vendor { Task { @MainActor in completion() } }
            else { completion() }
        } else {
            pendingSeeks.append(completion)
        }
    }
    func addObserver(_ observer: any RadioPlayerEvents) { self.observer = observer }

    /// The vendor's duration setter: stores the value and notifies only when it changed.
    func announceDuration(_ value: TimeInterval) {
        guard fidelity == .recording || value != (duration ?? 0) else { return }
        duration = value
        observer?.durationDidChange(value)
    }

    // FRadioPlayer 0.4 handles session notifications and preserves transport intent.
    // The app observes the resulting playback-state events.
    func interruptionBegan() {
        let resume = resumeAfterInterruption ?? isPlaying
        pause()
        resumeAfterInterruption = resume
    }
    func interruptionEnded(shouldResume: Bool) {
        guard let resume = resumeAfterInterruption else { return }
        resumeAfterInterruption = nil
        if shouldResume, resume { play() } else { pause() }
    }
    /// `.oldDeviceUnavailable` (headphones unplugged, car disconnected) pauses.
    func previousOutputBecameUnavailable() { pause() }

    private func setPlaybackState(_ state: PlayerService.State) {
        isPlaying = state == .playing
        guard state != playbackState else { return }
        playbackState = state
        observer?.playbackStateDidChange(state)
    }

    /// Injects an adversarial off-main event through the adapter's defensive delivery helper.
    /// This does not model the supported engine's guaranteed main-actor delivery. It
    /// resumes once the main-actor observer has been updated. Returns whether it really ran
    /// off-main, so the test cannot silently pass on the synchronous path.
    nonisolated func emitPlaybackStateFromBackground(_ state: PlayerService.State) async -> Bool {
        await withCheckedContinuation { continuation in
            DispatchQueue.global().async { [weak self] in
                let wasOffMain = !Thread.isMainThread
                deliverOnMainActor {
                    self?.observer?.playbackStateDidChange(state)
                    continuation.resume(returning: wasOffMain)
                }
            }
        }
    }
}
