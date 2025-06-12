// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "VisionOCRDemo",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "VisionOCRDemo",
            dependencies: []
        )
    ]
)
