// swift-tools-version: 5.10
// LivaKit — Liva's capture SDK for iOS.
//
// The engine ships as a compiled binary (LivaKitCore.xcframework, attached
// to this repo's releases); this manifest wraps it so `import LivaKit` is
// the entire integration. LiveKit and swift-atomics are open-source
// dependencies fetched from their own repositories — the pins are exact
// because the capture engine is verified against these versions.
import PackageDescription

let package = Package(
    name: "LivaKit",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "LivaKit", targets: ["LivaKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/livekit/client-sdk-swift", exact: "2.16.0"),
        .package(url: "https://github.com/apple/swift-atomics", from: "1.2.0"),
    ],
    targets: [
        .binaryTarget(
            name: "LivaKitCore",
            url: "https://github.com/symbiateam/crowdplaysdk/releases/download/0.1.3/LivaKitCore.xcframework.zip",
            checksum: "257924d0850e52cf060d74849dc31438756e952d27bd1496e1c7e0e5f40fb16c"
        ),
        .target(
            name: "LivaKit",
            dependencies: [
                "LivaKitCore",
                .product(name: "LiveKit", package: "client-sdk-swift"),
                .product(name: "Atomics", package: "swift-atomics"),
            ],
            path: "Sources/LivaKit"
        ),
    ]
)
