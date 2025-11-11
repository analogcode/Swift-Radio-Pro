import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 11.0, macOS 10.13, tvOS 11.0, *)
extension ColorResource {

}

// MARK: - Image Symbols -

@available(iOS 11.0, macOS 10.7, tvOS 11.0, *)
extension ImageResource {

    /// The "NowPlayingBars" asset catalog image resource.
    static let nowPlayingBars = ImageResource(name: "NowPlayingBars", bundle: resourceBundle)

    /// The "NowPlayingBars-0" asset catalog image resource.
    static let nowPlayingBars0 = ImageResource(name: "NowPlayingBars-0", bundle: resourceBundle)

    /// The "NowPlayingBars-1" asset catalog image resource.
    static let nowPlayingBars1 = ImageResource(name: "NowPlayingBars-1", bundle: resourceBundle)

    /// The "NowPlayingBars-2" asset catalog image resource.
    static let nowPlayingBars2 = ImageResource(name: "NowPlayingBars-2", bundle: resourceBundle)

    /// The "NowPlayingBars-3" asset catalog image resource.
    static let nowPlayingBars3 = ImageResource(name: "NowPlayingBars-3", bundle: resourceBundle)

    /// The "albumArt" asset catalog image resource.
    static let albumArt = ImageResource(name: "albumArt", bundle: resourceBundle)

    /// The "az-rock-radio" asset catalog image resource.
    static let azRockRadio = ImageResource(name: "az-rock-radio", bundle: resourceBundle)

    /// The "background" asset catalog image resource.
    static let background = ImageResource(name: "background", bundle: resourceBundle)

    /// The "btn-close" asset catalog image resource.
    static let btnClose = ImageResource(name: "btn-close", bundle: resourceBundle)

    /// The "btn-next" asset catalog image resource.
    static let btnNext = ImageResource(name: "btn-next", bundle: resourceBundle)

    /// The "btn-nowPlaying" asset catalog image resource.
    static let btnNowPlaying = ImageResource(name: "btn-nowPlaying", bundle: resourceBundle)

    /// The "btn-pause" asset catalog image resource.
    static let btnPause = ImageResource(name: "btn-pause", bundle: resourceBundle)

    /// The "btn-play" asset catalog image resource.
    static let btnPlay = ImageResource(name: "btn-play", bundle: resourceBundle)

    /// The "btn-previous" asset catalog image resource.
    static let btnPrevious = ImageResource(name: "btn-previous", bundle: resourceBundle)

    /// The "btn-stop" asset catalog image resource.
    static let btnStop = ImageResource(name: "btn-stop", bundle: resourceBundle)

    /// The "carPlayTab" asset catalog image resource.
    static let carPlayTab = ImageResource(name: "carPlayTab", bundle: resourceBundle)

    /// The "icon-hamburger" asset catalog image resource.
    static let iconHamburger = ImageResource(name: "icon-hamburger", bundle: resourceBundle)

    /// The "icon-info" asset catalog image resource.
    static let iconInfo = ImageResource(name: "icon-info", bundle: resourceBundle)

    /// The "logo" asset catalog image resource.
    static let logo = ImageResource(name: "logo", bundle: resourceBundle)

    /// The "radiospiral" asset catalog image resource.
    static let radiospiral = ImageResource(name: "radiospiral", bundle: resourceBundle)

    /// The "share" asset catalog image resource.
    static let share = ImageResource(name: "share", bundle: resourceBundle)

    /// The "slider-ball" asset catalog image resource.
    static let sliderBall = ImageResource(name: "slider-ball", bundle: resourceBundle)

    /// The "station-80s" asset catalog image resource.
    static let station80S = ImageResource(name: "station-80s", bundle: resourceBundle)

    /// The "station-absolutecountry" asset catalog image resource.
    static let stationAbsolutecountry = ImageResource(name: "station-absolutecountry", bundle: resourceBundle)

    /// The "station-altvault" asset catalog image resource.
    static let stationAltvault = ImageResource(name: "station-altvault", bundle: resourceBundle)

    /// The "station-classicrock" asset catalog image resource.
    static let stationClassicrock = ImageResource(name: "station-classicrock", bundle: resourceBundle)

    /// The "station-killrockstars" asset catalog image resource.
    static let stationKillrockstars = ImageResource(name: "station-killrockstars", bundle: resourceBundle)

    /// The "station-newportfolk" asset catalog image resource.
    static let stationNewportfolk = ImageResource(name: "station-newportfolk", bundle: resourceBundle)

    /// The "station-spaceland" asset catalog image resource.
    static let stationSpaceland = ImageResource(name: "station-spaceland", bundle: resourceBundle)

    /// The "station-sub" asset catalog image resource.
    static let stationSub = ImageResource(name: "station-sub", bundle: resourceBundle)

