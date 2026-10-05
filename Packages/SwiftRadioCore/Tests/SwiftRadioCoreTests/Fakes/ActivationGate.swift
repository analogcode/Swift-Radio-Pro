//
//  ActivationGate.swift
//  SwiftRadioCoreTests
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import Foundation
import Testing

/// Stands in for audio-session activation and holds each request until the test releases or
/// fails it, so the window between a transport command and an active session is observable.
@MainActor final class ActivationGate {
    struct Failure: Error {}

    private(set) var requests = 0
    private var waiting: [CheckedContinuation<Void, any Error>] = []
    var pendingCount: Int { waiting.count }

    func activate() async throws {
        requests += 1
        try await withCheckedThrowingContinuation { waiting.append($0) }
    }

    func release() { waiting.removeFirst().resume() }
    func fail() { waiting.removeFirst().resume(throwing: Failure()) }

    /// Yields until `count` requests are waiting; activation starts on a later main-actor turn.
    func waitForPending(_ count: Int, sourceLocation: SourceLocation = #_sourceLocation) async {
        var turns = 0
        while waiting.count < count, turns < 10_000 { await Task.yield(); turns += 1 }
        #expect(waiting.count == count, sourceLocation: sourceLocation)
    }
}
