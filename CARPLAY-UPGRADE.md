# CarPlay Framework Upgrade

## Overview

This document describes the modernization of RadioSpiral's CarPlay support from the deprecated `MPPlayableContentManager` API to the modern CarPlay framework (iOS 14+).

## What Changed

### Old Implementation (Deprecated)

**File:** `RadioSpiral/CarPlay/AppDelegate+CarPlay.swift`

Used the deprecated MediaPlayer framework APIs:
- `MPPlayableContentManager` - Deprecated since iOS 14
- `MPPlayableContentDelegate` - Deprecated
- `MPPlayableContentDataSource` - Deprecated
- `MPContentItem` - Still works but part of deprecated pattern

**Limitations:**
- Deprecated by Apple
- Not recommended for new implementations
- Limited customization
- Suboptimal UX on modern CarPlay systems
- Warning from App Store about deprecated APIs

### New Implementation (Modern)

**File:** `RadioSpiral/CarPlay/CarPlaySceneDelegate.swift`

Uses the modern CarPlay framework (iOS 14+):
- `CPTemplateApplicationSceneDelegate` - New scene delegate
- `CPTemplateApplicationScene` - CarPlay scene
- `CPListTemplate` - List of stations
- `CPListItem` - Individual station item
- `CPNowPlayingTemplate` - Now playing screen
- Integration with `MPNowPlayingInfoCenter` - For lock screen

**Advantages:**
- ✅ Modern, recommended by Apple
- ✅ Better UX on CarPlay systems
- ✅ Future-proof
- ✅ Proper template-based architecture
- ✅ No deprecation warnings
- ✅ Integrates with lock screen and Control Center

## Technical Details

### Scene Configuration

Added `UISceneConfigurations` to `Info.plist` for CarPlay:

```xml
<key>UISceneConfigurations</key>
<dict>
    <key>CPTemplateApplicationSceneSessionRoleApplication</key>
    <array>
        <dict>
            <key>UISceneClassName</key>
            <string>CPTemplateApplicationScene</string>
            <key>UISceneConfigurationName</key>
            <string>CarPlay Configuration</string>
            <key>UISceneDelegateClassName</key>
            <string>$(PRODUCT_MODULE_NAME).CarPlaySceneDelegate</string>
        </dict>
    </array>
</dict>
```

### CarPlaySceneDelegate Structure

```
CarPlaySceneDelegate (CPTemplateApplicationSceneDelegate)
├── templateApplicationScene(_:didConnect:to:)
│   └── Creates root stations list
├── templateApplicationScene(_:didDisconnect:to:)
│   └── Cleans up observations
├── createStationsListTemplate()
│   └── Returns CPListTemplate with all stations
├── createStationListItem(for:)
│   └── Creates selectable station CPListItem
├── selectStation(_:completionHandler:)
│   └── Handles station selection and playback
├── updateNowPlayingTemplate()
│   └── Updates now playing display
├── updateMPNowPlayingInfo(station:)
│   └── Updates lock screen and system info
└── subscribeToMetadataUpdates()
    └── Listens for real-time metadata changes
```

### Key Integration Points

**Station Selection:**
```
User taps station in CarPlay
  ↓
selectStation(_:completionHandler:)
  ├─ Set station in StationsManager
  ├─ Start FRadioPlayer
  ├─ Update now playing template
  └─ Push CPNowPlayingTemplate
```

**Metadata Updates:**
```
WebSocket receives metadata update
  ↓
ACWebSocketClient.addSubscriber()
  ↓
updateMPNowPlayingInfo()
  ├─ Update lock screen (MPNowPlayingInfoCenter)
  └─ Update CarPlay display
```

## Backwards Compatibility

The old `AppDelegate+CarPlay.swift` is still in the codebase but is now **deprecated**.

**Current status:**
- ⚠️ Still compiled and called on iOS 15
- ✅ Will NOT break anything
- ✅ Modern implementation takes precedence on iOS 14+
- ⏰ Should be removed in a future version

**Migration path:**
1. Current: Both old and new implementations can coexist
2. Future: Remove old MPPlayableContent code (AppDelegate+CarPlay.swift)

## Testing

### Manual Testing Checklist

- [ ] Launch app and connect to CarPlay simulator
- [ ] Verify stations list appears
- [ ] Select a station - verify playback starts
- [ ] Verify "Now Playing" screen appears
- [ ] Verify metadata updates in real-time
- [ ] Verify album art displays
- [ ] Verify lock screen shows correct metadata
- [ ] Stop playback and verify UI updates
- [ ] Disconnect CarPlay - verify cleanup

### Simulator Testing

```bash
# Build and run on simulator
# In Xcode Simulator menu: Simulate CarPlay
# Navigate to RadioSpiral app in CarPlay
```

Note: Simulator doesn't fully test CarPlay (no Bluetooth, limited features). Physical device testing with actual CarPlay system is recommended for complete validation.

## Performance Considerations

1. **Lazy Loading:** Station artwork is loaded asynchronously when needed
2. **Memory:** Station list is created once, updated when stations change
3. **Battery:** WebSocket connection maintains in background (already implemented)
4. **Network:** Real-time metadata updates only when actively playing

## Future Enhancements

Possible improvements for future versions:

1. **Playback Controls:**
   - Previous/Next station buttons
   - Skip forward/backward in metadata updates

2. **Search:**
   - CPSearchTemplate for finding stations
   - Filtered station lists

3. **Favorites:**
   - Mark favorite stations in CarPlay
   - Quick access tab

4. **Visual Improvements:**
   - Better artwork handling
   - Station information screen

## API Reference

### Key Classes

- **CPTemplateApplicationSceneDelegate** - Main delegate for CarPlay scene lifecycle
- **CPTemplateApplicationScene** - Represents the CarPlay interface
- **CPInterfaceController** - Controller for managing CarPlay templates
- **CPListTemplate** - Displays a scrollable list of items
- **CPListItem** - Individual selectable item in list
- **CPNowPlayingTemplate** - Now playing display (singleton)
- **MPNowPlayingInfoCenter** - System-wide now playing information

### Methods Called

- `setRootTemplate(_:animated:)` - Sets initial template
- `pushTemplate(_:animated:)` - Pushes new template onto stack
- `setImage(_:)` - Sets CPListItem artwork
- `handler` - Closure called when item is selected

## Resources

- [Apple CarPlay Documentation](https://developer.apple.com/carplay/)
- [CPTemplateApplicationSceneDelegate](https://developer.apple.com/documentation/carplay/cptemplateapplicationscenedelegate)
- [CPListTemplate](https://developer.apple.com/documentation/carplay/cplisttemplate)
- [CPNowPlayingTemplate](https://developer.apple.com/documentation/carplay/cpnowplayingtemplate)
- [WWDC 2020: Accelerate your app with CarPlay](https://developer.apple.com/videos/play/wwdc2020/10635/)

## Files Changed

- **Added:** `RadioSpiral/CarPlay/CarPlaySceneDelegate.swift` (new modern implementation)
- **Modified:** `RadioSpiral/Info.plist` (added scene configurations)
- **Deprecated:** `RadioSpiral/CarPlay/AppDelegate+CarPlay.swift` (old implementation still present)

## Next Steps

1. Test thoroughly on CarPlay simulator
2. Physical device testing with actual CarPlay head unit if available
3. Monitor for edge cases (connection/disconnection, metadata updates)
4. In a future version, remove deprecated `AppDelegate+CarPlay.swift`
