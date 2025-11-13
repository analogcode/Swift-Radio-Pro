//
//  ConfigClient.swift
//  RadioSpiral
//
//  Created on 2025-11-12.
//  Provides dynamic station configuration from Azuracast API with fallback support
//

import UIKit

/// Portable station data structure from configuration sources
/// Can be converted to RadioStation using RadioStation.from(configStation:)
public struct StationConfig: Codable {
    public let name: String
    public let streamURL: String
    public let imageURL: String
    public let desc: String
    public let longDesc: String
    public let serverName: String
    public let shortCode: String
    public let defaultDJ: String
}

/// Client for fetching server configuration and stations
/// Supports multiple config sources: primary Azuracast, fallback Azuracast, static JSON
/// Returns portable StationConfig objects
class ConfigClient {
    static let shared = ConfigClient()

    private let configURL: String
    private let apiKey: String?
    private var cachedStations: [StationConfig] = []

    init(configURL: String = "https://raw.githubusercontent.com/joemcmahon/radiospiral-config/master/config.json", apiKey: String? = nil) {
        self.configURL = configURL
        self.apiKey = apiKey
    }

    /// Fetch stations from configured sources in order
    /// Tries each config in sequence until one succeeds
    /// Returns portable StationConfig objects
    func fetchStations(completion: @escaping (Result<[StationConfig], Error>) -> Void) {
        fetchServerConfig { [weak self] configResult in
            switch configResult {
            case .success(let configs):
                self?.tryConfigsInOrder(configs, index: 0, completion: completion)
            case .failure:
                // If we can't fetch config, try cached stations
                if let cached = self?.cachedStations, !cached.isEmpty {
                    completion(.success(cached))
                } else {
                    completion(.failure(DataError.dataNotFound))
                }
            }
        }
    }

    /// Get station info by short code (for metadata fallback)
    /// Returns station data when metadata server is unavailable
    func getStationInfo(byShortCode shortCode: String) -> StationConfig? {
        return cachedStations.first { $0.shortCode == shortCode }
    }

    // MARK: - Private Methods

    private func fetchServerConfig(completion: @escaping (Result<[ConfigSource], Error>) -> Void) {
        guard let url = URL(string: configURL) else {
            completion(.failure(DataError.urlNotValid))
            return
        }

        // Handle file:// URLs directly (for tests and bundled configs)
        if url.scheme == "file" {
            do {
                let data = try Data(contentsOf: url)
                let configWrapper = try JSONDecoder().decode(ConfigWrapper.self, from: data)
                if Config.debugLog { print("ConfigClient: Server config loaded from file with \(configWrapper.configs.count) sources") }
                completion(.success(configWrapper.configs))
            } catch {
                if Config.debugLog { print("ConfigClient: Failed to load file config: \(error)") }
                completion(.failure(error))
            }
            return
        }

        // Handle HTTP/HTTPS URLs with URLSession
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.timeoutIntervalForRequest = 10

        let session = URLSession(configuration: config)
        let task = session.dataTask(with: url) { data, response, error in
            if let error = error {
                if Config.debugLog { print("ConfigClient: Failed to fetch server config: \(error)") }
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
                if Config.debugLog { print("ConfigClient: Invalid HTTP response") }
                completion(.failure(DataError.httpResponseNotValid))
                return
            }

            guard let data = data else {
                completion(.failure(DataError.dataNotFound))
                return
            }

            do {
                let configWrapper = try JSONDecoder().decode(ConfigWrapper.self, from: data)
                if Config.debugLog { print("ConfigClient: Server config fetched with \(configWrapper.configs.count) sources") }
                completion(.success(configWrapper.configs))
            } catch {
                if Config.debugLog { print("ConfigClient: Failed to decode config: \(error)") }
                completion(.failure(error))
            }
        }

        task.resume()
    }

    private func tryConfigsInOrder(_ configs: [ConfigSource], index: Int, completion: @escaping (Result<[StationConfig], Error>) -> Void) {
        guard index < configs.count else {
            // Tried all configs, fall back to cached if available
            if !cachedStations.isEmpty {
                completion(.success(cachedStations))
            } else {
                completion(.failure(DataError.dataNotFound))
            }
            return
        }

        let config = configs[index]

        switch config.format {
        case .azuracast:
            tryAzuracastConfig(config, completion: { [weak self] result in
                switch result {
                case .success(let stations):
                    self?.cachedStations = stations
                    completion(.success(stations))
                case .failure:
                    if Config.debugLog { print("ConfigClient: Azuracast config \(index) failed, trying next...") }
                    self?.tryConfigsInOrder(configs, index: index + 1, completion: completion)
                }
            })

        case .static:
            tryStaticConfig(config, completion: { [weak self] result in
                switch result {
                case .success(let stations):
                    self?.cachedStations = stations
                    completion(.success(stations))
                case .failure:
                    if Config.debugLog { print("ConfigClient: Static config \(index) failed, trying next...") }
                    self?.tryConfigsInOrder(configs, index: index + 1, completion: completion)
                }
            })
        }
    }

