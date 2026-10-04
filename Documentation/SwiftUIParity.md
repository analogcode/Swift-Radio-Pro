# SwiftUI visual parity

The UIKit app is the visual and behavioral reference. A successful build alone is not parity approval. Compare both implementations on the same device, OS build, appearance, text size, language, station and playback state. Accessibility layouts should preserve all content and actions rather than copy clipping in a fixed-height reference.

## Ownership and extension points

- `AppEnvironment` creates one shared playback/catalog composition for the phone and CarPlay. Views must not create another engine or system remote-command registration.
- `SwiftRadioCore` owns playback state, station loading, artwork identity and system metadata. Its injected boundaries support network-free unit tests; see the package README.
- `RootView` owns navigation and popup presentation. An options action queues its destination, waits for the sheet's `onDismiss`, closes the popup, then navigates from the popup's completion callback. Do not substitute arbitrary delays or unstructured tasks for dismissal completion.
- Player sections receive the values they display. Playback time belongs in the transport/timeline subtree; avoid passing an aggregate model snapshot through every catalog row.
- The native seek slider is a small `UIViewRepresentable` boundary for UIKit's track/thumb appearance and adjustable accessibility. Selection and scrubbing state remain in SwiftUI. Decorative backgrounds must never determine foreground layout size.
- `MarqueeText` wraps the same MarqueeLabel version and configuration as UIKit: continuous motion at 30pt/s, 10pt edge fades, 30pt trailing buffer. Identical metadata must not restart it on every playback tick. The library owns window/app lifecycle; teardown shuts the label down. Reduce Motion and accessibility text sizes use wrapping text instead.
- Equalizer and buffering views use the reference NVActivityIndicatorView implementation. A native container starts them only after layout supplies a nonzero frame, and explicitly stops them on state changes and teardown; the toolbar is absent while paused/stopped. Never use a persistent `repeatForever` animation as a substitute for an engine with explicit cancellation. Check that the playing indicator is actually visible before accepting a stopped-state comparison.
- The row removes the equalizer's layout space when paused/stopped, matching a hidden UIKit stack arranged subview. Only the subdued selected-artwork ring remains; a paused row must not retain an empty subtitle indent.
- Artwork replacement cross-dissolves at 0.3s (foreground) and 0.5s (background); buffering fades at 0.3s. Reduce Motion disables these transitions. Native image containers accept the proposed size rather than propagating image intrinsic dimensions.
- Expanded artwork keeps a small native presentation boundary for UIKit's exact 0.5s/damping-0.7 scale animation, buffering overlay and fixed outer shadow. Async artwork resolution and playback state remain in SwiftUI/shared services.
- Sharing queues its payload on the player and presents only after Options dismisses. Cancelling must return directly to the player, including on repeated presentations; do not restore the old nested sheet stack.
- The diagonal background wraps `CAGradientLayer` with the reference's colors and locations. Matching normalized endpoints in `LinearGradient` did not produce the same tall-screen rendering in the simulator comparison.
- Station cards keep native `Button` activation/cancellation. Their feedback completes a short activation pulse as well as reflecting held presses, so quick taps do not depend on a transient pressed frame. Reduce Motion substitutes opacity feedback for scaling; do not add a zero-distance drag gesture that competes with list scrolling.
- The options sheet sizes itself to its measured list content (iOS 18+), so row and section metrics can differ between OS releases without a gap or clipping. iOS 17 uses an estimate from the scaled row height.
- CarPlay pages a catalog longer than the head unit's list limit: each page ends with a More row that pushes the next page. Four pages at most, so Now Playing still fits CarPlay's template depth; pushed pages follow a runtime limit change.
- Use `Config`, `Content`, `stations.json` and the asset catalog for branding/content. Changing station data or About sections must not require editing navigation or the playback engine.
- Retain the iOS 17 deployment floor. Newer presentation APIs need availability handling; changing the whole app's minimum version is not a styling fix.

## Comparison protocol

