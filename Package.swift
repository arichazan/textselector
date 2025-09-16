// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SnapText",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "SnapText", targets: ["SnapText"])
    ],
    targets: [
        .executableTarget(
            name: "SnapText",
            path: "Sources/SnapText"
        )
    ]
)