    private func tryAzuracastConfig(
        _ config: ConfigSource,
        completion: @escaping (Result<[StationConfig], Error>) -> Void
    ) {
        guard let server = config.server else {
            completion(.failure(DataError.dataNotValid))
            return
        }

        // Try public API first (no authentication required)
        tryPublicAzuracastAPI(server: server, exclude: config.exclude ?? []) { [weak self] result in
            switch result {
            case .success(let stations):
                if Config.debugLog { print("ConfigClient: Fetched \(stations.count) stations from public Azuracast API") }
                completion(.success(stations))
            case .failure:
                // Fall back to admin API if public API fails
                if Config.debugLog { print("ConfigClient: Public API failed, trying admin API...") }
                self?.tryAdminAzuracastAPI(server: server, exclude: config.exclude ?? [], completion: completion)
            }
        }
    }

    private func tryPublicAzuracastAPI(
        server: String,
        exclude: [String],
        completion: @escaping (Result<[StationConfig], Error>) -> Void
    ) {
        let urlString = "https://\(server)/api/stations"

        guard let url = URL(string: urlString) else {
            completion(.failure(DataError.urlNotValid))
            return
        }

        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.requestCachePolicy = .reloadIgnoringLocalCacheData
        sessionConfig.timeoutIntervalForRequest = 10

        let session = URLSession(configuration: sessionConfig)
        let task = session.dataTask(with: url) { data, response, error in
            if let error = error {
                if Config.debugLog { print("ConfigClient: Public API request failed: \(error)") }
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
                if Config.debugLog {
                    if let httpResponse = response as? HTTPURLResponse {
                        print("ConfigClient: HTTP \(httpResponse.statusCode) from public API")
                    }
                }
                completion(.failure(DataError.httpResponseNotValid))
                return
            }

            guard let data = data else {
                completion(.failure(DataError.dataNotFound))
                return
            }

            do {
                let publicStations = try JSONDecoder().decode([PublicAzuracastStation].self, from: data)
                let filtered = publicStations.filter { !exclude.contains($0.shortcode) }

                // If all stations are excluded, treat as failure to try next config
                guard !filtered.isEmpty else {
                    if Config.debugLog { print("ConfigClient: All stations excluded from public API") }
                    completion(.failure(DataError.dataNotFound))
                    return
                }

                let stationConfigs = filtered.map { self.convertFromPublicAzuracastStation($0, serverDomain: server) }
                completion(.success(stationConfigs))
            } catch {
                if Config.debugLog { print("ConfigClient: Failed to decode public API response: \(error)") }
                completion(.failure(error))
            }
        }

        task.resume()
    }

    private func tryAdminAzuracastAPI(
        server: String,
        exclude: [String],
        completion: @escaping (Result<[StationConfig], Error>) -> Void
    ) {
        let urlString = "https://\(server)/api/admin/stations"

        guard let url = URL(string: urlString) else {
            completion(.failure(DataError.urlNotValid))
            return
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10

        // Add API key authentication if provided
        if let apiKey = apiKey {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.requestCachePolicy = .reloadIgnoringLocalCacheData
        sessionConfig.timeoutIntervalForRequest = 10

        let session = URLSession(configuration: sessionConfig)
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                if Config.debugLog { print("ConfigClient: Admin API request failed: \(error)") }
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
                if Config.debugLog {
                    if let httpResponse = response as? HTTPURLResponse {
                        print("ConfigClient: HTTP \(httpResponse.statusCode) from admin API")
                    }
                }
                completion(.failure(DataError.httpResponseNotValid))
                return
            }

            guard let data = data else {
                completion(.failure(DataError.dataNotFound))
                return
            }

            do {
                let azuracastStations = try JSONDecoder().decode([AzuracastStation].self, from: data)
                let filtered = azuracastStations.filter { !exclude.contains($0.id) }

                // If all stations are excluded, treat as failure to try next config
                guard !filtered.isEmpty else {
                    if Config.debugLog { print("ConfigClient: All stations excluded from admin API") }
                    completion(.failure(DataError.dataNotFound))
                    return
                }

                let stationConfigs = filtered.map { self.convertToStationConfig($0, serverDomain: server) }
                completion(.success(stationConfigs))
            } catch {
                if Config.debugLog { print("ConfigClient: Failed to decode admin API response: \(error)") }
                completion(.failure(error))
            }
        }

        task.resume()
    }

