//
//  ACWebSocketClient.swift
//
//  Created by Joe McMahon on 12/18/24.
//

import Foundation
import Combine

/// Type describing a callback to send the current status to a subscriber.
public typealias MetadataCallback<T> = (T) -> Void

///  The `ACWebSocketClient` class allows us to connect to an Azuracast websocket server
///  for realtime stream metadata updates via a  supplied callback.
public class ACWebSocketClient: ObservableObject {
    
    /// Singleton instance; used  (particularly in SwiftUI) to ensure that everyone is using the same ciient.
    public static let shared = ACWebSocketClient()
    
    // Anyone subscribed to the metadata stream
    private var subscribers: [MetadataCallback<ACStreamStatus>] = []
    
    /// Current status for this client. If this is the singleton client, this status should be the same
    /// for all references to the client.
    public var status = ACStreamStatus()
        
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession = URLSession(configuration: .default)
    private var webSocketURL: URL?

    
    /// `serverName` is the name of the Azuracast server we're connecting to for the metadata stream
    var serverName: String?
    
    /// `shortCode` is the station name shortcode defined by Azuracast and found on the stations's profile page
    var shortCode: String?
    
    /// `defaultDJ`: the string to be retuned as the active DJ if no streamer is connected. Publically accessible.
    /// Set by `setDefaultDJ`.
    public var defaultDJ: String?
    
    /// `debugLevel`: for development only; set to  the sum of the flag values you want while debugging
    /// - 0: no debug outout is printed
    /// - 1: print the minimum data (track, artist, album, DJ)
    /// - 2: print the raw subsections the data is extracted from
    /// - 4: print the full set of JSON received from the stream before parsing`
    var debugLevel: Int = 0
    
    private var lastResult: ACStreamStatus?

    /// Constructs an empty `ACWebSoscketClient`, which must be initialized with
    /// `configurationDidChange` and `setDefaultDJ`.
    public init() {}
    
    ///  Initializes an `ACWebSocketClient` instance with a preset server and station.
    /// - Parameters:
    ///   - serverName: The server name of the server to connect to
    ///   - `shortCode`: The Azuracast-defined shortcode from the station's profile page
    ///   - `defaultDJ`: The DJ name to supply if no streamer is active. Useful if the station is configured to play music when no streamer is active. Defaults to `""` if no value is specified.
    public init (serverName: String?, shortCode: String?, defaultDJ: String? = "") {
        if let defaultDJ {
            self.defaultDJ = defaultDJ
        }
        if let serverName, let shortCode {
            self.serverName = serverName
            self.shortCode = shortCode
            constructWebSocketURL(serverName: serverName)
        }
    }
    
    private func constructWebSocketURL(serverName: String) {
        guard let webSocketURL = URL(string: "wss://\(String(describing: serverName))/api/live/nowplaying/websocket") else {
            fatalError("Invalid server name for WebSocket URL")
        }
        self.webSocketURL = webSocketURL
    }

    
    /// Adds a subscriber to the metadata returned asynchronously by the Azuracast now-plaiing API.
    /// - Parameter callback: Callback function to be called when a change to the station metadata
    /// is detected.
    ///
    /// The callback has the form `callbackFunction(status: StreamStatus)`; the `callback`
    /// parameter should be given only `callbackFunction`.
    public func addSubscriber(callback: @escaping MetadataCallback<ACStreamStatus>) {
            subscribers.append(callback)
    }
    
    /// Sets the default value to be returned as the DJ name when no streamer is connected.
    /// - Parameter name: The string  to be returned as the DJ's name when no streamer is active.
    public func setDefaultDJ(name: String) {
        defaultDJ = name
    }
    
    /// Sets the debug output level for the JSON parsing.
    ///
    /// Sum the values desired and use them as the `to:` argument
    ///  - 0: No debug output
    ///  - 1: Print the final derived values only.
    ///  - 2: Print the subsections of the JSON that are used to extract the data.
    ///  - 4: Print the raw incoming JSON in its entirety.
    public func debug(to: Int) {
        debugLevel = to
    }
    
