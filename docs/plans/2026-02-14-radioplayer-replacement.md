# RadioPlayer Replacement Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace FRadioPlayer with a direct AVPlayer wrapper (`RadioPlayer`) that gives us full control over the audio connection lifecycle, eliminating aggressive internal retries on network loss.

**Architecture:** Singleton `RadioPlayer` wrapping AVPlayer with `@Published` state properties. No internal reachability — network-aware restart handled by NowPlayingVC's existing connectionState Combine sink. No metadata — Azuracast WebSocket is the sole metadata source.

**Tech Stack:** AVFoundation (AVPlayer, AVPlayerItem, AVAudioSession), Combine (@Published), KVO (NSKeyValueObservation)

**Design doc:** `docs/plans/2026-02-14-radioplayer-replacement-design.md`

---

### Task 1: Create RadioPlayer.swift

**Files:**
- Create: `RadioSpiral/Player/RadioPlayer.swift`
- Add to Xcode project build phase (RadioSpiral target)

**Step 1: Create RadioPlayer.swift**

Create `RadioSpiral/Player/RadioPlayer.swift` with the full implementation:

```swift
import AVFoundation
import Combine

/// Direct AVPlayer wrapper for internet radio streaming.
/// No internal reachability — network-aware restart is the caller's responsibility.
/// No metadata parsing — Azuracast WebSocket provides all metadata.
class RadioPlayer: ObservableObject {

    static let shared = RadioPlayer()

    // MARK: - Published State

    @Published private(set) var state: State = .idle
    @Published private(set) var playbackState: PlaybackState = .stopped

    var isPlaying: Bool { playbackState == .playing }

    var radioURL: URL? {
        didSet { radioURLDidChange(radioURL) }
    }

    // MARK: - State Enums

    enum State {
        case idle          // No URL set
        case loading       // Buffering
        case readyToPlay   // Buffer sufficient
        case error         // AVPlayerItem failed
    }

    enum PlaybackState {
        case playing, stopped, paused
    }

    // MARK: - Private

    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var statusObservation: NSKeyValueObservation?
    private var bufferObservation: NSKeyValueObservation?
    private var timeControlObservation: NSKeyValueObservation?

    // MARK: - Init

    private init() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default,
                                 options: [.allowAirPlay, .allowBluetoothA2DP])

        NotificationCenter.default.addObserver(
            self, selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        tearDownObservations()
    }

    // MARK: - Playback Control

    func play() {
        guard let player = player else { return }
        if player.currentItem == nil, let item = playerItem {
            player.replaceCurrentItem(with: item)
        }
        player.play()
        playbackState = .playing
    }

    func pause() {
        player?.pause()
        playbackState = .paused
    }

    func stop() {
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        playbackState = .stopped
    }

    // MARK: - URL Change

    private func radioURLDidChange(_ url: URL?) {
        tearDownObservations()
        stop()
        playerItem = nil
        player = nil

        guard let url = url else {
            state = .idle
            return
        }

        state = .loading
        let asset = AVURLAsset(url: url)
        playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: playerItem!)
        player?.allowsExternalPlayback = false

        setupObservations()
    }

    // MARK: - KVO

    private func setupObservations() {
        guard let item = playerItem else { return }

        statusObservation = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            DispatchQueue.main.async {
                switch item.status {
                case .readyToPlay:
                    self?.state = .readyToPlay
                case .failed:
                    self?.state = .error
                default:
                    break
                }
            }
        }

        bufferObservation = item.observe(\.isPlaybackBufferEmpty, options: [.new]) { [weak self] item, _ in
            DispatchQueue.main.async {
                if item.isPlaybackBufferEmpty {
                    self?.state = .loading
                }
            }
        }

        // Track when buffer recovers
        item.observe(\.isPlaybackLikelyToKeepUp, options: [.new]) { [weak self] item, _ in
            DispatchQueue.main.async {
                if item.isPlaybackLikelyToKeepUp {
                    self?.state = .readyToPlay
                }
            }
        }
    }

    private func tearDownObservations() {
        statusObservation?.invalidate()
        statusObservation = nil
        bufferObservation?.invalidate()
        bufferObservation = nil
        timeControlObservation?.invalidate()
        timeControlObservation = nil
    }

    // MARK: - System Events

    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        switch type {
        case .began:
            DispatchQueue.main.async { self.pause() }
        case .ended:
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { break }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            DispatchQueue.main.async { options.contains(.shouldResume) ? self.play() : self.pause() }
        @unknown default:
            break
        }
    }

    @objc private func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }

        if reason == .oldDeviceUnavailable {
            // Headphones unplugged
            DispatchQueue.main.async { self.pause() }
        }
    }
}
```

