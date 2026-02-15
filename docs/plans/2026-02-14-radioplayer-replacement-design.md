# Replace FRadioPlayer with RadioPlayer (direct AVPlayer wrapper)

## Problem

FRadioPlayer wraps AVPlayer and adds its own Reachability-based retry/reconnection logic. When the network drops, FRadioPlayer's internal AVPlayer opens new connections to the stream URL with accelerating frequency (connections 18→29+ observed in device testing), eventually triggering `HALC_ProxyIOContext::IOWorkLoop: skipping cycle due to overload` and crashing the app.

FRadioPlayer's main value proposition — ICY stream metadata parsing from Icecast — is now completely redundant since all metadata comes from the Azuracast WebSocket (ACWebSocketClient). It's just a hostile AVPlayer wrapper at this point.

## Design

### RadioPlayer class

Create `RadioPlayer.swift` as a singleton wrapping AVPlayer directly.

```swift
class RadioPlayer: ObservableObject {
    static let shared = RadioPlayer()

    @Published private(set) var state: State = .idle
    @Published private(set) var playbackState: PlaybackState = .stopped

    var isPlaying: Bool { playbackState == .playing }

    var radioURL: URL? {
        didSet { radioURLDidChange(radioURL) }
    }

    enum State {
        case idle          // No URL set
        case loading       // Buffering
        case readyToPlay   // Buffer sufficient
        case error         // AVPlayerItem failed
    }

    enum PlaybackState {
        case playing, stopped, paused
    }

    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var statusObservation: NSKeyValueObservation?
    private var bufferObservation: NSKeyValueObservation?
    private var timeControlObservation: NSKeyValueObservation?
}
```

**Key design decisions:**

- **No Reachability.** Network-aware restart is NowPlayingViewController's responsibility via the existing connectionState Combine sink. Single source of truth: if we can't get metadata (WebSocket down), we can't get music.
- **No metadata.** Azuracast WebSocket provides all metadata. `currentMetadata` and `currentArtworkURL` are deleted entirely, along with `enableArtwork`, `artworkAPI`, and the iTunes API integration.
- **@Published state** instead of FRadioPlayerObserver protocol. Consumers subscribe via Combine sinks. Already used in NowPlayingVC for connectionState.
- **Modern KVO** (`NSKeyValueObservation` closures) instead of `observeValue(forKeyPath:)`.

### Critical method: stop()

```swift
func stop() {
    player?.pause()
    player?.replaceCurrentItem(with: nil)  // Kills AVPlayer's connection entirely
    playbackState = .stopped
}
```

`replaceCurrentItem(with: nil)` is the fix for aggressive retries. Just `pause()` leaves the connection open and AVPlayer retries internally. This is the entire reason for the replacement.

### Audio session and system events

RadioPlayer handles in its `init()`:

1. **Audio session setup** — `.playback` category with `.allowAirPlay` and `.allowBluetoothA2DP` (same as FRadioPlayer).
2. **Interruption handling** — Phone calls, Siri: `.began` → pause, `.ended` with `.shouldResume` → play.
3. **Route change handling** — Headphones unplugged → pause.

**Removed vs FRadioPlayer:**

- No `Reachability` observer or `checkNetworkInterruption()` (source of aggressive retries)
- No `itemDidPlayToEnd` (live radio, not files)
- No `isPlayImmediately` (unnecessary complexity)
- No `seek()` / `duration` / `currentTime` (live stream only)

### Consumer changes (9 files)

#### Straightforward replacements

| File | Change |
|------|--------|
| `AppDelegate.swift` | Delete `isAutoPlay`, `enableArtwork`, `artworkAPI` config. Remote commands: `FRadioPlayer.shared` → `RadioPlayer.shared` |
| `SceneDelegate.swift` | `FRadioPlayer.shared.isPlaying` → `RadioPlayer.shared.isPlaying` |
| `CarPlaySceneDelegate.swift` | Change import only |
| `StationMetadataManager.swift` | Delete `player` property and `getFRadioPlayerMetadata()` entirely. Fallback chain simplifies to: Azuracast → ConfigClient+RadioStation → RadioStation defaults |
| `Handoffable.swift` | Replace `FRadioPlayer.shared.currentMetadata` with StationMetadataManager data |

#### Observer pattern → Combine

| File | Change |
|------|--------|
| `NowPlayingViewController.swift` | Delete `FRadioPlayerObserver` conformance + 4 delegate methods. Add `$playbackState` and `$state` Combine sinks. Existing connectionState sink stays as-is. |
| `StationsViewController.swift` | Delete `FRadioPlayerObserver` conformance. Add `$playbackState` sink for cell UI updates. Delete metadata observer (Azuracast handles it). |
| `StationsManager.swift` | Delete `FRadioPlayerObserver` conformance + metadata/artwork callbacks. Keep `player.radioURL = URL(...)` in station switching methods. |

#### Metadata cleanup

| File | Change |
|------|--------|
| `RadioStation.swift` | Delete `trackName` and `artistName` computed properties that read `FRadioPlayer.shared.currentMetadata`. Callers use StationMetadataManager instead. |

### What gets deleted

- **FRadioPlayer SPM dependency** — Removed from Xcode project package dependencies
- **~600 lines** of FRadioPlayer library code (including its bundled Reachability)
- **~80 lines** of metadata gymnastics across consumer files
- `FRadioPlayerObserver` protocol conformances in 3 files
- `FRadioPlayer.Metadata`, `FRadioPlayer.PlaybackState`, `FRadioPlayer.State` types
- `iTunesAPI` reference in AppDelegate
- `StationMetadataManager.getFRadioPlayerMetadata()` entire method
- `RadioStation.trackName` / `.artistName` FRadioPlayer-backed computed properties

### What gets added

- **`RadioPlayer.swift`** — ~120-line AVPlayer wrapper singleton
- **Combine sinks** in 3 files replacing observer callbacks
- **Centralized timestamped logging** — Small utility in ACWebSocketClient (from connection recovery handoff)

### State mapping

| FRadioPlayer | RadioPlayer |
|---|---|
| `FRadioPlayer.State.urlNotSet` | `RadioPlayer.State.idle` |
| `FRadioPlayer.State.loading` | `RadioPlayer.State.loading` |
| `FRadioPlayer.State.readyToPlay` | `RadioPlayer.State.readyToPlay` |
| `FRadioPlayer.State.loadingFinished` | `RadioPlayer.State.readyToPlay` (merged — distinction unnecessary) |
| `FRadioPlayer.State.error` | `RadioPlayer.State.error` |
| `FRadioPlayer.PlaybackState.*` | `RadioPlayer.PlaybackState.*` (same cases) |

## Testing

Device test after replacement:

1. Launch app, play station, confirm audio works
2. Turn off WiFi → verify audio stops cleanly (no accelerating retries in logs)
3. Turn WiFi back on → verify WebSocket reconnects, audio restarts via `wasPlaying` flag
4. Verify exponential backoff timing via timestamped logs
5. Test phone call interruption → audio pauses and resumes
6. Test headphone unplug → audio pauses