    /// The "station-therockfm" asset catalog image resource.
    static let stationTherockfm = ImageResource(name: "station-therockfm", bundle: resourceBundle)

    /// The "stationImage" asset catalog image resource.
    static let station = ImageResource(name: "stationImage", bundle: resourceBundle)

    /// The "swift-radio-black" asset catalog image resource.
    static let swiftRadioBlack = ImageResource(name: "swift-radio-black", bundle: resourceBundle)

    /// The "vol-max" asset catalog image resource.
    static let volMax = ImageResource(name: "vol-max", bundle: resourceBundle)

    /// The "vol-min" asset catalog image resource.
    static let volMin = ImageResource(name: "vol-min", bundle: resourceBundle)

}

// MARK: - Color Symbol Extensions -

#if canImport(AppKit)
@available(macOS 10.13, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

}
#endif

#if canImport(UIKit)
@available(iOS 11.0, tvOS 11.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

}
#endif

#if canImport(SwiftUI)
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SwiftUI.Color {

}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

}
#endif

// MARK: - Image Symbol Extensions -

#if canImport(AppKit)
@available(macOS 10.7, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    /// The "NowPlayingBars" asset catalog image.
    static var nowPlayingBars: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .nowPlayingBars)
#else
        .init()
#endif
    }

    /// The "NowPlayingBars-0" asset catalog image.
    static var nowPlayingBars0: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .nowPlayingBars0)
#else
        .init()
#endif
    }

    /// The "NowPlayingBars-1" asset catalog image.
    static var nowPlayingBars1: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .nowPlayingBars1)
#else
        .init()
#endif
    }

    /// The "NowPlayingBars-2" asset catalog image.
    static var nowPlayingBars2: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .nowPlayingBars2)
#else
        .init()
#endif
    }

    /// The "NowPlayingBars-3" asset catalog image.
    static var nowPlayingBars3: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .nowPlayingBars3)
#else
        .init()
#endif
    }

    /// The "albumArt" asset catalog image.
    static var albumArt: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .albumArt)
#else
        .init()
#endif
    }

    /// The "az-rock-radio" asset catalog image.
    static var azRockRadio: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .azRockRadio)
#else
        .init()
#endif
    }

    /// The "background" asset catalog image.
    static var background: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .background)
#else
        .init()
#endif
    }

    /// The "btn-close" asset catalog image.
    static var btnClose: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .btnClose)
#else
        .init()
#endif
    }

    /// The "btn-next" asset catalog image.
    static var btnNext: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .btnNext)
#else
        .init()
#endif
    }

    /// The "btn-nowPlaying" asset catalog image.
    static var btnNowPlaying: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .btnNowPlaying)
#else
        .init()
#endif
    }

    /// The "btn-pause" asset catalog image.
    static var btnPause: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .btnPause)
#else
        .init()
#endif
    }

    /// The "btn-play" asset catalog image.
    static var btnPlay: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .btnPlay)
#else
        .init()
#endif
    }

    /// The "btn-previous" asset catalog image.
    static var btnPrevious: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .btnPrevious)
#else
        .init()
#endif
    }

    /// The "btn-stop" asset catalog image.
    static var btnStop: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .btnStop)
#else
        .init()
#endif
    }

    /// The "carPlayTab" asset catalog image.
    static var carPlayTab: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .carPlayTab)
#else
        .init()
#endif
    }

    /// The "icon-hamburger" asset catalog image.
    static var iconHamburger: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .iconHamburger)
#else
        .init()
#endif
    }

    /// The "icon-info" asset catalog image.
    static var iconInfo: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .iconInfo)
#else
        .init()
#endif
    }

    /// The "logo" asset catalog image.
    static var logo: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .logo)
#else
        .init()
#endif
    }

    /// The "radiospiral" asset catalog image.
    static var radiospiral: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .radiospiral)
#else
        .init()
#endif
    }

    /// The "share" asset catalog image.
    static var share: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .share)
#else
        .init()
#endif
    }

    /// The "slider-ball" asset catalog image.
    static var sliderBall: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .sliderBall)
#else
        .init()
#endif
    }

    /// The "station-80s" asset catalog image.
    static var station80S: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .station80S)
#else
        .init()
#endif
    }

    /// The "station-absolutecountry" asset catalog image.
    static var stationAbsolutecountry: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .stationAbsolutecountry)
#else
        .init()
#endif
    }

    /// The "station-altvault" asset catalog image.
    static var stationAltvault: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .stationAltvault)
#else
        .init()
#endif
    }

    /// The "station-classicrock" asset catalog image.
    static var stationClassicrock: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .stationClassicrock)
#else
        .init()
