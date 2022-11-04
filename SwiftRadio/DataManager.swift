//
//  DataManager.swift
//  Swift Radio
//
//  Created by Matthew Fecher on 3/24/15.
//  Copyright (c) 2015 MatthewFecher.com. All rights reserved.
//

import UIKit

struct DataManager {
    
    // Helper struct to get either local or remote JSON
    
    static func getStation(completion: @escaping (_ stations: [RadioStation]) -> Void) {

        DispatchQueue.global(qos: .userInitiated).async {
            
            if useLocalStations {
                loadData() { data in
                    let stations = decode(data)
                    DispatchQueue.main.async {
                        completion(stations)
                    }
                }
            } else {
                guard let stationDataURL = URL(string: stationDataURL) else {
                    if kDebugLog { print("stationDataURL not a valid URL") }
                    DispatchQueue.main.async {
                        completion([])
                    }
                    return
                }
                
                loadData(from: stationDataURL) { data, error in
                    let stations = decode(data)
                    DispatchQueue.main.async {
                        completion(stations)
                    }
                }
            }
        }
    }
    
    static func decode(_ data: Data?) -> [RadioStation] {
        if kDebugLog { print("Stations JSON Found") }
        
        guard
            let data = data,
            let jsonDictionary = try? JSONDecoder().decode([String: [RadioStation]].self, from: data),
            let stations = jsonDictionary["station"]
        else {
            if kDebugLog { print("JSON Station Loading Error") }
            return []
        }
        
        return stations
    }
    
    // Load local JSON Data
    
    static func loadData(completion: (_ data: Data?) -> Void) {
        guard let filePathURL = Bundle.main.url(forResource: "stations", withExtension: "json") else {
            if kDebugLog { print("The local JSON file could not be found") }
            completion(nil)
            return
        }
        
        do {
            let data = try Data(contentsOf: filePathURL, options: .uncached)
            completion(data)
        } catch {
            fatalError()
        }
    }
    
    // REUSABLE DATA/API CALL METHOD
    // TODO: Replace this with `Result`
    static func loadData(from url: URL, completion: @escaping (_ data: Data?, _ error: Error?) -> Void) {
        
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        
        let session = URLSession(configuration: config)
        
        // Use URLSession to get data from an NSURL
        let loadDataTask = session.dataTask(with: url) { data, response, error in
            
            if let error = error {
                completion(nil, error)
                if kDebugLog { print("API ERROR: \(error.localizedDescription)") }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
                completion(nil, nil)
                if kDebugLog { print("API: HTTP status code has unexpected value") }
                return
            }
            
            guard let data = data else {
                completion(nil, nil)
                if kDebugLog { print("API: No data received") }
                return
            }
            
            // Success, return data
            completion(data, nil)
        }
        
        loadDataTask.resume()
    }
}
