//
//  NetworkService.swift
//  SwiftRadio
//
//  Created by Fethi El Hassasna on 2025-01-31.
//  Copyright © 2025 matthewfecher.com. All rights reserved.
//

import UIKit

// MARK: - Error

enum NetworkError: Error {
    case urlNotValid, dataNotValid, dataNotFound, fileNotFound, httpResponseNotValid
}

// MARK: - GitHub Models

struct Contributor: Decodable {
    let login: String
    let avatarURL: URL
    let htmlURL: URL
    let contributions: Int

    enum CodingKeys: String, CodingKey {
        case login
        case avatarURL = "avatar_url"
        case htmlURL = "html_url"
        case contributions
    }
}

struct GitHubRepo: Decodable {
    let name: String
    let description: String?
}

// MARK: - NetworkService

struct NetworkService {

    // MARK: - Stations

    static func fetchStations() async throws -> [RadioStation] {
        let data: Data

        if Config.useLocalStations {
            guard let fileURL = Bundle.main.url(forResource: "stations", withExtension: "json") else {
                if Config.debugLog { print("The local JSON file could not be found") }
                throw NetworkError.fileNotFound
            }
            data = try Data(contentsOf: fileURL, options: .uncached)
        } else {
            guard let url = URL(string: Config.stationsURL) else {
                if Config.debugLog { print("stationsURL not a valid URL") }
                throw NetworkError.urlNotValid
            }

            let config = URLSessionConfiguration.default
            config.requestCachePolicy = .reloadIgnoringLocalCacheData
            let session = URLSession(configuration: config)

            let (responseData, response) = try await session.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
                if Config.debugLog { print("API: HTTP status code has unexpected value") }
                throw NetworkError.httpResponseNotValid
            }

            data = responseData
        }

        if Config.debugLog { print("Stations JSON Found") }

        let jsonDictionary = try JSONDecoder().decode([String: [RadioStation]].self, from: data)

        guard let stations = jsonDictionary["station"] else {
            throw NetworkError.dataNotValid
        }

        return stations
    }

    // MARK: - Images

    static func fetchImage(from url: URL) async -> UIImage? {
        let cache = URLCache.shared
        let request = URLRequest(url: url)

        if let data = cache.cachedResponse(for: request)?.data, let image = UIImage(data: data) {
            return image
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  200...299 ~= httpResponse.statusCode,
                  let image = UIImage(data: data) else {
                return nil
            }

            let cachedData = CachedURLResponse(response: httpResponse, data: data)
            cache.storeCachedResponse(cachedData, for: request)
            return image
        } catch {
            return nil
        }
    }

    // MARK: - GitHub API

    static func fetchContributors(owner: String, repo: String) async throws -> [Contributor] {
        guard let url = URL(string: "https://api.github.com/repos/\(owner)/\(repo)/contributors") else {
            throw NetworkError.urlNotValid
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw NetworkError.httpResponseNotValid
        }

        return try JSONDecoder().decode([Contributor].self, from: data)
    }

    static func fetchRepository(owner: String, repo: String) async throws -> GitHubRepo {
        guard let url = URL(string: "https://api.github.com/repos/\(owner)/\(repo)") else {
            throw NetworkError.urlNotValid
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw NetworkError.httpResponseNotValid
        }

        return try JSONDecoder().decode(GitHubRepo.self, from: data)
    }
}
