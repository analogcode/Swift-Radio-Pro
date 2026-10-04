//
//  RadioPlaying.swift
//  SwiftRadioCore
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import Foundation

/// The main-actor transport and event registration boundary implemented by engines and test fakes.
@MainActor public protocol RadioPlaying: AnyObject {
    var radioURL: URL? { get set }
    var isPlaying: Bool { get }
    var duration: TimeInterval? { get }
    var currentMetadata: (artist: String?, track: String?)? { get }
    func play()
    func pause()
    func stop()
    func togglePlaying()
    func seek(to seconds: TimeInterval, completion: @escaping @MainActor @Sendable () -> Void)
    func addObserver(_ observer: any RadioPlayerEvents)
}
