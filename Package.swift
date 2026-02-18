// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ClassicLaunch",
    products: [
        .executable(
            name: "ClassicLaunch",
            targets: ["ClassicLaunchApp"]
        )
    ],
    targets: [
        .target(
            name: "ClassicLaunchCore",
            path: "Sources/ClassicLaunchCore"
        ),
        .executableTarget(
            name: "ClassicLaunchApp",
            dependencies: ["ClassicLaunchCore"],
            path: "Sources/ClassicLaunchApp"
        ),
        .testTarget(
            name: "ClassicLaunchCoreTests",
            dependencies: ["ClassicLaunchCore"],
            path: "Tests/ClassicLaunchCoreTests"
        )
    ]
)
