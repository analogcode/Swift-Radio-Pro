//
//  FRadioAPI.swift
//  FRadioPlayer
//
//  Created by Fethi El Hassasna on 2017-11-25.
//  Copyright © 2017 Fethi El Hassasna (@fethica). All rights reserved.
//

import Foundation

// MARK: - iTunes API
internal struct FRadioAPI {
    
    // MARK: - Util methods
    
    static func getArtwork(for metadata: String, size: Int, completionHandler: @escaping (_ artworkURL: URL?) -> ()) {
        
        guard !metadata.isEmpty, metadata !=  " - ", let url = getURL(with: metadata) else {
            completionHandler(nil)
            return
        }
                
        URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
            guard error == nil, let data = data else {
                completionHandler(nil)
                return
            }
            
            let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
            
            guard let parsedResult = json as? [String: Any],
                let results = parsedResult[Keys.results] as? Array<[String: Any]>,
                let result = results.first,
                var artwork = result[Keys.artwork] as? String else {
                    completionHandler(nil)
                    return
            }
            
            if size != 100, size > 0 {
                artwork = artwork.replacingOccurrences(of: "100x100", with: "\(size)x\(size)")
            }
            
            let artworkURL = URL(string: artwork)
            completionHandler(artworkURL)
        }).resume()
    }
    
    private static func getURL(with term: String) -> URL? {
        var components = URLComponents()
        components.scheme = Domain.scheme
        components.host = Domain.host
        components.path = Domain.path
        components.queryItems = [URLQueryItem]()
        components.queryItems?.append(URLQueryItem(name: Keys.term, value: term))
        components.queryItems?.append(URLQueryItem(name: Keys.entity, value: Values.entity))
        return components.url
    }
    
    // MARK: - Constants
    
    private struct Domain {
        static let scheme = "https"
        static let host = "itunes.apple.com"
        static let path = "/search"
    }
    
    private struct Keys {
        // Request
        static let term = "term"
        static let entity = "entity"
        
        // Response
        static let results = "results"
        static let artwork = "artworkUrl100"
    }
    
    private struct Values {
        static let entity = "song"
    }
}

