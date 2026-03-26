// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "ParsingTestHarness",
    platforms: [.macOS(.v15)],
    targets: [
        .executableTarget(
            name: "ParsingHarness",
            path: "Sources",
            swiftSettings: [.unsafeFlags(["-strict-concurrency=minimal"])]
        ),
    ]
)