#endif
    }

    /// The "station-killrockstars" asset catalog image.
    static var stationKillrockstars: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .stationKillrockstars)
#else
        .init()
#endif
    }

    /// The "station-newportfolk" asset catalog image.
    static var stationNewportfolk: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .stationNewportfolk)
#else
        .init()
#endif
    }

    /// The "station-spaceland" asset catalog image.
    static var stationSpaceland: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .stationSpaceland)
#else
        .init()
#endif
    }

    /// The "station-sub" asset catalog image.
    static var stationSub: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .stationSub)
#else
        .init()
#endif
    }

    /// The "station-therockfm" asset catalog image.
    static var stationTherockfm: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .stationTherockfm)
#else
        .init()
#endif
    }

    /// The "stationImage" asset catalog image.
    static var station: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .station)
#else
        .init()
#endif
    }

    /// The "swift-radio-black" asset catalog image.
    static var swiftRadioBlack: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .swiftRadioBlack)
#else
        .init()
#endif
    }

    /// The "vol-max" asset catalog image.
    static var volMax: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .volMax)
#else
        .init()
#endif
    }

    /// The "vol-min" asset catalog image.
    static var volMin: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .volMin)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 11.0, tvOS 11.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    /// The "NowPlayingBars" asset catalog image.
    static var nowPlayingBars: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .nowPlayingBars)
#else
        .init()
#endif
    }

    /// The "NowPlayingBars-0" asset catalog image.
    static var nowPlayingBars0: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .nowPlayingBars0)
#else
        .init()
#endif
    }

    /// The "NowPlayingBars-1" asset catalog image.
    static var nowPlayingBars1: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .nowPlayingBars1)
#else
        .init()
#endif
    }

    /// The "NowPlayingBars-2" asset catalog image.
    static var nowPlayingBars2: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .nowPlayingBars2)
#else
        .init()
#endif
    }

    /// The "NowPlayingBars-3" asset catalog image.
    static var nowPlayingBars3: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .nowPlayingBars3)
#else
        .init()
#endif
    }

    /// The "albumArt" asset catalog image.
    static var albumArt: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .albumArt)
#else
        .init()
#endif
    }

    /// The "az-rock-radio" asset catalog image.
    static var azRockRadio: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .azRockRadio)
#else
        .init()
#endif
    }

    /// The "background" asset catalog image.
    static var background: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .background)
#else
        .init()
#endif
    }

    /// The "btn-close" asset catalog image.
    static var btnClose: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .btnClose)
#else
        .init()
#endif
    }

    /// The "btn-next" asset catalog image.
    static var btnNext: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .btnNext)
#else
        .init()
#endif
    }

    /// The "btn-nowPlaying" asset catalog image.
    static var btnNowPlaying: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .btnNowPlaying)
#else
        .init()
#endif
    }

    /// The "btn-pause" asset catalog image.
    static var btnPause: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .btnPause)
#else
        .init()
#endif
    }

    /// The "btn-play" asset catalog image.
    static var btnPlay: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .btnPlay)
#else
        .init()
#endif
    }

    /// The "btn-previous" asset catalog image.
    static var btnPrevious: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .btnPrevious)
#else
        .init()
#endif
    }

    /// The "btn-stop" asset catalog image.
    static var btnStop: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .btnStop)
#else
        .init()
#endif
    }

    /// The "carPlayTab" asset catalog image.
    static var carPlayTab: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .carPlayTab)
#else
        .init()
#endif
    }

    /// The "icon-hamburger" asset catalog image.
    static var iconHamburger: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .iconHamburger)
#else
        .init()
#endif
    }

    /// The "icon-info" asset catalog image.
    static var iconInfo: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .iconInfo)
#else
        .init()
#endif
    }

    /// The "logo" asset catalog image.
    static var logo: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .logo)
#else
        .init()
#endif
    }

    /// The "radiospiral" asset catalog image.
    static var radiospiral: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .radiospiral)
#else
        .init()
#endif
    }

    /// The "share" asset catalog image.
    static var share: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .share)
#else
        .init()
#endif
    }

    /// The "slider-ball" asset catalog image.
    static var sliderBall: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .sliderBall)
#else
        .init()
#endif
    }

    /// The "station-80s" asset catalog image.
    static var station80S: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .station80S)
#else
        .init()
#endif
    }

    /// The "station-absolutecountry" asset catalog image.
    static var stationAbsolutecountry: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .stationAbsolutecountry)
#else
        .init()
#endif
    }

    /// The "station-altvault" asset catalog image.
    static var stationAltvault: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .stationAltvault)
#else
        .init()
#endif
    }

    /// The "station-classicrock" asset catalog image.
    static var stationClassicrock: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .stationClassicrock)
#else
        .init()
