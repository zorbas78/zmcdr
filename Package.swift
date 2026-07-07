// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "zcmdr",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "zcmdr",
            path: "Sources"
        )
    ]
)
