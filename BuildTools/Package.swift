// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "BuildTools",
    platforms: [
        .macOS(.v11),
        .iOS(.v16),
    ],
    dependencies: [
        .package(url: "https://github.com/nicklockwood/SwiftFormat", from: "0.50.7"),
    ],
    targets: [
        .target(
            name: "BuildTools",
            dependencies: []
        ),
        .testTarget(
            name: "BuildToolsTests",
            dependencies: ["BuildTools"]
        ),
    ]
)
