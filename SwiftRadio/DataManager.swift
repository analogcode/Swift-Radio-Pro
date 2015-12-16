//
//  DataManager.swift
//  Swift Radio
//
//  Created by Matthew Fecher on 3/24/15.
//  Copyright (c) 2015 MatthewFecher.com. All rights reserved.
//

import UIKit

class DataManager {
    
    //*****************************************************************
    // Load local JSON Data
    //*****************************************************************
    
    class func getDataFromFileWithSuccess(success: (data: NSData) -> Void) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            
            let filePath = NSBundle.mainBundle().pathForResource("stations", ofType:"json")
            do {
                let data = try NSData(contentsOfFile:filePath!,
                    options: NSDataReadingOptions.DataReadingUncached)
                success(data: data)
            } catch {
                fatalError()
            }
        }
    }
    
    //*****************************************************************
    // Get LastFM/iTunes Data
    //*****************************************************************
    
    class func getTrackDataWithSuccess(queryURL: String, success: ((metaData: NSData!) -> Void)) {

        loadDataFromURL(NSURL(string: queryURL)!) { data, _ in
            // Return Data
            if let urlData = data {
                success(metaData: urlData)
            } else {
                if DEBUG_LOG { print("API TIMEOUT OR ERROR") }
            }
        }
    }
    
    //*****************************************************************
    // REUSABLE DATA/API CALL METHOD
    //*****************************************************************
    
    class func loadDataFromURL(url: NSURL, completion:(data: NSData?, error: NSError?) -> Void) {
        
        let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
        sessionConfig.allowsCellularAccess          = true
        sessionConfig.timeoutIntervalForRequest     = 15
        sessionConfig.timeoutIntervalForResource    = 30
        sessionConfig.HTTPMaximumConnectionsPerHost = 1
        
        let session = NSURLSession(configuration: sessionConfig)
        
        // Use NSURLSession to get data from an NSURL
        let loadDataTask = session.dataTaskWithURL(url){ data, response, error in
            if let responseError = error {
                completion(data: nil, error: responseError)
                
                if DEBUG_LOG { print("API ERROR: \(error)") }
                
                // Stop activity Indicator
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                
            } else if let httpResponse = response as? NSHTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    let statusError = NSError(domain:"io.codemarket", code:httpResponse.statusCode, userInfo:[NSLocalizedDescriptionKey : "HTTP status code has unexpected value."])
                    
                    if DEBUG_LOG { print("API: HTTP status code has unexpected value") }
                    
                    completion(data: nil, error: statusError)
                    
                } else {
                    
                    // Success, return data
                    completion(data: data, error: nil)
                }
            }
        }
        
        loadDataTask.resume()
    }
}