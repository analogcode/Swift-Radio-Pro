// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SwiftRadioCore",
    platforms: [.iOS(.v17)],
    products: [.library(name: "SwiftRadioCore", targets: ["SwiftRadioCore"])],
    dependencies: [.package(url: "https://github.com/fethica/FRadioPlayer.git", .upToNextMinor(from: "0.4.0"))],
    targets: [
        .target(name: "SwiftRadioCore", dependencies: ["FRadioPlayer"],
                swiftSettings: [.swiftLanguageMode(.v6)]),
        .testTarget(name: "SwiftRadioCoreTests", dependencies: ["SwiftRadioCore"],
                    resources: [.copy("Fixtures")], swiftSettings: [.swiftLanguageMode(.v6)])
    ]
)
