// swift-tools-version: 5.10
// CrowdPlaySDK — CrowdPlay's capture SDK for iOS.
//
// The engine ships as a compiled binary (CrowdPlaySDKCore.xcframework,
// attached to this repo's releases); this manifest wraps it so
// `import CrowdPlaySDK` is the entire integration. LiveKit and
// swift-atomics are open-source dependencies fetched from their own
// repositories — the pins are exact because the capture engine is verified
// against these versions. The `LivaKit` product is a legacy alias from the
// 0.1.x era; new integrations use CrowdPlaySDK.
import PackageDescription

let package = Package(
    name: "CrowdPlaySDK",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "CrowdPlaySDK", targets: ["CrowdPlaySDK"]),
        .library(name: "LivaKit", targets: ["LivaKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/livekit/client-sdk-swift", exact: "2.16.0"),
        .package(url: "https://github.com/apple/swift-atomics", from: "1.2.0"),
    ],
    targets: [
        .binaryTarget(
            name: "CrowdPlaySDKCore",
            url: "https://github.com/symbiateam/crowdplaysdk/releases/download/0.2.1/CrowdPlaySDKCore.xcframework.zip",
            checksum: "7558d03fa298857d76717cfbd2a6ce035b743ddcbbb5b599bc7e9c07fba418ec"
        ),
        .target(
            name: "CrowdPlaySDK",
            dependencies: [
                "CrowdPlaySDKCore",
                .product(name: "LiveKit", package: "client-sdk-swift"),
                .product(name: "Atomics", package: "swift-atomics"),
            ],
            path: "Sources/CrowdPlaySDK"
        ),
        .target(
            name: "LivaKit",
            dependencies: ["CrowdPlaySDK"],
            path: "Sources/LivaKit"
        ),
    ]
)