    // Notify all suscribers when an update occurs
    private func notifySubscribers(with data: ACStreamStatus) {
        for callback in subscribers {
            callback(data)
        }
    }
    
    
    /// Call this method to update the configuration of the `ACWebSocketClient` and reconnect it.
    /// Diisconnects the client if  it's connected, changes the parameters, and reconnects with the new
    /// server and station, and clears the  last recorded stream status.
    public func configurationDidChange(serverName: String, shortCode: String) {
        self.serverName = serverName
        self.shortCode = shortCode
        self.disconnect()
        self.constructWebSocketURL(serverName: serverName)
        self.connect()
        self.lastResult = ACStreamStatus()
    }
    
    /// Connects to the websocket API and sends the subscription message. Can be used to connect a
    /// currently-disconnected `ACWebSocketClient` or to reconnect an already-connected one.
    /// Marks the global status as `connected`.
    public func connect() {
        if status.connection == ACConnectionState.connected { disconnect() }
        webSocketTask = urlSession.webSocketTask(with: self.webSocketURL!)
        webSocketTask?.resume()
        DispatchQueue.main.async {
            self.status.connection = ACConnectionState.connected
        }
        
        sendSubscriptionMessage()
        listenForMessages()
    }
    
    /// Disconnects from the WebSocket API.  Sets the global status to `disconnected`.
    public func disconnect() {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        DispatchQueue.main.async {
            self.status.connection = ACConnectionState.disconnected
        }
    }
    
    // Sends the subscription message for the specified station.
    // If the websocket task is already running, does nothing.
    // If the necessary parameters aren't set, does nothing and marks
    // `failedSubscribe` in the global status.
    // Otherwise generates the expected subscription message and sends it.
    private func sendSubscriptionMessage() {
        guard let webSocketTask = webSocketTask else { return }
        guard let _ = self.serverName,
              let _ = self.shortCode else {
            status.connection = ACConnectionState.failedSubscribe
            status.changed = true
            return
        }
        
        let subscriptionMessage = ["subs": ["station:\(self.shortCode!)": ["recover": true]]]
        if let jsonData = try? JSONSerialization.data(withJSONObject: subscriptionMessage, options: []) {
            let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
            webSocketTask.send(.string(jsonString)) { error in
                if let error = error {
                    print("Failed to send subscription message: \(error)")
                    self.status.connection = ACConnectionState.failedSubscribe
                    self.status.changed = true
                }
            }
        } else {
            print("Failed to encode subscription message")
            status.connection = ACConnectionState.failedSubscribe
            status.changed = true
        }
    }
    
    // Listens for incoming messages from the WebSocket server.
    // All incoming messages should be text.
    private func listenForMessages() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self.handleMessage(text)
                case .data(let data):
                    print("Received binary data: \(data)")
                @unknown default:
                    print("Received unknown message type")
                }
            case .failure(let error):
                print("WebSocket error: \(error)")
                DispatchQueue.main.async {
                    self.status.connection = ACConnectionState.disconnected
                    self.status.changed = true
                }
            }
            
            // Keep listening for new messages
            self.listenForMessages()
        }
    }
    
    // Handles incoming messages and updates the status.
    private func handleMessage(_ message: String) {
        
        // Decode into data for parseWebSocketData.
        guard let data = message.data(using: .utf8) else {
            print("Failed to decode message to data")
            return
        }
        
        // Save last result.
        lastResult?.album = status.album
        lastResult?.artist = status.artist
        lastResult?.track = status.track
        lastResult?.artwork = status.artwork
        lastResult?.dj = status.dj
        
        do {
            // Attempt to parse the data. Parser will throw if it fails to work.
            let parser = ParseWebSocketData(data: data, defaultDJ: defaultDJ)
            parser.debug(to: debugLevel)
            
            // I can hard-unwrap this because I had to have a value to connect
            // at all. The shortCode is needed because one key contains it.
            let result = try parser.parse(shortCode: shortCode!)
            DispatchQueue.main.async {
                if result != self.lastResult {
                    // Status changed from old values. (Note that the initial
                    // connect message and one or more subsequent channel
                    // messages may contain the same data; if they do, we'll
                    // skip this.) Record the new status and call all the
                    // callbacks.
                    self.status = result
                    self.notifySubscribers(with: self.status)
                }
            }
        } catch {
            print("Failed to parse JSON: \(error)")
        }
    }
}
