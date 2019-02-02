//
//  CarPlayPlaylist.swift
//  SwiftRadio
//
//  Created by Fethi El Hassasna on 2019-02-02.
//  Copyright © 2019 matthewfecher.com. All rights reserved.
//

import Foundation

class CarPlayPlaylist {
    
    static let shared = CarPlayPlaylist()
    
    var stations = [RadioStation]()
    
    private init() {}
    
    func load(_ completion: @escaping (Error?) -> Void) {
        
        DataManager.getStationDataWithSuccess() { (data) in
            
            guard let data = data else {
                completion(nil)
                return
            }
            
            do {
                let jsonDictionary = try JSONDecoder().decode([String: [RadioStation]].self, from: data)
                if let stationsArray = jsonDictionary["station"] {
                    self.stations = stationsArray
                }
            } catch (let error) {
                completion(error)
                return
            }
            
            completion(nil)
        }
        
    }

}
