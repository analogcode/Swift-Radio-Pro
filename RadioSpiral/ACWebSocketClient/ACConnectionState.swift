//
//  ACConnectionState.swift
//  ACWebSocketClient
//
//  Created by Joe McMahon on 12/29/24.
//

import Foundation

///  Describes the current state of the client's connection to the Azuracast server
///   - `connected`: client is successfully connected
///   - `disconnected`: client is not connected at all
///   - `stationNotFound`: the supplied shortcode  doesn't correspond to a station on this server
///   - `failedSubscribe`: we could connect to the server, but could not enable streaming
public enum ACConnectionState {
    case connected
    case disconnected
    case stationNotFound
    case failedSubscribe
}
