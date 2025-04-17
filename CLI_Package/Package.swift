// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "LabelRenamer",
    platforms: [.macOS(.v12)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.1.0"),
    ],
    targets: [
        .executableTarget(
            name: "LabelRenamer",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        )
    ]
)
