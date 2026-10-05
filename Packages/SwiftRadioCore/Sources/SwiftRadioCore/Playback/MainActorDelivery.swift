//
//  MainActorDelivery.swift
//  SwiftRadioCore
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import Foundation

/// Delivers a vendor callback to the main actor without asserting where it came from.
///
/// The supported FRadioPlayer 0.4 engine already delivers on the main actor. This defensive
/// boundary also supports explicitly injected background events without an actor assertion.
/// Main-thread delivery stays synchronous and ordered with transport commands; other threads
/// hop before touching application state.
func deliverOnMainActor(_ body: @escaping @MainActor @Sendable () -> Void) {
    if Thread.isMainThread {
        MainActor.assumeIsolated { body() }
    } else {
        Task { @MainActor in body() }
    }
}