1. Build UIKit and SwiftUI separately, then install on separate simulators with matching hardware/runtime. They use the same bundle identifier, so do not install one over the other during a comparison.
2. Set dark appearance, English, default `large` content size and the same status-bar overrides. Capture raw screenshots without frames, resizing or retouching.
3. Compare initial catalog, selected/playing/buffering cards, collapsed popup, expanded live/file player, options, station info, About and its destinations. Check search, refresh, previous/next, seeking, close/reopen and sheet handoffs.
4. For file playback, pause and seek to the same elapsed time before pixel comparison. Exclude genuinely volatile OS/status-bar content from numerical comparison, not app-layout differences.
5. Repeat with accessibility text sizes and Reduce Motion. Inspect the accessibility hierarchy and actual hit targets, not screenshots alone. Small windows/landscape may scroll; every control must remain reachable.
6. Retain screenshots, runtime details and test results with the review. Record remaining differences explicitly rather than calling a close match pixel-perfect.

The initial iPhone 18 Pro / stable iOS 27 comparison identified catalog spacing/materials, an overflowing full-screen player, options sizing, and About/info typography differences. The current work addresses those areas; final visual acceptance is still pending.

## Regression checks

From the repository root, using a simulator destination available on the machine:

```sh
xcodebuild test -project SwiftRadio.xcodeproj -scheme SwiftRadio \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro,OS=27.0' \
  -only-testing:SwiftRadioUITests/SwiftRadioUITests/testStationsListRenders \
  -only-testing:SwiftRadioUITests/SwiftRadioUITests/testPlayerControlsFitAndOptionsNavigate \
  -only-testing:SwiftRadioUITests/SwiftRadioUITests/testAboutFeaturesNavigationAndDismissal
```

The layout/navigation test does not wait for an internet station to begin playback. The separate `testPopupNavigationAndRefresh` is a live-stream integration test and can fail because a third-party stream is unavailable. Run core tests from `Packages/SwiftRadioCore`, not the app project's generated package scheme.

Run the full app suite (omit `-only-testing`) for deterministic Stop/resume, file Pause/seek, marquee scrolling after reopen and foreground, repeated Share/cancel, row cancellation/reselection, previous/next wraparound, website handoff and library-link coverage. These tests launch with `--ui-test-playback`: Debug builds inject a deterministic `RadioPlaying` implementation at the existing composition boundary; Release builds exclude it. The real catalog, stores, navigation and animation views still run. Keep a separate real-stream integration test: a fake engine cannot validate AVPlayer or audio routing. Swift Debug compilation explicitly defines `DEBUG`; a C preprocessor `DEBUG=1` alone does not enable Swift fixtures.

Static screenshots do not prove that a title scrolls or that an equalizer animates, so the UI tests compare element screenshots over time: the toolbar equalizer must change while playing and disappear when paused or stopped, and the long fixture title must move after first open, after reopening the popup and after returning to the foreground. They do not check that identical metadata leaves a running marquee alone, or animation timing; use a recording for those. Core seek tests deliberately deliver stale time events before completion and out-of-order completions, and run against a fake with FRadioPlayer 0.4's independent seek and interruption-intent behavior. Adversarial late events separately test the app's transport guards; real-engine seek tests exercise the released package.

Physical-device audio interruptions, route changes, lock-screen controls, CarPlay and the oldest supported OS remain separate acceptance gates. Core tests reproduce the engine's interruption and route-change handlers, but simulator and unit test success does not prove those behaviors on hardware.

## Guidance

The implementation follows Apple's SwiftUI guidance on [performance](https://developer.apple.com/documentation/xcode/understanding-and-improving-swiftui-performance) (small view sections, per-property Observation, stable list identity) and [localization](https://developer.apple.com/documentation/swiftui/preparing-views-for-localization). Presentation behavior is checked against Apple's [modal presentation documentation](https://developer.apple.com/documentation/swiftui/modal-presentations) and [custom detents](https://developer.apple.com/documentation/swiftui/custompresentationdetent). Native controls retain their accessibility semantics; accessibility content uses wrapping text instead of a continuously moving marquee.
