// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "Boya",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Boya",
            path: "Sources/Boya"
        )
    ]
)
