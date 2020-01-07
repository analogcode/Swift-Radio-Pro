//
//  CarPlayPlaylist.swift
//  SwiftRadio
//
//  Created by Fethi El Hassasna on 2019-02-02.
//  Copyright © 2019 matthewfecher.com. All rights reserved.
//

import Foundation

public enum listType{
    case station, list
}
class CarPlayPlaylist {
    
    var stations = [RadioStation]()
        
    func load(type: listType, completion: @escaping (Error?) -> Void) {
        
        DataManager.getStationDataWithSuccess() { (data) in
            
            guard let data = data else {
                completion(nil)
                return
            }
            
            do {
                let jsonDictionary = try JSONDecoder().decode([String: [RadioStation]].self, from: data)
                switch type{
                case .station:
                    if let stationsArray = jsonDictionary["station"] {
                        self.stations = stationsArray
                    }
                case .list:
                    if let stationsArray = jsonDictionary["list"] {
                        self.stations = stationsArray
                    }
                }
            } catch (let error) {
                completion(error)
                return
            }
            
            completion(nil)
        }
        
    }

}
