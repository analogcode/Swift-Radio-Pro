//
//  RemoteCommandsController.swift
//  SwiftRadioCore
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import MediaPlayer

/// Owns remote command registrations and runs their actions on the main actor, reporting each
/// action's real status to the system.
@MainActor public final class RemoteCommandsController {
    private let handler: any RemoteCommandHandling
    private var isLive = false
    private var tokens: [(RemoteCommand, Any)] = []

    public convenience init() { self.init(handler: SystemRemoteCommandHandler()) }

    init(handler: any RemoteCommandHandling) {
        self.handler = handler
        handler.setEnabled(true, for: .pause)
        handler.setEnabled(false, for: .stop)
    }

    isolated deinit { unbind() }

    /// Wires the six commands to the shared player and catalog. Without a selection every command
    /// reports that there is nothing to act on instead of starting the radio from nothing, which
    /// matches UIKit's `setNext`/`setPrevious` ignoring a missing current station. Next/Previous
    /// with no other usable station report `.noSuchContent` rather than claiming a change.
    public func bind(player: PlayerService, stations: StationsStore) {
        func whenSelected(_ action: @escaping @MainActor @Sendable (PlayerService, StationsStore) -> Bool)
            -> @MainActor @Sendable () -> MPRemoteCommandHandlerStatus {
            { [weak player, weak stations] in
                guard let player, let stations, stations.currentStation != nil else { return .noActionableNowPlayingItem }
                return action(player, stations) ? .success : .noSuchContent
            }
        }
        bind(play: whenSelected { player, _ in player.play(); return true },
             pause: whenSelected { player, _ in player.pause(); return true },
             stop: whenSelected { player, _ in player.stop(); return true },
             toggle: whenSelected { player, _ in player.togglePlayPause(); return true },
             next: whenSelected { _, stations in stations.selectNext() },
             previous: whenSelected { _, stations in stations.selectPrevious() })
    }

    /// Custom wiring: each action's return value is the status reported to the system.
    public func bind(play: @escaping @MainActor @Sendable () -> MPRemoteCommandHandlerStatus,
                     pause: @escaping @MainActor @Sendable () -> MPRemoteCommandHandlerStatus,
                     stop: @escaping @MainActor @Sendable () -> MPRemoteCommandHandlerStatus,
                     toggle: @escaping @MainActor @Sendable () -> MPRemoteCommandHandlerStatus,
                     next: @escaping @MainActor @Sendable () -> MPRemoteCommandHandlerStatus,
                     previous: @escaping @MainActor @Sendable () -> MPRemoteCommandHandlerStatus) {
        unbind()
        let actions = [play, pause, stop, toggle, next, previous]
        for (command, action) in zip(RemoteCommand.allCases, actions) {
            let token = handler.addTarget(for: command) { Self.accept(action) }
            tokens.append((command, token))
            handler.setEnabled(command != .stop, for: command)
        }
        updateLiveState(isLive: isLive)
        handler.beginReceivingEvents()
    }

    public func unbind() {
        for (command, token) in tokens { handler.removeTarget(token, for: command) }
        tokens.removeAll()
    }

    public func updateLiveState(isLive: Bool) {
        self.isLive = isLive
        handler.setEnabled(!isLive, for: .pause)
        handler.setEnabled(isLive, for: .stop)
    }

    /// MediaPlayer calls targets on the main thread in practice, where the action runs inline. On
    /// any other thread the callback blocks on `DispatchQueue.main.sync` for the real status. That
    /// cannot deadlock: nothing on the main actor ever waits for a MediaPlayer callback queue, and
    /// the actions only touch main-actor state (session activation is awaited asynchronously).
    nonisolated private static func accept(_ action: @escaping @MainActor @Sendable () -> MPRemoteCommandHandlerStatus)
        -> MPRemoteCommandHandlerStatus {
        if Thread.isMainThread { return MainActor.assumeIsolated { action() } }
        return DispatchQueue.main.sync { MainActor.assumeIsolated { action() } }
    }
}
