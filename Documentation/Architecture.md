# Architecture

Screens and navigation use SwiftUI. UIKit remains at focused boundaries: CarPlay, the popup library, system presentations (Safari, mail, AirPlay and sharing), and small wrappers that keep the reference appearance and native accessibility: the seek slider, the gradient, the marquee title (`MarqueeText`), the equalizer and buffering indicators (`PlaybackActivityIndicator`), and the artwork containers (`CrossfadeImage`, `PlaybackArtworkImage`). Playback state stays outside those wrappers.

```
SwiftRadio/
  App/         SwiftRadioApp (@main), AppDelegate, AppEnvironment, RootView,
               ConfiguredStationsLoader, ArtworkLoaderKey, UITestRadioPlayer (Debug only)
  CarPlay/     CarPlaySceneDelegate and its observation helper
  Config/      Config, Content (String Catalog keys), InfoSection
  Data/        stations.json
  Features/    One folder per screen: Loading, Stations, NowPlaying, StationInfo, About
  Helpers/     Small Foundation extensions
  UI/          Views shared across screens: artwork, gradient, marquee, equalizer,
               AirPlay, Safari, mail, share sheet, share card
  Images.xcassets, Localizable.xcstrings, Info.plist, Info-CarPlay.plist

Packages/SwiftRadioCore/
  Models/      RadioStation, StationsResponse
  Stations/    StationsStore, the loader protocol, bundle and remote loaders,
               CatalogListContent (what a size-limited list shows)
  Playback/    PlayerService, the FRadioPlayer boundary, audio session, now playing info,
               remote commands
  Images/      ArtworkLoader
  Handoff/     HandoffActivity
```

- **`AppEnvironment`**: builds one `PlayerService`, one `StationsStore`, and one `ArtworkLoader` at launch. The phone scene and the CarPlay scene share those instances, so a station picked in the car updates the phone, the lock screen, and Control Center.
- **`RootView`**: shows `LoadingScreen` until the first catalog load settles, then a `NavigationStack` holding the station list, a `navigationDestination` for station info, and the popup player.
- **`SwiftRadioCore`**: a local Swift package that holds the models, the stores, and the only import of FRadioPlayer. It has no SwiftUI in it and carries the unit tests.
- **CarPlay**: the `SwiftRadio-CarPlay` target compiles the same sources with `-D CarPlay` and swaps in `Info-CarPlay.plist`. `CarPlaySceneDelegate` renders a `CPListTemplate` from the shared store:
  - **Catalog states**: a loading message while the first load runs, and a Retry row when loading failed or the catalog is empty, so the driver can recover without the phone.
  - **Item limit**: catalogs are paged within `CPListTemplate.maximumItemCount`, with a More row and at most four list pages so Now Playing fits the template-depth limit. Limits can change while driving.
  - **Selection**: tapping a station pushes the Now Playing template. Tapping the station that is already playing or buffering doesn't restart its stream, and a station whose stream URL can't be opened is ignored.

## The popup player

[LNPopupUI](https://github.com/LeoNatan/LNPopupUI) draws the bar above the station list and expands it into the full player.

- **Presentation**: `RootView` attaches `.popup(isBarPresented:isPopupOpen:)` to the `NavigationStack`. The bar shows whenever `StationsStore.currentStation` is set, including when CarPlay made the selection.
- **Bar content**: `NowPlayingView` feeds the title, artwork, progress, and play/pause button to the bar through `.popupTitle`, `.popupImage`, `.popupProgress`, and `.popupBarButtons`.
- **Full player**: the same view's body is the expanded content: blurred artwork backdrop, marquee title, transport controls, and the options sheet.
- **Sequencing**: options that leave the player (station info, station website) wait for the options sheet's `onDismiss`, close the popup, then run from `onClose`, so a push or a sheet never fights either dismissal animation.

## Audio session and system controls

- **Session**: `PlayerService` activates a non-mixable `.playback` session right before it loads, plays or seeks, never at launch. Opening the app doesn't stop other apps' audio; starting a station does.
- **Mixing**: set `Config.mixesWithOtherAudio = true` to keep other audio playing under the radio. A mixable session can't own the lock screen, Control Center or CarPlay Now Playing, so those controls stop working.
- **Remote commands**: live streams enable Stop and disable Pause, files do the opposite. Play, play/pause, next and previous stay enabled. With no station selected every command reports `.noActionableNowPlayingItem` and does nothing.
- **Now Playing info**: each update replaces the whole dictionary, so a live stream never keeps a file's scrubber or an old track's artwork. Clock ticks don't republish it: the system advances elapsed time from the published rate.

See the [SwiftRadioCore guide](../Packages/SwiftRadioCore/README.md) for service contracts and tests.
