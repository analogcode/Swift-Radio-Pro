//
//  RadioAPI.swift
//  RadioSpiral
//
//  Created by Joe McMahon on 12/22/23.
//  Copyright © 2023 matthewfecher.com. All rights reserved.
//

import Foundation

struct Host: Codable {
    let name: String
    let url: String
}

struct Show: Codable {
    let id: Int
    let name: String
    let slug: String
    let url: String
    let hosts: [Host]
    let producers: [String]
    let genres: [String]
    let languages: [String]
    let avatar_url: String
    let avatar_id: String
    let image_url: String
    let image_id: String
}

struct BroadcastShow: Codable {
    let id: String
    let day: String
    let date: String
    let start: String
    let end: String
    let split: Bool
    let show: Show
}

struct NowPlaying: Codable {
    let text: String
    let title: String
    let artist: String
}

struct Broadcast: Codable {
    let current_show: BroadcastShow
    let next_show: BroadcastShow
    let current_playlist: Bool
    let now_playing: NowPlaying
    let instance: Int
}

struct Endpoints: Codable {
    let station, broadcast, schedule, shows, genres, languages, episodes, hosts, producers: String
}

struct RadioData: Codable {
    let broadcast: Broadcast
    let timezone, stream_url, stream_format, fallback_url: String
    let fallback_format, station_url, schedule_url, language, timestamp: String
    let date_time, updated: String
    let success: Bool
    let endpoints: Endpoints
}

struct RadioAPI {
    
    // Define the URL for the broadcast endpoint
    private static let endpointURL = URL(string: "https://radiospiral.net/wp-json/radio/broadcast/")!
    static var djName: String = ""
    static var showName: String = ""
    
    // Define a struct to represent the JSON response
    struct BroadcastResponse: Codable {
        let current_show: String
    }
    
    static var result: String = ""
    
    // Define a function to fetch the current show from the API
    static func getCurrentDJ(completion: @escaping (Result<String, Error>) -> Void) {
        
        // Create a data task to make the HTTP request
        let task = URLSession.shared.dataTask(with: endpointURL) { (data, response, error) in
            // Check for errors
            if let error = error {
                completion(.failure(error))
                return
            }

            // Check for a valid HTTP response
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(NSError(domain: "Invalid HTTP response", code: 0, userInfo: nil)))
                return
            }

            // Check for valid data
            guard let data = data else {
                completion(.failure(NSError(domain: "No data received", code: 0, userInfo: nil)))
                return
            }

            result = String(decoding: data, as: UTF8.self)
            print(result)
            do {
                // Decode the JSON response
                let decoder = JSONDecoder()
                let broadcastResponse = try decoder.decode(RadioData.self, from: data)
                // Extract and pass the current show value to the completion handler
                completion(.success("Live DJ: \(broadcastResponse.broadcast.current_show.show.hosts[0].name)"))
            } catch {
                print("failed")
                print(error)
                // Handle decoding errors within the closure
                completion(.failure(error))
            }
        }
        
        // Start the data task
        task.resume()
    }
}