**Step 2: Add to Xcode project**

Add `RadioSpiral/Player/RadioPlayer.swift` to the RadioSpiral target's Compile Sources build phase in `project.pbxproj`. Generate a unique file reference ID and add entries to:
- PBXFileReference section
- PBXBuildFile section
- PBXGroup section (create `Player` group under RadioSpiral)
- Compile Sources build phase

**Step 3: Verify build**

Run: `xcodebuild build -scheme RadioSpiral -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -5`
Expected: BUILD SUCCEEDED (RadioPlayer.swift compiles but isn't used yet)

**Step 4: Commit**

```
Add RadioPlayer: direct AVPlayer wrapper replacing FRadioPlayer
```

---

### Task 2: Migrate StationsManager (station switching)

**Files:**
- Modify: `RadioSpiral/Model/StationsManager.swift`

StationsManager is the hub for station switching — it sets `player.radioURL` in 5 places. Migrate it first since other files depend on stations being set correctly.

**Step 1: Replace import and player property**

- Line 10: `import FRadioPlayer` → remove
- Line 55: `private let player = FRadioPlayer.shared` → `private let player = RadioPlayer.shared`

**Step 2: Remove observer registration**

- Line 60: Delete `self.player.addObserver(self)`

**Step 3: Delete FRadioPlayerObserver extension**

Delete lines 232-243 (the entire `extension StationsManager: FRadioPlayerObserver` block). These metadata/artwork callbacks triggered `metadataManager.triggerMetadataUpdate()`, but Azuracast WebSocket already drives metadata updates through its own observer chain.

**Step 4: Add Combine subscription for metadata trigger (if needed)**

Check if `metadataManager.triggerMetadataUpdate()` is still needed from StationsManager. If Azuracast metadata updates already flow without it, skip this. If needed, add a Combine sink on `RadioPlayer.shared.$playbackState` that calls `metadataManager.triggerMetadataUpdate()` when playback starts.

**Step 5: Verify build**

Run: `xcodebuild build -scheme RadioSpiral -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 6: Commit**

```
Migrate StationsManager from FRadioPlayer to RadioPlayer
```

---

### Task 3: Migrate NowPlayingViewController (playback UI + observers)

**Files:**
- Modify: `RadioSpiral/ViewControllers/NowPlayingViewController.swift`

This is the most complex migration. NowPlayingVC has 4 FRadioPlayerObserver callbacks, direct player control, and the existing connectionState Combine sink.

**Step 1: Replace import and player property**

- Line 14: `import FRadioPlayer` → remove
- Line 45: `private let player = FRadioPlayer.shared` → `private let player = RadioPlayer.shared`

**Step 2: Remove observer registration**

- Line 66: Delete `player.addObserver(self)`

**Step 3: Add Combine sinks for playback and state**

In `setupPlayer()` (around line 100, after the existing connectionState sink), add:

```swift
// Observe playback state changes (replaces FRadioPlayerObserver.playbackStateDidChange)
RadioPlayer.shared.$playbackState
    .receive(on: DispatchQueue.main)
    .sink { [weak self] playbackState in
        guard let self = self else { return }
        self.playbackStateDidChange(playbackState, animate: true)
    }
    .store(in: &cancellables)

// Observe player state changes (replaces FRadioPlayerObserver.playerStateDidChange)
RadioPlayer.shared.$state
    .receive(on: DispatchQueue.main)
    .sink { [weak self] state in
        guard let self = self else { return }
        self.playerStateDidChange(state, animate: true)
    }
    .store(in: &cancellables)
```

**Step 4: Update playerStateDidChange to use RadioPlayer.State**

Change method signature and switch cases (lines 295-315):

```swift
func playerStateDidChange(_ state: RadioPlayer.State, animate: Bool) {
    let message: String?
    switch state {
    case .loading:
        if songLabel.text != "" {
            message = songLabel.text
        } else {
            message = "Station loading..."
        }
    case .idle:
        message = "Station URL not valid"
    case .readyToPlay:
        playbackStateDidChange(player.playbackState, animate: animate)
        return
    case .error:
        message = "Error playing stream"
    }
    updateLabels(with: message, animate: animate)
}
```

Note: `.urlNotSet` → `.idle`, `.readyToPlay` and `.loadingFinished` merged into `.readyToPlay`.

**Step 5: Update playbackStateDidChange to use RadioPlayer.PlaybackState**

Change method signature (lines 278-293):

```swift
func playbackStateDidChange(_ playbackState: RadioPlayer.PlaybackState, animate: Bool) {
    let message: String?
    switch playbackState {
    case .paused:
        message = "Station Paused..."
    case .playing:
        message = nil
    case .stopped:
        message = "Station Stopped..."
    }
    updateLabels(with: message, animate: animate)
    isPlayingDidChange(player.isPlaying)
}
```

**Step 6: Delete FRadioPlayerObserver extension**

Delete lines 438-455 (the entire `extension NowPlayingViewController: FRadioPlayerObserver` block).

**Step 7: Verify build**

Run: `xcodebuild build -scheme RadioSpiral -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 8: Commit**

```
Migrate NowPlayingViewController from FRadioPlayer to RadioPlayer
```

---

### Task 4: Migrate StationsViewController (cell animation)

**Files:**
- Modify: `RadioSpiral/ViewControllers/StationsViewController.swift`

**Step 1: Replace import and player property**

- Line 10: `import FRadioPlayer` → remove
- Line 23: `private let player = FRadioPlayer.shared` → `private let player = RadioPlayer.shared`

**Step 2: Add Combine infrastructure**

Add to properties (near line 23):
```swift
private var cancellables = Set<AnyCancellable>()
```

Add `import Combine` at the top of the file.

**Step 3: Remove observer registration, add Combine sink**

- Line 74: Delete `player.addObserver(self)`

Add in `viewDidLoad()` where the observer was:

```swift
RadioPlayer.shared.$playbackState
    .receive(on: DispatchQueue.main)
    .sink { [weak self] _ in
        guard let self = self else { return }
        self.startNowPlayingAnimation(self.player.isPlaying)
    }
    .store(in: &cancellables)
```

**Step 4: Fix updateNowPlayingButton metadata reference**

Line 129: `player.currentMetadata != nil` → This fallback branch used FRadioPlayer metadata. Since all metadata comes from Azuracast now, simplify to just use metadataManager:

```swift
// Remove the `else if player.currentMetadata != nil` branch entirely.
// The metadataManager check already covers it, and the final else
// falls back to station name.
```

**Step 5: Delete FRadioPlayerObserver extension**

Delete lines 266-276 (the entire `extension StationsViewController: FRadioPlayerObserver` block).

**Step 6: Verify build**

Run: `xcodebuild build -scheme RadioSpiral -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 7: Commit**

```
Migrate StationsViewController from FRadioPlayer to RadioPlayer
```

---

### Task 5: Migrate simple files (AppDelegate, SceneDelegate, CarPlay)

**Files:**
- Modify: `RadioSpiral/AppDelegate.swift`
- Modify: `RadioSpiral/SceneDelegate.swift`
- Modify: `RadioSpiral/CarPlay/CarPlaySceneDelegate.swift`

**Step 1: AppDelegate.swift**

- Line 11: `import FRadioPlayer` → remove
- Lines 18-21: Delete the FRadioPlayer config block:
  ```swift
  // DELETE: FRadioPlayer.shared.isAutoPlay = true
  // DELETE: FRadioPlayer.shared.enableArtwork = true
  // DELETE: FRadioPlayer.shared.artworkAPI = iTunesAPI(artworkSize: 600)
  ```
- Lines 75, 81, 87-90: Replace `FRadioPlayer.shared` with `RadioPlayer.shared` in remote command handlers

**Step 2: SceneDelegate.swift**

- Line 9: `import FRadioPlayer` → remove
- Line 46: `FRadioPlayer.shared.isPlaying` → `RadioPlayer.shared.isPlaying`

**Step 3: CarPlaySceneDelegate.swift**

- Line 10: `import FRadioPlayer` → remove (no other changes needed)

**Step 4: Verify build**

Run: `xcodebuild build -scheme RadioSpiral -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 5: Commit**

```
Migrate AppDelegate, SceneDelegate, CarPlaySceneDelegate from FRadioPlayer
```

---

### Task 6: Migrate metadata files (StationMetadataManager, RadioStation, Handoffable)

**Files:**
- Modify: `RadioSpiral/Model/StationMetadataManager.swift`
- Modify: `RadioSpiral/Model/RadioStation.swift`
- Modify: `RadioSpiral/Helpers/Handoffable.swift`

**Step 1: StationMetadataManager.swift**

- Line 10: `import FRadioPlayer` → remove
- Line 72: Delete `private let player = FRadioPlayer.shared`
- Lines 223-235: Delete entire `getFRadioPlayerMetadata()` method
- Lines 199: In `getUnifiedMetadata()`, remove the FRadioPlayer fallback branch:
  ```swift
  // DELETE:
  // if let fradioMetadata = getFRadioPlayerMetadata() {
  //     return fradioMetadata
  // }
  ```
  The fallback chain becomes: Azuracast → ConfigClient+RadioStation fallback → station defaults.

**Step 2: RadioStation.swift**

- Line 10: `import FRadioPlayer` → remove
- Lines 98-104: Delete both computed properties:
  ```swift
  // DELETE:
  // var trackName: String {
  //     FRadioPlayer.shared.currentMetadata?.trackName ?? name
  // }
  // var artistName: String {
  //     FRadioPlayer.shared.currentMetadata?.artistName ?? desc
  // }
  ```

After deleting these, check all callers of `station.trackName` and `station.artistName`. These callers should either:
- Already use `metadataManager.getCurrentMetadata()` (likely), or
- Fall back to `station.name` / `station.desc` directly

**Step 3: Handoffable.swift**

- Line 10: `import FRadioPlayer` → remove
- Lines 34-39: Replace FRadioPlayer fallback with graceful handling:
  ```swift
  // The metadataManager check on line 30 already gets Azuracast metadata.
  // The FRadioPlayer fallback is redundant. Just let the else branch
  // set activity.webpageURL = nil (no metadata available).
  ```
  Delete the `else { guard let metadata = FRadioPlayer.shared.currentMetadata ... }` block. If metadataManager has no metadata, there's no metadata.

**Step 4: Verify build**

Run: `xcodebuild build -scheme RadioSpiral -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -5`
Expected: BUILD SUCCEEDED (no more FRadioPlayer references in Swift code)

**Step 5: Commit**

```
Remove FRadioPlayer metadata dependencies from StationMetadataManager, RadioStation, Handoffable
```

---

### Task 7: Remove FRadioPlayer SPM dependency

**Files:**
- Modify: `RadioSpiral.xcodeproj/project.pbxproj`

**Step 1: Remove from project.pbxproj**

Remove these entries (search for `FRadioPlayer` in the file):

1. **PBXBuildFile** (line 58): Delete the line containing `CE37D7B7290F4A9700B0933B /* FRadioPlayer in Frameworks */`
2. **Frameworks build phase** (line 174): Delete the line `CE37D7B7290F4A9700B0933B /* FRadioPlayer in Frameworks */,`
3. **Package product dependency ref** (line 432): Delete the line `CE37D7B6290F4A9700B0933B /* FRadioPlayer */,`
4. **Package reference** (line 485): Delete the line `CE37D7B5290F4A9700B0933B /* XCRemoteSwiftPackageReference "FRadioPlayer" */,`
5. **XCRemoteSwiftPackageReference** (lines 980-986): Delete the entire block
6. **XCSwiftPackageProductDependency** (lines 1024-1028): Delete the entire block

**Step 2: Verify build**

Run: `xcodebuild build -scheme RadioSpiral -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -5`
Expected: BUILD SUCCEEDED with no FRadioPlayer dependency

**Step 3: Verify no remaining references**

Search codebase for any remaining `FRadioPlayer` references:
```bash
grep -r "FRadioPlayer" RadioSpiral/ --include="*.swift"
grep "FRadioPlayer" RadioSpiral.xcodeproj/project.pbxproj
```
Expected: No matches

**Step 4: Commit**

```
Remove FRadioPlayer SPM dependency
```

---

### Task 8: Add centralized timestamped logging

**Files:**
- Modify: `RadioSpiral/ACWebSocketClient/ACWebSocketClient.swift`

This was item 1 from the connection recovery handoff. Add a simple logging utility to ACWebSocketClient so all debug messages have timestamps for device test log analysis.

**Step 1: Add logging method**

Add a static or private method to ACWebSocketClient:

```swift
/// Centralized debug logging with ISO timestamps and component tags.
/// Usage: debugLog("[Connect]", "State set to connecting", ACConnectivityChecks)
private func debugLog(_ tag: String, _ message: String, _ flag: Int = ACConnectivityChecks) {
    guard debugLevel & flag != 0 else { return }
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    let timestamp = formatter.string(from: Date())
    print("\(timestamp) \(tag) \(message)")
}
```

**Step 2: Replace inline print() calls**

Replace all `if self.debugLevel & ACConnectivityChecks != 0 { print("[Tag] message") }` patterns with `debugLog("[Tag]", "message")`. This is a mechanical replacement across the file — approximately 25 inline print blocks.

**Step 3: Verify build**

Run: `xcodebuild build -scheme RadioSpiral -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 4: Commit**

```
Add centralized timestamped logging to ACWebSocketClient
```

---

### Task 9: Device test

**No code changes — manual testing on physical device.**

Run the full WiFi drop/restore test:

1. Build and deploy to device
2. Launch app, play a station, confirm audio + metadata working
3. Turn off WiFi
   - Verify: audio stops cleanly (check Xcode console — no accelerating connection attempts)
   - Verify: WebSocket schedules reconnect with exponential backoff (check timestamps)
4. Turn WiFi back on
   - Verify: WebSocket reconnects (metadata resumes)
   - Verify: audio restarts automatically via `wasPlaying` flag
   - Verify: exponential backoff timing correct via timestamped logs
5. Test phone call interruption → audio pauses and resumes
6. Test headphone unplug → audio pauses

If any test fails, fix and re-test before committing.

---

## Task Summary

| Task | Description | Files | Risk |
|------|-------------|-------|------|
| 1 | Create RadioPlayer.swift | 1 new | Low — additive only |
| 2 | Migrate StationsManager | 1 modified | Medium — station switching hub |
| 3 | Migrate NowPlayingViewController | 1 modified | Medium — most complex observer migration |
| 4 | Migrate StationsViewController | 1 modified | Low — simple observer replacement |
| 5 | Migrate AppDelegate, SceneDelegate, CarPlay | 3 modified | Low — straightforward replacements |
| 6 | Remove metadata dependencies | 3 modified | Medium — callers of deleted properties need checking |
| 7 | Remove FRadioPlayer SPM dependency | 1 modified (pbxproj) | Low — mechanical removal |
| 8 | Centralized timestamped logging | 1 modified | Low — additive |
| 9 | Device test | 0 | High — validates everything |
