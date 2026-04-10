// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "WWQOI",
    platforms: [
        .iOS(.v16),
    ],
    products: [
        .library(name: "WWQOI", targets: ["WWQOI"])
    ],
    targets: [
        .target(name: "WWQOI"),
    ],
    swiftLanguageVersions: [
        .v5
    ]
)
