// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "ImportSpike",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "ImportSpike",
            swiftSettings: [.unsafeFlags(["-strict-concurrency=minimal"])]
        ),
    ]
)
