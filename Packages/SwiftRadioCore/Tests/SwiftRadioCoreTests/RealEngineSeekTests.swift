//
//  RealEngineSeekTests.swift
//  SwiftRadioCoreTests
//
//  Created on 2026-10-03.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import XCTest
import FRadioPlayer
@testable import SwiftRadioCore

/// Exercises the production adapter with AVPlayer, including FRadioPlayer 0.4's independent seek.
@MainActor final class RealEngineSeekTests: XCTestCase {
    private var files: [URL] = []

    override func tearDown() async throws {
        FRadioPlayer.shared.radioURL = nil
        FRadioPlayer.shared.isAutoPlay = true
        for url in files { try? FileManager.default.removeItem(at: url) }
        files = []
    }

    private func audio() throws -> URL {
        let size = 20 * 8000 * 2
        var data = Data("RIFF".utf8)
        func append32(_ value: Int) {
            withUnsafeBytes(of: UInt32(value).littleEndian) { data.append(contentsOf: $0) }
        }
        func append16(_ value: Int) {
            withUnsafeBytes(of: UInt16(value).littleEndian) { data.append(contentsOf: $0) }
        }
        append32(36 + size)
        data.append(Data("WAVEfmt ".utf8)); append32(16)
        append16(1); append16(1); append32(8000); append32(16000); append16(2); append16(16)
        data.append(Data("data".utf8)); append32(size); data.append(Data(count: size))
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("seek-\(UUID()).wav")
        try data.write(to: url)
        files.append(url)
        return url
    }

    private func station(_ url: URL) -> RadioStation {
        RadioStation(name: url.lastPathComponent, streamURL: url.absoluteString, imageURL: "", desc: "Seek fixture")
    }

    private func waitUntil(_ predicate: () -> Bool) async -> Bool {
        let deadline = Date().addingTimeInterval(10)
        while !predicate(), Date() < deadline { try? await Task.sleep(for: .milliseconds(50)) }
        return predicate()
    }

    private func loadedService() async throws -> PlayerService {
        let url = try audio()
        let service = PlayerService(player: PlayerService.makeRadioPlayer(),
                                    nowPlaying: NowPlayingInfoPublisher(publish: { _ in }),
                                    remoteCommands: RemoteCommandsController(handler: FakeRemoteCommandHandler()),
                                    activateAudioSession: nil)
        service.updateStation(station(url))
        service.load(url: url)
        let ready = await waitUntil { service.duration > 0 && FRadioPlayer.shared.currentTime > 0 }
        XCTAssertTrue(ready, "The real engine must load and advance before testing seek")
        if !ready { throw NSError(domain: "RealEngineSeekTests", code: 1) }
        service.pause()
        return service
    }

    func testCurrentSeekResumesPausedRealEngine() async throws {
        let service = try await loadedService()
        defer { service.unload() }
        service.seek(to: 5)
        let resumed = await waitUntil {
            !service.isSeeking && service.state == .playing && (FRadioPlayer.shared.rate ?? 0) > 0
        }
        XCTAssertTrue(resumed)
        XCTAssertGreaterThanOrEqual(FRadioPlayer.shared.currentTime, 4.5)
    }

    func testPauseAndStopAfterRealSeekWin() async throws {
        for stop in [false, true] {
            let service = try await loadedService()
            service.seek(to: 5)
            if stop { service.stop() } else { service.pause() }
            try await Task.sleep(for: .milliseconds(500))
            XCTAssertEqual(service.state, stop ? .stopped : .paused)
            XCTAssertEqual(FRadioPlayer.shared.playbackState, stop ? .stopped : .paused)
            XCTAssertEqual(FRadioPlayer.shared.rate ?? 0, 0)
            XCTAssertFalse(service.isSeeking)
            service.unload()
        }
    }

    func testStationSwitchAndStopInvalidateRealSeek() async throws {
        let service = try await loadedService()
        defer { service.unload() }
        service.seek(to: 5)
        let next = try audio()
        service.updateStation(station(next))
        service.load(url: next)
        service.stop()
        try await Task.sleep(for: .milliseconds(500))
        XCTAssertEqual(FRadioPlayer.shared.radioURL, next)
        XCTAssertEqual(service.state, .stopped)
        XCTAssertEqual(FRadioPlayer.shared.playbackState, .stopped)
        XCTAssertEqual(FRadioPlayer.shared.rate ?? 0, 0)
        XCTAssertFalse(service.isSeeking)
    }
}
