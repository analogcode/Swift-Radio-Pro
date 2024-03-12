//
//  RadioStationPROAPI.swift
//  RadioSpiral
//
//  Created by Joe McMahon on 12/22/23.
//  Copyright © 2023 matthewfecher.com. All rights reserved.
//

import Foundation

enum NoShowError: Error {
    case message(String)
}

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
}

struct BroadcastShow: Codable {
    let id: String
    let day: String
    let date: String
    let start: String
    let end: String
    let show: Show
}

struct NowPlaying: Codable {
    let text: String
    let title: String
    let artist: String
}

struct ActiveShow: Codable {
    let current_show: BroadcastShow?
    let next_show: BroadcastShow
    let now_playing: NowPlaying
    let instance: Int
}

struct NoActiveShow: Codable {
//    let current_show: Bool
    let next_show: BroadcastShow
    let now_playing: NowPlaying
    let instance: Int
}

struct Endpoints: Codable {
    let station, broadcast, schedule, shows, genres, languages, episodes, hosts, producers: String
}

struct ShowOn: Codable {
    let broadcast: ActiveShow
    let timezone, stream_url, stream_format, fallback_url: String
    let fallback_format, station_url, schedule_url, language, timestamp: String
    let date_time, updated: String
    let success: Bool
    let endpoints: Endpoints
}

struct NoShowOn: Codable {
    let broadcast: NoActiveShow
    let timezone, stream_url, stream_format, fallback_url: String
    let fallback_format, station_url, schedule_url, language, timestamp: String
    let date_time, updated: String
    let success: Bool
    let endpoints: Endpoints
}

struct RadioStationPROAPI {
    
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
            // Try active show, then no show
            do {
                // Decode the JSON response
                let decoder = JSONDecoder()
                print("decoding assuming current show")
                let activeResponse = try decoder.decode(ShowOn.self, from: data)
                // Extract and pass the current show value to the completion handler
                print("active parse okay, trying extract")
                completion(.success(activeResponse.broadcast.current_show!.show.hosts[0].name))
            } catch {
                print("active show failed, trying inactive")
                // Retry with different parse
                do {
                    // Decode the JSON response
                    let decoder = JSONDecoder()
                    print("decoding assuming no current show")
                    let noActiveResponse = try decoder.decode(NoShowOn.self, from: data)
                    // Extract and pass the current show value to the completion handler
                    print("parse no active show okay, trying extract")
                    let djName = noActiveResponse.broadcast.next_show.show.hosts[0].name
                    print("trying to see if API is lagging")
                    let show_date = noActiveResponse.broadcast.next_show.date
                    let start_hour = noActiveResponse.broadcast.next_show.start
                    let tz = noActiveResponse.timezone
                    print("converting show date_time \(show_date) at \(start_hour) to \(tz)")
                    
                    var showDate = Date()
                    let showDateFormatter = DateFormatter()
                    showDateFormatter.dateFormat = "yyyy-MM-dd"
                    
                    // Parse the date string
                    if let date = showDateFormatter.date(from: show_date) {
                        // Get the current calendar
                        let showCalendar = Calendar.current
                        
                        // Extract components from the date
                        var showDateComponents = showCalendar.dateComponents([.year, .month, .day], from: date)
                        
                        // Set the hour component}
                        showDateComponents.hour = Int(start_hour)
                        
                        // Get the date with the new hour
                        if let showDate = showCalendar.date(from: showDateComponents) {
                            print("New date with hour set to \(start_hour): \(showDate)")
                        } else {
                            completion(.failure(NoShowError.message("could not use show hour \(start_hour)")))
                        }
                    } else {
                        completion(.failure(NoShowError.message("could not parse show date \(show_date)")))
                    }
                        
                    print("showDate: \(showDate)")
                    let currentDate = Date()
                    print("checking if 'next' show has started now: \(currentDate) vs show: \(showDate)")
                    print(currentDate > showDate)
                    print("hasn't")
                    completion(.failure(NoShowError.message("no active show")))
                } catch  {
                    print("parse failed completely")
                    print(error)
                    completion(.failure(error))
                }
            }
        }
        // Start the data task
        task.resume()
    }
}
