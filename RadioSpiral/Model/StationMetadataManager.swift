//
//  StationMetadataManager.swift
//  RadioSpiral
//
//  Created by Joe McMahon on 2025-01-27.
//  Copyright © 2025 RadioSpiral. All rights reserved.
//

import Foundation
import Combine

/// Unified metadata structure from Azuracast with ConfigClient fallback
public struct UnifiedMetadata: Equatable {
    let trackName: String
    let artistName: String
    let albumName: String?
    let artworkURL: URL?
    let duration: TimeInterval?
    let djName: String?
    let isLiveDJ: Bool

    public init(trackName: String, artistName: String, albumName: String? = nil, artworkURL: URL? = nil, duration: TimeInterval? = nil, djName: String? = nil, isLiveDJ: Bool = false) {
        self.trackName = trackName
        self.artistName = artistName
        self.albumName = albumName
        self.artworkURL = artworkURL
        self.duration = duration
        self.djName = djName
        self.isLiveDJ = isLiveDJ
    }
    
    public static func == (lhs: UnifiedMetadata, rhs: UnifiedMetadata) -> Bool {
        let lhsTrack = lhs.trackName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let rhsTrack = rhs.trackName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let lhsAlbum = (lhs.albumName ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let rhsAlbum = (rhs.albumName ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let result = lhsTrack == rhsTrack && lhsAlbum == rhsAlbum
        return result
    }
}

public extension UnifiedMetadata {
    var isValid: Bool {
        !trackName.isEmpty && !artistName.isEmpty
    }
}

/// Indicates the current connection state of the metadata system
public enum MetadataConnectionState {
    case disconnected
    case connecting
    case connected
    case failed
    case reconnecting
}

/// Protocol for metadata change callbacks
public typealias MetadataChangeCallback = (UnifiedMetadata?) -> Void

/// Manages unified metadata from Azuracast with ConfigClient fallback
public class StationMetadataManager: ObservableObject {
    
    // MARK: - Singleton
    public static let shared = StationMetadataManager()
    
    // MARK: - Published Properties
    @Published public private(set) var currentMetadata: UnifiedMetadata?
    @Published public private(set) var connectionState: MetadataConnectionState = .disconnected
    
    // MARK: - Private Properties
    private let azuracastClient = ACWebSocketClient.shared
    private let configClient = ConfigClient.shared
    private var subscribers: [MetadataChangeCallback] = []
    private var currentStation: RadioStation?
    private var cancellables = Set<AnyCancellable>()
    private static var activeSubscribers = 0
    
    // MARK: - Initialization
    private init() {
        // Debug flags: ACExtractedData(1) | ACRawSubsections(2) | ACFullDump(4) | ACConnectivityChecks(8) | ACActivityTrace(16)
        // Enable ACConnectivityChecks for connection debugging on device
        azuracastClient.debugLevel = ACConnectivityChecks
        setupPlayerObserver()
        setupAzuracastObserver()
    }
    
    // MARK: - Public Methods
    
    /// Connect to a station's metadata sources
    public func connectToStation(_ station: RadioStation) {
        disconnectCurrentStation()
        
        currentStation = station
        
        // Configure Azuracast client
        azuracastClient.switchToStation(station)
        
        // Update connection state
        connectionState = .connecting
        
        // Start monitoring metadata
        updateMetadata()
    }
    
    /// Disconnect from current station's metadata sources
    public func disconnectCurrentStation() {
        // Disconnect Azuracast client
        azuracastClient.disconnect()
        
        // Clear current metadata
        currentMetadata = nil
        currentStation = nil
        connectionState = .disconnected
        
        // Notify subscribers
        notifySubscribers(with: nil)
    }
    
    /// Subscribe to metadata changes
    public func subscribeToMetadataChanges(_ callback: @escaping MetadataChangeCallback) {
        subscribers.append(callback)
        StationMetadataManager.activeSubscribers += 1
        // Immediately call with current metadata
        callback(currentMetadata)
    }
    
    /// Unsubscribe from metadata changes
    public func unsubscribeFromMetadataChanges(_ callback: @escaping MetadataChangeCallback) {
        let before = subscribers.count
        subscribers.removeAll { $0 as AnyObject === callback as AnyObject }
        let after = subscribers.count
        let removed = before - after
        StationMetadataManager.activeSubscribers -= removed
    }

    /// Get current unified metadata
    public func getCurrentMetadata() -> UnifiedMetadata? {
        return currentMetadata
    }

    /// Trigger metadata update (called when FRadioPlayer metadata changes)
    public func triggerMetadataUpdate() {
        updateMetadata()
    }

    // MARK: - Private Methods
    
    private func setupPlayerObserver() {
        // Player observer - metadata updates come through Azuracast WebSocket
    }
    
    private func setupAzuracastObserver() {
        // Subscribe to Azuracast metadata changes
        azuracastClient.addSubscriber { [weak self] status in
            DispatchQueue.main.async {
                self?.handleAzuracastMetadataUpdate(status)
            }
        }
    }
    
    private func handleAzuracastMetadataUpdate(_ status: ACStreamStatus) {
        // Update connection state based on Azuracast status
        switch status.connection {
        case .connected:
            connectionState = .connected
        case .connecting:
            connectionState = .connecting
        case .disconnected:
            connectionState = .disconnected
        case .failedSubscribe:
            connectionState = .failed
        case .stationNotFound:
            connectionState = .failed
        }
        // Update metadata
        updateMetadata()
    }
    
    private func updateMetadata() {
        let newMetadata = getUnifiedMetadata()
        
        // Only update if metadata has actually changed
        if newMetadata != currentMetadata {
            currentMetadata = newMetadata
            notifySubscribers(with: newMetadata)
        }
    }
    
    private func getUnifiedMetadata() -> UnifiedMetadata? {
        // Priority 1: Azuracast metadata (if available and valid)
        if let azuracastMetadata = getAzuracastMetadata(), azuracastMetadata.isValid {
            return azuracastMetadata
        }
        
        // Priority 2: Fallback to station info
        return getFallbackMetadata()
    }
    
    private func getAzuracastMetadata() -> UnifiedMetadata? {
        let status = azuracastClient.status
        guard status.isValid else {
            return nil
        }
        return UnifiedMetadata(
            trackName: status.track,
            artistName: status.artist,
            albumName: status.album.isEmpty ? nil : status.album,
            artworkURL: status.artwork,
            duration: status.duration > 0 ? status.duration : nil,
            djName: status.dj.isEmpty ? nil : status.dj,
            isLiveDJ: status.isLiveDJ
        )
    }
    
    private func getFallbackMetadata() -> UnifiedMetadata? {
        guard let station = currentStation else { return nil }

        // Try to get enhanced station info from ConfigClient
        let stationInfo = configClient.getStationInfo(byShortCode: station.shortCode)

        // Use ConfigClient's station info if available, otherwise fall back to RadioStation data
        let trackName = stationInfo?.name ?? station.name
        let artistName = stationInfo?.desc ?? station.desc
        let djName = !station.defaultDJ.isEmpty ? station.defaultDJ : stationInfo?.defaultDJ

        return UnifiedMetadata(
            trackName: trackName,
            artistName: artistName,
            albumName: nil,
            artworkURL: nil,
            duration: nil,
            djName: djName,
            isLiveDJ: false
        )
    }
    
    private func notifySubscribers(with metadata: UnifiedMetadata?) {
        for callback in subscribers {
            callback(metadata)
        }
    }
}

// MARK: - Extensions

extension ACStreamStatus {
    /// Check if the Azuracast metadata is valid and usable
    var isValid: Bool {
        return !track.isEmpty && !artist.isEmpty && changed
    }
} 
