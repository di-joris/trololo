// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "trello-tool",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(name: "trello", targets: ["trello"]),
        .library(name: "TrelloAPI", targets: ["TrelloAPI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
    ],
    targets: [
        .executableTarget(
            name: "trello",
            dependencies: [
                "TrelloAPI",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .target(
            name: "TrelloAPI"
        ),
        .testTarget(
            name: "TrelloAPITests",
            dependencies: ["TrelloAPI"]
        ),
        .testTarget(
            name: "TrelloCLITests",
            dependencies: ["trello"]
        ),
    ]
)
