# Swift Radio

[![iOS build](https://github.com/analogcode/Swift-Radio-Pro/actions/workflows/ios.yml/badge.svg)](https://github.com/analogcode/Swift-Radio-Pro/actions/workflows/ios.yml)
[![CarPlay build](https://github.com/analogcode/Swift-Radio-Pro/actions/workflows/carplay.yml/badge.svg)](https://github.com/analogcode/Swift-Radio-Pro/actions/workflows/carplay.yml)

Open-source iOS radio app with a SwiftUI interface. Used by **80+ apps** on the App Store.

<p align="center">
    <img alt="Swift Radio" src="swift-radio-preview.png" width="700">
</p>

**Looking for Android?** See [Swift Radio Android](https://github.com/fethica/Swift-Radio-Android). Same station format, native Kotlin and Jetpack Compose.

## Features

- Stream live radio with background audio playback
- Scrubber and progress bar for non-live streams
- Apple CarPlay support
- Album art and track metadata from streams and iTunes API
- Lock screen and Control Center integration
- Multiple stations from a local or remote JSON file
- Pull to refresh and optional search bar
- Localization-ready via Xcode String Catalog
- About screen with email, sharing, and external links

Built on [FRadioPlayer](https://github.com/fethica/FRadioPlayer) for streaming, metadata parsing, and iTunes album art fetching.

## Requirements

- **iOS 17 or later**: the deployment target of the app target, the CarPlay target, and the `SwiftRadioCore` package.
- **Xcode 26.6 or later**: CI builds the app and CarPlay targets with Xcode 26.6 and 27.0. The test suites are run with Xcode 27.
- **Swift 6 language mode** for the app targets and `SwiftRadioCore`, with complete concurrency checking.

Dependencies resolve through Swift Package Manager, so there's nothing to install before the first build.

## Getting Started

1. Open `SwiftRadio.xcodeproj` in Xcode
2. Edit `SwiftRadio/Config/Config.swift` to set your stations URL, contact email, website, and other app-wide settings
3. Update your stations in `SwiftRadio/Data/stations.json` or host the file remotely
4. Build and run

### Adding a station

1. Add an entry to `SwiftRadio/Data/stations.json`, or to the JSON you host at `Config.stationsURL`
2. Add a square image to `SwiftRadio/Images.xcassets/Stations/` and name the image set exactly like the station's `imageURL`
3. Build and run: no code change is needed

Each station supports these fields:

```json
{
  "name": "Station Name",
  "streamURL": "https://stream.example.com/live",
  "imageURL": "station-image",
  "desc": "Short tagline",
  "longDesc": "Longer description for the detail screen",
  "website": "https://example.com"
}
```

- **`imageURL`**: an asset name for a bundled image, a full `http(s)` URL for a remote one, or an empty string to fall back to the `stationImage` placeholder.
- **`website`**: optional. The "Visit Website" row and the popup's website option appear only when it starts with `http` or `https`.
- **`longDesc`**: optional. Omit the key or leave it empty and the station info screen shows a default description.

### Forking for one station

The template works at any catalog size, so a single-station app is mostly configuration:

- **Trim the catalog**: leave one entry in `stations.json` and keep `Config.useLocalStations = true`.
- **Drop the controls it doesn't need**: set `Config.hideNextPreviousButtons = true` and leave `Config.searchable = false`.
- **Open on the player**: call `StationsStore.select(_:)` once the catalog loads and set `RootView`'s `popupOpen` to `true`. The one-row list stays behind the player as the back destination.
- **Rebrand**: replace `logo` and the station image in `Images.xcassets`, then edit the strings in `Localizable.xcstrings`.

### Customizing text and translation

All user-facing strings are managed through `Localizable.xcstrings` (the String Catalog). Open it in Xcode to change the default English text or add new languages. Most views read their strings through `Content.swift`; a few accessibility labels in the player and toolbar use their catalog keys directly (`player.next`, `player.seek`, `common.close` and similar). Either way the text lives in the catalog, so a translation needs no code change.

## Architecture

SwiftUI owns the app's screens and navigation. `AppEnvironment` creates shared services for the phone and CarPlay, so both interfaces use the same station selection and playback state.

`SwiftRadioCore` is a local Swift package that separates playback, station catalogs, artwork and system-media integration from presentation. Its dependency boundaries let us test playback and catalog behavior without launching the UI. Small UIKit adapters remain for the popup player, marquee text, indicators and system presentations.

See the [SwiftRadioCore guide](Packages/SwiftRadioCore/README.md) for service boundaries and the [architecture guide](Documentation/Architecture.md) for the source map, popup flow and system controls.

## Testing

Run the core tests from `Packages/SwiftRadioCore` using the [package guide](Packages/SwiftRadioCore/README.md). They cover playback, catalog refresh, remote commands, Now Playing and interruptions without live streams.

The [visual parity protocol](Documentation/SwiftUIParity.md) covers screenshots, accessibility and UI regression commands. [CI](https://github.com/analogcode/Swift-Radio-Pro/actions) also builds both app targets and validates an unsigned archive. Physical-device audio routes, lock-screen controls and CarPlay remain separate acceptance checks.

## Dependencies

| Library | Purpose |
|---------|---------|
| [FRadioPlayer](https://github.com/fethica/FRadioPlayer) | Audio playback, stream metadata and artwork lookup, behind SwiftRadioCore |
| [LNPopupUI](https://github.com/LeoNatan/LNPopupUI) | SwiftUI popup bar and expanded player |
| [MarqueeLabel](https://github.com/cbpowell/MarqueeLabel) | Scrolling title in the expanded player |
| [NVActivityIndicatorView](https://github.com/ninjaprox/NVActivityIndicatorView) | Playback equalizer and buffering animations |

Swift Package Manager manages these libraries. LNPopupUI also brings in LNPopupController, LNSwiftUIUtils and, through LNPopupController, LNSystemMarqueeLabel. `SwiftRadioCore` is included in this repository as a local package. The checked-in lockfiles record the exact resolved versions.

## Contributing

Contributions are welcome. Please branch off [`dev`](https://github.com/analogcode/Swift-Radio-Pro/tree/dev) and open a pull request. Do not commit directly to `master`.

## Single Station Version

Looking for a simpler, single-station version? It skips the station list and launches straight into the player. One purchase now includes **both the iOS and Android** single-station projects.

[![Buy on Payhip](https://img.shields.io/badge/Buy-Single%20Station%20iOS%20%2B%20Android-blue)](https://payhip.com/b/x15QB)

All proceeds go directly toward maintaining and improving Swift Radio.

For custom work or more advanced needs, reach out to [Fethi](mailto:contact@fethica.com).

**Built something with Swift Radio?** We'd love to see it. Drop us a line at [contact@fethica.com](mailto:contact@fethica.com).

## Credits

- [Fethi](https://fethica.com), co-organizer and lead developer
- [Matthew Fecher](http://matthewfecher.com), creator, [AudioKit Pro](https://audiokitpro.com)
- [All contributors](https://github.com/analogcode/Swift-Radio-Pro/graphs/contributors)

## License

Swift Radio is open source and available under the [MIT License](LICENSE).
