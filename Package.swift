// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Cafezinho",
    platforms: [.macOS(.v13)],
    targets: [
        .target(name: "CafezinhoCore"),
        .executableTarget(name: "Cafezinho", dependencies: ["CafezinhoCore"]),
        .testTarget(name: "CafezinhoCoreTests", dependencies: ["CafezinhoCore"]),
    ]
)
