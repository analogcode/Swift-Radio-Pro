//
//  GitHubClient.swift
//  Swift Radio
//
//  Created by Fethi El Hassasna on 2026-09-07.
//
//  SPDX-License-Identifier: MIT
//  See LICENSE in the repository root.
//

import Foundation

/// Async, `Sendable` client for the subset of the GitHub REST API the About
/// flow needs: repository metadata and the contributor list.
struct GitHubClient: Sendable {

    private let baseURL = "https://api.github.com"

    // MARK: - DTOs

    // GitHub's keys are snake_case. `.convertFromSnakeCase` would produce `htmlUrl`/`avatarUrl`,
    // never the acronym-cased properties below, so every response would throw `keyNotFound`.
    // Explicit CodingKeys with the default strategy is the documented way around that limitation.

    /// Repository metadata from `GET /repos/{owner}/{name}`.
    struct Repository: Decodable, Sendable {
        let name: String
        let description: String?
        let htmlURL: URL
        let owner: Owner

        private enum CodingKeys: String, CodingKey {
            case name, description, owner
            case htmlURL = "html_url"
        }
    }

    /// Repository owner (user or organization).
    struct Owner: Decodable, Sendable {
        let login: String
        let htmlURL: URL

        private enum CodingKeys: String, CodingKey {
            case login
            case htmlURL = "html_url"
        }
    }

    /// One entry from `GET /repos/{owner}/{name}/contributors`.
    struct Contributor: Decodable, Identifiable, Sendable {
        let id: Int
        let login: String
        let avatarURL: URL
        let htmlURL: URL
        let contributions: Int

        private enum CodingKeys: String, CodingKey {
            case id, login, contributions
            case avatarURL = "avatar_url"
            case htmlURL = "html_url"
        }
    }

    /// Errors surfaced by the client; callers degrade gracefully on `throw`.
    enum ClientError: Error {
        case badURL
        case badResponse(Int)
    }

    // MARK: - Endpoints

    /// Fetches metadata for a repository.
    func repository(owner: String, name: String) async throws -> Repository {
        try await fetch("\(baseURL)/repos/\(owner)/\(name)")
    }

    /// Fetches contributors for a repository (first page, GitHub's default ordering).
    func contributors(owner: String, name: String) async throws -> [Contributor] {
        try await fetch("\(baseURL)/repos/\(owner)/\(name)/contributors")
    }

    // MARK: - Private

    private func fetch<T: Decodable>(_ urlString: String) async throws -> T {
        guard let url = URL(string: urlString) else {
            throw ClientError.badURL
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw ClientError.badResponse(http.statusCode)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}