    private func tryStaticConfig(
        _ config: ConfigSource,
        completion: @escaping (Result<[StationConfig], Error>) -> Void
    ) {
        let stations = config.safeStations
        guard !stations.isEmpty else {
            completion(.failure(DataError.dataNotValid))
            return
        }

        if Config.debugLog { print("ConfigClient: Loaded \(stations.count) stations from static config") }
        completion(.success(stations))
    }

    private func convertToStationConfig(_ azStation: AzuracastStation, serverDomain: String) -> StationConfig {
        return StationConfig(
            name: azStation.name,
            streamURL: "https://\(serverDomain)/radio/\(azStation.shortCode)/live",
            imageURL: "",
            desc: azStation.description ?? "",
            longDesc: azStation.description ?? "",
            serverName: serverDomain,
            shortCode: azStation.shortCode,
            defaultDJ: ""
        )
    }

    private func convertFromPublicAzuracastStation(_ station: PublicAzuracastStation, serverDomain: String) -> StationConfig {
        return StationConfig(
            name: station.name,
            streamURL: station.listen_url,
            imageURL: "",
            desc: station.description,
            longDesc: station.description,
            serverName: serverDomain,
            shortCode: station.shortcode,
            defaultDJ: ""
        )
    }
}

// MARK: - Supporting Types

/// Wrapper for config array from GitHub
struct ConfigWrapper: Codable {
    let configs: [ConfigSource]
}

/// Configuration source type
enum ConfigFormat: String, Codable {
    case azuracast
    case `static`
}

/// A single configuration source (Azuracast or static)
/// All fields except format are optional; validation happens when the config is used
struct ConfigSource: Codable {
    let format: ConfigFormat
    let server: String?
    let exclude: [String]?
    let stations: [[String: String]]?

    /// Safe accessor for server (default: empty string)
    var safeServer: String {
        server ?? ""
    }

    /// Safe accessor for exclude list (default: empty array)
    var safeExclude: [String] {
        exclude ?? []
    }

    /// Safe accessor for stations - converts raw data to StationConfig objects
    var safeStations: [StationConfig] {
        guard let stationDicts = stations else { return [] }
        return stationDicts.compactMap { dict -> StationConfig? in
            guard
                let name = dict["name"],
                let streamURL = dict["streamURL"],
                let imageURL = dict["imageURL"],
                let desc = dict["desc"],
                let longDesc = dict["longDesc"],
                let serverName = dict["serverName"],
                let shortCode = dict["shortCode"],
                let defaultDJ = dict["defaultDJ"]
            else { return nil }

            return StationConfig(
                name: name,
                streamURL: streamURL,
                imageURL: imageURL,
                desc: desc,
                longDesc: longDesc,
                serverName: serverName,
                shortCode: shortCode,
                defaultDJ: defaultDJ
            )
        }
    }

    /// Check if this is a valid Azuracast config
    var isValidAzuracast: Bool {
        format == .azuracast && !safeServer.isEmpty
    }

    /// Check if this is a valid static config
    var isValidStatic: Bool {
        format == .static && !safeStations.isEmpty
    }
}

/// Station data from Azuracast Admin API
struct AzuracastStation: Codable {
    let id: String
    let name: String
    let shortCode: String
    let description: String?
    let isEnabled: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case shortCode = "short_code"
        case description
        case isEnabled = "is_enabled"
    }
}

/// Station data from public Azuracast API (/api/stations)
struct PublicAzuracastStation: Codable {
    let id: Int
    let name: String
    let shortcode: String
    let description: String
    let listen_url: String
    let url: String?
}

// MARK: - Internal Helpers

/// Error types for configuration loading
enum DataError: Error {
    case urlNotValid
    case dataNotValid
    case dataNotFound
    case fileNotFound
    case httpResponseNotValid
}

/// Debug configuration
struct Config {
    static let debugLog = false
}
