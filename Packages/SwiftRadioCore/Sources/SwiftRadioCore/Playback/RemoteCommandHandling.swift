//
//  RemoteCommandHandling.swift
//  SwiftRadioCore
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import MediaPlayer

/// Allows remote registration to be tested without changing the system command center.
@MainActor protocol RemoteCommandHandling: AnyObject {
    func setEnabled(_ enabled: Bool, for command: RemoteCommand)
    func addTarget(for command: RemoteCommand, handler: @escaping @Sendable () -> MPRemoteCommandHandlerStatus) -> Any
    func removeTarget(_ token: Any, for command: RemoteCommand)
    func beginReceivingEvents()
}
