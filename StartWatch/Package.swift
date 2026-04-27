// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "StartWatch",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "StartWatch",
            path: "Sources/StartWatch"
        ),
        .testTarget(
            name: "StartWatchTests",
            dependencies: ["StartWatch"],
            path: "Tests/StartWatchTests"
        )
    ]
)
