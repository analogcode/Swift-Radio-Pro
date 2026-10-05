//
//  FakeRemoteCommandHandler.swift
//  SwiftRadioCoreTests
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import MediaPlayer
@testable import SwiftRadioCore

/// Exercises registration and enablement without the process-wide command center.
@MainActor final class FakeRemoteCommandHandler: RemoteCommandHandling {
    var enabled: [RemoteCommand: Bool] = [:]
    var handlers: [RemoteCommand: @Sendable () -> MPRemoteCommandHandlerStatus] = [:]
    var removedCount = 0
    var beginCount = 0
    func setEnabled(_ enabled: Bool, for command: RemoteCommand) { self.enabled[command] = enabled }
    func addTarget(for command: RemoteCommand, handler: @escaping @Sendable () -> MPRemoteCommandHandlerStatus) -> Any {
        handlers[command] = handler
        return command
    }
    func removeTarget(_ token: Any, for command: RemoteCommand) {
        handlers[command] = nil
        removedCount += 1
    }
    func beginReceivingEvents() { beginCount += 1 }
}
