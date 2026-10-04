// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "OpenCFMotoCore",
    platforms: [.macOS(.v13), .iOS("27.0")],
    products: [
        .library(name: "OpenCFMotoCore", targets: ["OpenCFMotoCore"]),
        .executable(name: "ProtocolProbe", targets: ["ProtocolProbe"])
    ],
    targets: [
        .target(
            name: "OpenCFMotoCore",
            path: "OpenCFMoto",
            exclude: ["App", "Network", "Capture", "Video", "Diagnostics", "Pairing/README.md", "EasyConnect/README.md"],
            sources: ["Pairing", "EasyConnect"]
        ),
        .executableTarget(name: "ProtocolProbe", dependencies: ["OpenCFMotoCore"], path: "Tools/ProtocolProbe"),
        .testTarget(name: "OpenCFMotoCoreTests", dependencies: ["OpenCFMotoCore"], path: "OpenCFMotoTests", exclude: ["README.md"])
    ]
)
