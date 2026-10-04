//
//  ControlledStationsLoader.swift
//  SwiftRadioCoreTests
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

@testable import SwiftRadioCore

/// Allows overlapping loads to complete in an explicitly chosen order.
actor ControlledStationsLoader: StationsLoader {
    private var requests: [CheckedContinuation<[RadioStation], any Error>] = []
    private var waiters: [(Int, CheckedContinuation<Void, Never>)] = []
    func load() async throws -> [RadioStation] {
        try await withCheckedThrowingContinuation { continuation in
            requests.append(continuation)
            let ready = waiters.filter { $0.0 <= requests.count }
            waiters.removeAll { $0.0 <= requests.count }
            for (_, waiter) in ready { waiter.resume() }
        }
    }
    func waitForRequests(_ count: Int) async {
        if requests.count >= count { return }
        await withCheckedContinuation { waiters.append((count, $0)) }
    }
    func finish(_ index: Int, with stations: [RadioStation]) { requests[index].resume(returning: stations) }
}
