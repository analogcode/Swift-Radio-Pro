//
//  ParseWebSocketData.swift
//
//  Created by Joe McMahon on 12/21/24.
//

import Foundation
import Combine

///  Actually parses the incoming JSON from the websocket and sets the status fields to correspond.
public class ParseWebSocketData {
    var data: Data
    var defaultDJ: String?
    private var debugLevel: Int = 0
    
    ///  `init(data: status: defaultDJ:)
    ///  Sets up to parse the data passed as the `data:` argument.
    /// - Parameters:
    ///   - data: <#data description#>
    ///   - status: <#status description#>
    ///   - defaultDJ: <#defaultDJ description#>
    public init(data: Data, defaultDJ: String?) {
        self.data = data
        self.defaultDJ = defaultDJ
    }
    
    /// `debug(to:)`
    /// Sets the debugging flags:
    /// - Parameter `to`:  Summed valies from the list below. E. g., if we want the extracted field
    /// values and the full JSON dump, then we set `to` to `1 + 4`, or `5`.
    ///     - 0 - no debug
    ///     - 1 - debug extracted fields
    ///     - 2 - debug subsctructs
    ///     - 4 - full metadata dump
    public func debug(to: Int) {
        debugLevel = to
    }
    
    /// `status` is an `@Published` `ACStreamStatus` struct,, updated each time we successfully
    /// parse the stream JSON.
    @Published var status: ACStreamStatus = ACStreamStatus()
    
    /// `parse(shortCode:)`
    /// Parses the websocket JSON and extracts relevant data into an `ACStreamStatus`.
    /// - Parameter shortCode: The shortcode for the station being monitored. Needed to be able to
    /// construct one of the JSON keys.
    /// - Returns: A duplicate `ACStreamStatus` to the one stored in the `@Published` variable.
    /// Allows us to use either SwiftUI or UIKit  when parsing the data.
    public func parse(shortCode: String) throws -> ACStreamStatus {
        // First: I know, I know. Codable is the better way to do this.
        // The problem is that there is one weird key that doesn't match
        // standard JSON keying ("station:shortname") which means we can't
        // use Codable.
        //
        // So we're stuck with JSONSerialization, messy as it is.
        // If I do find a way to fix that, I will absolutely switch to Codable.
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        if let nowPlayingData = json as? [String: Any] {
            if debugLevel & 4 != 0 { print("nowPlayingData: \(nowPlayingData)") }
            self.status = ACStreamStatus()
            
            // 'connect' message
            if nowPlayingData["connect"] != nil {
                
                // chain down to the now-playing data
                let connect = nowPlayingData["connect"] as? Dictionary<String, Any>
                let subs = connect?["subs"] as? Dictionary<String, Any>
                let sub = subs?["station:\(shortCode)"] as? Dictionary<String, Any>
                let publications = sub?["publications"] as? [Any]
                // A bad shortcode will cause us to not have any publications.
                // Use this to diagnose this properly to the caller. (The connection
                // will be up, and we'll be receiving data, but none of it will
                // have anything we can _use_ as metadata.
                if publications == nil {
                    self.status.connection = ACConnectionState.failedSubscribe
                    return self.status
                }
                let pub = publications?[0] as? Dictionary<String, Any>
                let data = pub?["data"] as? Dictionary<String, Any>
                let np = data?["np"] as? Dictionary<String, Any>

                // Live segment. Contains info about the streamer.
                let live = np?["live"] as? Dictionary<String, Any>
                self.status = setDJ(live: live, status: self.status, defaultDJ: defaultDJ)
                if debugLevel & 2 != 0 { print("live: \(String(describing: live))") }

                /*
                 // Next song data is available, but StreamStatus doesn't support it yet
                 // Commented out but left here for future expansion.
                 // Parse `playing_next` segment.
                 let next = np?["playing_next"] as? Dictionary<String, Any>
                 let next_song = next?["song"] as? Dictionary<String, Any>
                 let next_album = next_song?["album"] as! String
                 let next_art_url = try URL(from:next_song?["art"] as! Decoder)
                 let next_artist = next_song?["artist"] as! String
                 let next_title = next_song?["title"] as! String
                 */
                
                // Chain down to current song segment.
                let current = np?["now_playing"] as? Dictionary<String, Any>
                let current_song = current?["song"] as? Dictionary<String, Any>
                if debugLevel & 2 != 0 { print("current song: \(String(describing: current_song))") }
                
                // Extract track info from song segment.
                // TODO: Generalize this for next song and songs in song history.
                status.album = current_song?["album"] as! String
                status.artist = current_song?["artist"] as! String
                status.track = current_song?["title"] as! String
                
                // Extract artwork URL as string, and convert to URL.
                let artURLString = current_song?["art"] as! String
                status.artwork = URL(string: artURLString)
                
                if debugLevel & 1 != 0 {
                    print("album: \(status.album)")
                    print("track: \(status.track)")
                    print("artist: \(status.artist)")
                    print("art: \(artURLString)")
                }

                // We parsed the data, so this struct has changed.
                status.changed = true
            } else if nowPlayingData["channel"] != nil {
                
                // channel data. chain down to now-playing data.
                let pub = nowPlayingData["pub"] as! Dictionary<String, Any>
                let npData = pub["data"] as! Dictionary<String, Any>
                let np = npData["np"] as! Dictionary<String, Any>

                // live block. Extract DJ info.
                let live = np["live"] as? Dictionary<String, Any>
                self.status = setDJ(live: live, status: self.status, defaultDJ: defaultDJ)

                // now_playing block. Extract track info.
                let nowPlaying = np["now_playing"] as! Dictionary<String, Any>
                let song = nowPlaying["song"] as! Dictionary<String, Any>
                status.album = song["album"] as! String
                status.artist = song["artist"] as! String
                status.track = song["title"] as! String
                
                // Extract artwork URL string, and make it a real URL.
                let artURLString = song["art"] as! String
                status.artwork = URL(string: artURLString)
                
                // Mark as changed.
                status.changed = true
            }
            else {
                // Message type we can't parse. Mark statuss
                status.changed = false
            }
        }
        // Return the status of the parse. Anyone monitoring it via `@publishef
        return status
    }
    
    // DJ processing. If we can't extract a streamer from the live data,
    // use the default DJ. If we can, but it's blank, also send back the
    // default DJ.
    private func setDJ(live: Dictionary<String, Any>?, status: ACStreamStatus, defaultDJ: String?) -> ACStreamStatus {
        // live data: extract dj, set default if no dj and a default was supplied
        status.dj = live?["streamer_name"] as? String ?? ""
        status.isLiveDJ = true
        if status.dj == "" {
            status.isLiveDJ = false
            guard let dj = defaultDJ else {
                if debugLevel & 1 != 0 { print("DJ: \(String(describing: defaultDJ))") }
                return status
            }
                status.dj = dj
                if debugLevel & 1 != 0 { print("DJ: \(dj)") }
        }
        return status
    }
}
