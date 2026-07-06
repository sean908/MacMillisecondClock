// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MacMillisecondClock",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "ClockWidgetCore",
            targets: ["ClockWidgetCore"]
        ),
        .executable(
            name: "MacMillisecondClock",
            targets: ["MacMillisecondClock"]
        )
    ],
    targets: [
        .target(
            name: "ClockWidgetCore"
        ),
        .executableTarget(
            name: "MacMillisecondClock",
            dependencies: ["ClockWidgetCore"]
        ),
        .executableTarget(
            name: "ClockWidgetCoreBehaviorTests",
            dependencies: ["ClockWidgetCore"],
            path: "Tests/ClockWidgetCoreBehaviorTests"
        )
    ]
)
