//
//  ACStreamStatus.swift
//
//  Created by Joe McMahon on 12/21/24.
//

import Foundation

/// Encapsulates the current metadata for the subscribed-to station.
public class ACStreamStatus: Equatable, ObservableObject {
    
    /// ==: allows you to use the == operator to compare two `ACStreamStatus` instances
    /// - Parameters:
    ///   - lhs: one `AcStreamStatus` instance
    ///   - rhs: a second `AcStreamStatus` instance
    /// - Returns: `true` if they match, `false` if they don't.
    public static func == (lhs: ACStreamStatus, rhs: ACStreamStatus) -> Bool {
        lhs.connection == rhs.connection
        && lhs.isLiveDJ == rhs.isLiveDJ
        && lhs.track == rhs.track
        && lhs.artist == rhs.artist
        && lhs.album == rhs.album
        && lhs.dj == rhs.dj
    }
    
    ///   `init()` creates an empty `AcStreamStatus` instance
    ///
    ///    - stream is disconnected
    ///    - values are changed
    ///    - no live DJ, track, artist, album, or DJ name
    public init() {
        self.connection = ACConnectionState.disconnected
        self.changed = true
        self.isLiveDJ = false
        self.track = ""
        self.artist = ""
        self.album = ""
        self.dj = ""
    }
    
    ///  `init` with all fields speciified
    ///
    ///  Creates a fully-populated `ACStreamStatus` instance
    ///
    ///  - `connection` statte is one of the valid states (see `ACConectionState`)
    ///  - `changed` is `true` (since this is a newly-created status)
    ///  - `isLiveDJ`, `track`, `artist`, `album`, `dj`, and `artwork` are all set to the supplied values
    public init(connection: ACConnectionState, isLiveDJ: Bool, track: String, artist: String, album: String, dj: String, artwork: URL?) {
        self.connection = connection
        self.changed = true
        self.isLiveDJ = isLiveDJ
        self.track = track
        self.artist = artist
        self.album = album
        self.dj = dj
        self.artwork = artwork
    }
    
    public var connection: ACConnectionState
    public var changed: Bool
    public var isLiveDJ: Bool
    public var track: String
    public var artist: String
    public var album: String
    public var dj: String
    public var artwork: URL?
}
