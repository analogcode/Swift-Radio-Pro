//
//  DataManager.swift
//  Swift Radio
//
//  Created by Matthew Fecher on 3/24/15.
//  Copyright (c) 2015 MatthewFecher.com. All rights reserved.
//

import UIKit

enum DataError: Error {
    case urlNotValid, dataNotValid, dataNotFound, fileNotFound, httpResponseNotValid
}

typealias StationsResult = Result<[RadioStation], Error>
typealias StationsCompletion = (StationsResult) -> Void

struct DataManager {

    // Helper struct to load stations from multiple sources
    private static let configClient = ConfigClient.shared

    static func getStation(completion: @escaping StationsCompletion) {

        DispatchQueue.global(qos: .userInitiated).async {

            // Priority order: ConfigClient → Local → HTTP
            if Config.useConfigClient {
                loadConfigClient { result in
                    handleStations(result, completion)
                }
            } else if Config.useLocalStations {
                loadLocal() { dataResult in
                    handle(dataResult, completion)
                }
            } else {
                loadHttp { dataResult in
                    handle(dataResult, completion)
                }
            }
        }
    }

    private typealias DataResult = Result<Data?, Error>
    private typealias DataCompletion = (DataResult) -> Void

    // Handler for direct StationsResult (from ConfigClient)
    private static func handleStations(_ stationsResult: StationsResult, _ completion: @escaping StationsCompletion) {
        DispatchQueue.main.async {
            completion(stationsResult)
        }
    }

    // Handler for DataResult (from Local/HTTP)
    private static func handle(_ dataResult: DataResult, _ completion: @escaping StationsCompletion) {
        DispatchQueue.main.async {
            switch dataResult {
            case .success(let data):
                let result = decode(data)
                completion(result)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private static func decode(_ data: Data?) -> Result<[RadioStation], Error> {
        if Config.debugLog { print("Stations JSON Found") }

        guard let data = data else {
            return .failure(DataError.dataNotFound)
        }

        let jsonDictionary: [String: [RadioStation]]

        do {
            jsonDictionary = try JSONDecoder().decode([String: [RadioStation]].self, from: data)
        } catch let error {
            return .failure(error)
        }

        guard let stations = jsonDictionary["station"] else {
            return .failure(DataError.dataNotValid)
        }

        return .success(stations)
    }

    // Load stations from ConfigClient
    private static func loadConfigClient(_ completion: @escaping (StationsResult) -> Void) {
        configClient.fetchStations { result in
            switch result {
            case .success(let stationConfigs):
                if Config.debugLog { print("Loaded \(stationConfigs.count) stations from ConfigClient") }
                // Convert StationConfig to RadioStation using the converter extension
                let radioStations = stationConfigs.map { RadioStation(from: $0) }
                completion(.success(radioStations))
            case .failure(let error):
                if Config.debugLog { print("ConfigClient fetch failed: \(error)") }
                completion(.failure(error))
            }
        }
    }

    // Load local JSON Data
    
    private static func loadLocal(_ completion: DataCompletion) {
        guard let filePathURL = Bundle.main.url(forResource: "stations", withExtension: "json") else {
            if Config.debugLog { print("The local JSON file could not be found") }
            completion(.failure(DataError.fileNotFound))
            return
        }
        
        do {
            let data = try Data(contentsOf: filePathURL, options: .uncached)
            completion(.success(data))
        } catch let error {
            completion(.failure(error))
        }
    }
        
    // Load http JSON Data
    private static func loadHttp(_ completion: @escaping DataCompletion) {
        guard let url = URL(string: Config.stationsURL) else {
            if Config.debugLog { print("stationsURL not a valid URL") }
            completion(.failure(DataError.urlNotValid))
            return
        }
        
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        
        let session = URLSession(configuration: config)
        
        // Use URLSession to get data from an NSURL
        let loadDataTask = session.dataTask(with: url) { data, response, error in
            
            if let error = error {
                if Config.debugLog { print("API ERROR: \(error.localizedDescription)") }
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
                if Config.debugLog { print("API: HTTP status code has unexpected value") }
                completion(.failure(DataError.httpResponseNotValid))
                return
            }
            
            guard let data = data else {
                if Config.debugLog { print("API: No data received") }
                completion(.failure(DataError.dataNotFound))
                return
            }
            
            completion(.success(data))
        }
        
        loadDataTask.resume()
    }
}
