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
    dependencies: [
        .package(url: "https://github.com/William-Weng/WWByteReader", .upToNextMinor(from: "1.0.2")),
    ],
    targets: [
        .target(name: "WWQOI", dependencies: [
            .product(name: "WWByteReader", package: "WWByteReader"),
        ]),
    ],
    swiftLanguageVersions: [
        .v5
    ]
)
