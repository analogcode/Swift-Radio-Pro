//
//  SystemRemoteCommandHandler.swift
//  SwiftRadioCore
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import MediaPlayer
import UIKit

/// Connects application command identifiers to MediaPlayer's system commands.
@MainActor final class SystemRemoteCommandHandler: RemoteCommandHandling {
    private let center = MPRemoteCommandCenter.shared()
    func setEnabled(_ enabled: Bool, for command: RemoteCommand) { systemCommand(command).isEnabled = enabled }
    func addTarget(for command: RemoteCommand, handler: @escaping @Sendable () -> MPRemoteCommandHandlerStatus) -> Any {
        // The wrapper must be explicitly @Sendable: inside a @MainActor type it would otherwise be
        // inferred main-actor-isolated, and MediaPlayer may invoke the target off the main thread.
        // That inferred isolation traps on the executor check before the controller can enqueue its
        // main-actor action; the handler itself reaches the main actor (RemoteCommandsController.accept).
        systemCommand(command).addTarget { @Sendable _ in handler() }
    }
    func removeTarget(_ token: Any, for command: RemoteCommand) { systemCommand(command).removeTarget(token) }
    func beginReceivingEvents() { UIApplication.shared.beginReceivingRemoteControlEvents() }

    private func systemCommand(_ command: RemoteCommand) -> MPRemoteCommand {
        switch command {
        case .play: center.playCommand
        case .pause: center.pauseCommand
        case .stop: center.stopCommand
        case .toggle: center.togglePlayPauseCommand
        case .next: center.nextTrackCommand
        case .previous: center.previousTrackCommand
        }
    }
}
