//
//  StubURLProtocol.swift
//  SwiftRadioCoreTests
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import Foundation

/// Returns deterministic image/data responses based on URL paths, with no shared mutable state.
final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        guard let url = request.url else { return }
        if url.path == "/offline" {
            client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
            return
        }
        let status = url.path == "/missing" ? 404 : 200
        let data: Data
        if url.path == "/stations" || url.path == "/policy" {
            if url.path == "/policy" && request.cachePolicy != .reloadIgnoringLocalCacheData {
                client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
                return
            }
            data = try! Data(contentsOf: Bundle.module.url(forResource: "stations", withExtension: "json", subdirectory: "Fixtures")!)
        } else if url.path == "/invalid" {
            data = Data("not an image or JSON".utf8)
        } else {
            data = try! Data(contentsOf: Bundle.module.url(forResource: "station", withExtension: "png", subdirectory: "Fixtures")!)
        }
        client?.urlProtocol(self, didReceive: HTTPURLResponse(url: url, statusCode: status, httpVersion: nil,
                                                           headerFields: ["Cache-Control": "max-age=3600"])!, cacheStoragePolicy: .allowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
    static func session() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [Self.self]
        return URLSession(configuration: configuration)
    }
}
