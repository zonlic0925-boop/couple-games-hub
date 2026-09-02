// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CoupleGames",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "CoupleGamesCore",
            targets: ["CoupleGamesCore"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "CoupleGamesCore",
            dependencies: [],
            path: "Sources/CoupleGamesCore"
        ),
        .testTarget(
            name: "CoupleGamesCoreTests",
            dependencies: ["CoupleGamesCore"],
            path: "Tests/CoupleGamesCoreTests"
        ),
    ]
)