#endif
    }

    /// The "station-killrockstars" asset catalog image.
    static var stationKillrockstars: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .stationKillrockstars)
#else
        .init()
#endif
    }

    /// The "station-newportfolk" asset catalog image.
    static var stationNewportfolk: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .stationNewportfolk)
#else
        .init()
#endif
    }

    /// The "station-spaceland" asset catalog image.
    static var stationSpaceland: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .stationSpaceland)
#else
        .init()
#endif
    }

    /// The "station-sub" asset catalog image.
    static var stationSub: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .stationSub)
#else
        .init()
#endif
    }

    /// The "station-therockfm" asset catalog image.
    static var stationTherockfm: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .stationTherockfm)
#else
        .init()
#endif
    }

    /// The "stationImage" asset catalog image.
    static var station: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .station)
#else
        .init()
#endif
    }

    /// The "swift-radio-black" asset catalog image.
    static var swiftRadioBlack: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .swiftRadioBlack)
#else
        .init()
#endif
    }

    /// The "vol-max" asset catalog image.
    static var volMax: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .volMax)
#else
        .init()
#endif
    }

    /// The "vol-min" asset catalog image.
    static var volMin: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .volMin)
#else
        .init()
#endif
    }

}
#endif

// MARK: - Thinnable Asset Support -

@available(iOS 11.0, macOS 10.13, tvOS 11.0, *)
@available(watchOS, unavailable)
extension ColorResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if AppKit.NSColor(named: NSColor.Name(thinnableName), bundle: bundle) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIColor(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(UIKit)
@available(iOS 11.0, tvOS 11.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    private convenience init?(thinnableResource: ColorResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SwiftUI.Color {

    private init?(thinnableResource: ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    private init?(thinnableResource: ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}
#endif

@available(iOS 11.0, macOS 10.7, tvOS 11.0, *)
@available(watchOS, unavailable)
extension ImageResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if bundle.image(forResource: NSImage.Name(thinnableName)) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIImage(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 10.7, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    private convenience init?(thinnableResource: ImageResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 11.0, tvOS 11.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    private convenience init?(thinnableResource: ImageResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

// MARK: - Backwards Deployment Support -

/// A color resource.
struct ColorResource: Swift.Hashable, Swift.Sendable {

    /// An asset catalog color resource name.
    fileprivate let name: Swift.String

    /// An asset catalog color resource bundle.
    fileprivate let bundle: Foundation.Bundle

    /// Initialize a `ColorResource` with `name` and `bundle`.
    init(name: Swift.String, bundle: Foundation.Bundle) {
        self.name = name
        self.bundle = bundle
    }

}

/// An image resource.
struct ImageResource: Swift.Hashable, Swift.Sendable {

    /// An asset catalog image resource name.
    fileprivate let name: Swift.String

    /// An asset catalog image resource bundle.
    fileprivate let bundle: Foundation.Bundle

    /// Initialize an `ImageResource` with `name` and `bundle`.
    init(name: Swift.String, bundle: Foundation.Bundle) {
        self.name = name
        self.bundle = bundle
    }

}

#if canImport(AppKit)
@available(macOS 10.13, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    /// Initialize a `NSColor` with a color resource.
    convenience init(resource: ColorResource) {
        self.init(named: NSColor.Name(resource.name), bundle: resource.bundle)!
    }

}

protocol _ACResourceInitProtocol {}
extension AppKit.NSImage: _ACResourceInitProtocol {}

@available(macOS 10.7, *)
@available(macCatalyst, unavailable)
extension _ACResourceInitProtocol {

    /// Initialize a `NSImage` with an image resource.
    init(resource: ImageResource) {
        self = resource.bundle.image(forResource: NSImage.Name(resource.name))! as! Self
    }

}
#endif

#if canImport(UIKit)
@available(iOS 11.0, tvOS 11.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    /// Initialize a `UIColor` with a color resource.
    convenience init(resource: ColorResource) {
#if !os(watchOS)
        self.init(named: resource.name, in: resource.bundle, compatibleWith: nil)!
#else
        self.init()
#endif
    }

}

@available(iOS 11.0, tvOS 11.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    /// Initialize a `UIImage` with an image resource.
    convenience init(resource: ImageResource) {
#if !os(watchOS)
        self.init(named: resource.name, in: resource.bundle, compatibleWith: nil)!
#else
        self.init()
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SwiftUI.Color {

    /// Initialize a `Color` with a color resource.
    init(_ resource: ColorResource) {
        self.init(resource.name, bundle: resource.bundle)
    }

}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SwiftUI.Image {

    /// Initialize an `Image` with an image resource.
    init(_ resource: ImageResource) {
        self.init(resource.name, bundle: resource.bundle)
    }

}
#endif