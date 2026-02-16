//
//  ACWebSocketClient.swift
//
//  Created by Joe McMahon on 12/18/24.
//

import Foundation
import Combine

public let ACExtractedData = 1
public let ACRawSubsections = 2
public let ACFullDump = 4
public let ACConnectivityChecks = 8
public let ACActivityTrace = 16


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
    
    // Used to monitor connection to the metadata API. When we receive a connect
    // message, we clear out any old timer, then set a new one for a little after
    // the runtime of the track that's playing now. If all goes well, we'll get
    // another message before the time goes off, cancel it, and set a new one.
    // If we don't get a message before then, the timer pops, we disconnect the API,
    // reconnect, and set a new timer when the connect message is received.
    //
    private var stillAliveTimer: Timer? {
        willSet {
            if let timer = stillAliveTimer {
                timer.invalidate()
            }
        }
        didSet {
            if let timer = stillAliveTimer {
            }
        }
    }
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
    public var debugLevel: Int = 0
    
    private var lastResult: ACStreamStatus?
    private var consecutiveFailures: Int = 0
    private var lastKnownPingInterval: TimeInterval = 25.0

    /// Centralized debug logging with ISO timestamps and component tags.
    private func debugLog(_ tag: String, _ message: String, _ flag: Int = ACConnectivityChecks) {
        guard debugLevel & flag != 0 else { return }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let timestamp = formatter.string(from: Date())
        print("\(timestamp) \(tag) \(message)")
    }

    /// Constructs an empty `ACWebSoscketClient`, which must be initialized with
    /// `configurationDidChange` and `setDefaultDJ`.
    public init() {
        debugLog("[Init]", "Creating empty client", ACActivityTrace)
    }
    
    ///  Initializes an `ACWebSocketClient` instance with a preset server and station.
    /// - Parameters:
    ///   - serverName: The server name of the server to connect to
    ///   - `shortCode`: The Azuracast-defined shortcode from the station's profile page
    ///   - `defaultDJ`: The DJ name to supply if no streamer is active. Useful if the station is configured to play music when no streamer is active. Defaults to `""` if no value is specified.
    public init (serverName: String?, shortCode: String?, defaultDJ: String? = "") {
        debugLog("[Init]", "Creating configured client", ACActivityTrace)

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
        debugLog("[Subscribe]", "adding subscriber", ACActivityTrace)
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
        debugLog("[Notify]", "sending notifications", ACActivityTrace)
        for callback in subscribers {
            callback(data)
        }
    }
    
    /// switchToStation lets us pass a RadioStation in to set all the relevant URLs, etc. and (re)connect
    /// the websocket.
    func switchToStation(_ station: RadioStation) {
        debugLog("[SwitchStation]", "Switching to station: \(station.shortCode)", ACActivityTrace)

        self.serverName = station.serverName
        self.shortCode = station.shortCode
        self.defaultDJ = station.defaultDJ
        self.disconnect()
        self.constructWebSocketURL(serverName: station.serverName)
        self.connect()
        self.lastResult = ACStreamStatus()
    }
    
    /// Connects to the websocket API and sends the subscription message. Can be used to connect a
    /// currently-disconnected `ACWebSocketClient` or to reconnect an already-connected one.
    /// Marks the global status as `connected`.
    ///
    ///  This function is called if the liveness check timer goes off; this happens only if we haven't received
    ///  another message from the websocket by the time the timer goes off. The timer takes the API's
    ///  delivery guarantee, doubles it, and waits for that long before deciding we've lost the connection.
    public func connect() {
        // turn off the liveness check; the first parse of the connect data will
        // turn it back on.
        debugLog("[Connect]", "connect() called, current state: \(status.connection)", ACActivityTrace | ACConnectivityChecks)
        self.stillAliveTimer?.invalidate()
        if status.connection == ACConnectionState.connected {
            debugLog("[Connect]", "Already connected, disconnecting first")
            disconnect()
        }
        if let _ = self.webSocketURL {
            debugLog("[Connect]", "Starting websocket task to \(self.webSocketURL!)", ACActivityTrace | ACConnectivityChecks)
            webSocketTask = urlSession.webSocketTask(with: self.webSocketURL!)
            webSocketTask?.resume()
            status.connection = .connecting
            debugLog("[Connect]", "State set to connecting")
            sendSubscriptionMessage()
            listenForMessages()
        } else {
            debugLog("[Connect]", "No webSocketURL, cannot connect")
        }
     }
    
    /// Disconnects from the WebSocket API.  Sets the global status to `disconnected`.
    /// Always notifies subscribers so downstream consumers (StationMetadataManager)
    /// track the actual connection state. Duplicate .disconnected notifications are
    /// harmless — removeDuplicates() on the Combine chain handles idempotency.
    public func disconnect() {
        debugLog("[Disconnect]", "disconnect() called, current state: \(status.connection)", ACActivityTrace | ACConnectivityChecks)
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        status.connection = .disconnected
        debugLog("[Disconnect]", "State set to disconnected")
        notifySubscribers(with: status)
    }
    
    // Called if the liveness timer goes off.
    @objc func fellOver() {
        debugLog("[FellOver]", "Liveness timer expired after \(String(describing: status.pingInterval)) seconds, state: \(status.connection)")
        connect()
    }

    // Schedules a reconnection attempt after WebSocket error.
    // Only reconnects if network is reachable and we're still disconnected.
    // Uses exponential backoff: 5s, 10s, 20s, 40s, 60s max.
    private func scheduleReconnect() {
        let baseDelay: TimeInterval = 5.0
        let maxDelay: TimeInterval = 60.0
        let reconnectDelay = min(baseDelay * pow(2.0, Double(consecutiveFailures)), maxDelay)
        consecutiveFailures += 1
        debugLog("[ScheduleReconnect]", "Scheduling reconnect in \(reconnectDelay) seconds (attempt \(consecutiveFailures)), current state: \(status.connection)")
        DispatchQueue.main.asyncAfter(deadline: .now() + reconnectDelay) { [weak self] in
            guard let self = self else { return }
            self.debugLog("[ScheduleReconnect]", "Timer fired, state: \(self.status.connection)")
            if self.status.connection != .connected && self.status.connection != .connecting {
                self.debugLog("[ScheduleReconnect]", "Attempting connect")
                self.connect()
            } else {
                self.debugLog("[ScheduleReconnect]", "Already connected/connecting, skipping reconnect")
            }
        }
    }

    // Sends the subscription message for the specified station.
    // If the websocket task is already running, does nothing.
    // If the necessary parameters aren't set, does nothing and marks
    // `failedSubscribe` in the global status.
    // Otherwise generates the expected subscription message and sends it.
    private func sendSubscriptionMessage() {
        guard let webSocketTask = webSocketTask else { return }
        debugLog("[Subscribe]", "Subscribing", ACActivityTrace)
        guard let _ = self.serverName,
              let _ = self.shortCode else {
            status.connection = ACConnectionState.failedSubscribe
            status.changed = true
            debugLog("[Subscribe]", "Subscription failed!", ACActivityTrace)
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
        debugLog("[Subscribe]", "Subscription complete", ACActivityTrace)
    }
    
    // Listens for incoming messages from the WebSocket server.
    // All incoming messages should be text.
    private func listenForMessages() {
        debugLog("[Listen]", "Start listening for messages", ACActivityTrace)
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }

            self.debugLog("[Listen]", "message received", ACActivityTrace)
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
                if self.debugLevel & ACConnectivityChecks != 0 {
                    self.debugLog("[WebSocket]", "Error received: \(error), scheduling reconnect")
                } else {
                    print("WebSocket error: \(error)")
                }
                self.status.connection = .disconnected
                self.status.changed = true
                self.debugLog("[WebSocket]", "State set to disconnected after error")
                // Notify subscribers of disconnection so NowPlayingVC can
                // stop AVPlayer (prevents aggressive internal retries).
                self.notifySubscribers(with: self.status)
                // Don't keep listening on dead socket - schedule reconnection instead
                self.scheduleReconnect()
                return
            }

            // Keep listening for new messages (only on success)
            self.listenForMessages()
        }
    }
    
    // Handles incoming messages and updates the status.
    private func handleMessage(_ message: String) {
        debugLog("[HandleMessage]", "Handling message", ACActivityTrace)

        // First successful message confirms connection
        if status.connection == .connecting {
            status.connection = .connected
            consecutiveFailures = 0
            debugLog("[HandleMessage]", "First message received, state set to connected")
            // Notify subscribers immediately so downstream consumers
            // (StationMetadataManager) learn about reconnection even if
            // the metadata hasn't changed (e.g. same track still playing).
            notifySubscribers(with: status)
        }

        // Reset liveness timer BEFORE parsing. Any message at all proves
        // the WebSocket is alive — we don't need a successful parse for that.
        // Must schedule on main run loop because handleMessage runs on
        // URLSession's background thread.
        DispatchQueue.main.async {
            self.stillAliveTimer?.invalidate()
            let interval = self.lastKnownPingInterval * 1.5
            self.stillAliveTimer = Timer.scheduledTimer(
                timeInterval: interval,
                target: self,
                selector: #selector(self.fellOver),
                userInfo: nil,
                repeats: false)
            self.debugLog("[HandleMessage]", "liveness timer reset to \(interval)s (pingInterval \(self.lastKnownPingInterval)s + 50% leeway)")
        }

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

            // Update stored pingInterval from successful parse
            if let ping = result.pingInterval, ping > 0 {
                lastKnownPingInterval = Double(ping)
            }

            DispatchQueue.main.async {
                if result != self.lastResult && result.changed {
                    // Status changed from old values. (Note that the initial
                    // connect message and one or more subsequent channel
                    // messages may contain the same data; if they do, we'll
                    // skip this.) Record the new status and call all the
                    // callbacks.
                    // Preserve connection and network state - these are managed
                    // separately from parsed data. The parser creates a new
                    // ACStreamStatus with connection = .disconnected by default,
                    // which would overwrite the actual connection state.
                    let currentConnection = self.status.connection
                    self.status = result
                    self.status.connection = currentConnection
                    self.notifySubscribers(with: self.status)
                }
            }
        } catch {
            // Parse should NEVER fail — the parser has been thoroughly tested.
            // If this fires, something fundamentally unexpected happened.
            debugLog("[HandleMessage]", "PARSE FAILURE — THIS SHOULD NEVER HAPPEN: \(error)", ACConnectivityChecks)
            debugLog("[HandleMessage]", "Raw message (\(message.count) chars): \(String(message.prefix(500)))", ACConnectivityChecks)
        }
    }
}
