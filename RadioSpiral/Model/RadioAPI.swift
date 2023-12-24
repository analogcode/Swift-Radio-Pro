//
//  RadioAPI.swift
//  RadioSpiral
//
//  Created by Joe McMahon on 12/22/23.
//  Copyright © 2023 matthewfecher.com. All rights reserved.
//

import Foundation

struct Show: Codable {
    let id: Int
    let title: String
    let name: String
    let slug: String
    let url: String
    let genres: [String]
    let languages: [String]
    let hosts: [Host]
    let producers: [String] // You can replace this with the actual type if needed
    let avatar_url: String
    let avatar_id: String
    let image_url: String
    let image_id: String
}

struct Host: Codable {
    let name: String
    let url: String
}

struct ShowDetails: Codable {
    let override: Int
    let id: String
    let name: String
    let slug: String
    let date: String
    let day: String
    let start: String
    let end: String
    let url: String
    let split: Bool
    let show: Show
}

struct Broadcast: Codable {
    let current_show: ShowDetails
    let next_show: ShowDetails
    let current_playlist: Bool
    let now_playing: NowPlaying
    let instance: Int
}

struct NowPlaying: Codable {
    let text: String
    let title: String
    let artist: String
}

struct Endpoints: Codable {
    let station: String
    let broadcast: String
    let schedule: String
    let shows: String
    let genres: String
    let languages: String
    let episodes: String
    let hosts: String
    let producers: String
}

struct Root: Codable {
    let broadcast: Broadcast
    let timezone: String
    let stream_url: String
    let stream_format: String
    let fallback_url: String
    let fallback_format: String
    let station_url: String
    let schedule_url: String
    let language: String
    let timestamp: String
    let date_time: String
    let updated: String
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
            do {
                // Decode the JSON response
                let decoder = JSONDecoder()
                let broadcastResponse = try decoder.decode(BroadcastResponse.self, from: data)

                // Extract and pass the current show value to the completion handler
                completion(.success(broadcastResponse.current_show))
            } catch {
                // Handle decoding errors within the closure
                completion(.failure(error))
            }
        }
        
        // Start the data task
        task.resume()
    }
}
