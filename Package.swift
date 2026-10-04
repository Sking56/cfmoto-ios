// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "OpenCFMotoCore",
    platforms: [.macOS(.v13), .iOS("27.0")],
    products: [
        .library(name: "OpenCFMotoCore", targets: ["OpenCFMotoCore"]),
        .library(name: "OpenCFMotoVideo", targets: ["OpenCFMotoVideo"]),
        .executable(name: "ProtocolProbe", targets: ["ProtocolProbe"])
    ],
    targets: [
        .target(
            name: "OpenCFMotoCore",
            path: "OpenCFMoto",
            exclude: ["App", "Network", "Capture", "Video", "Diagnostics", "Pairing/README.md", "EasyConnect/README.md"],
            sources: ["Pairing", "EasyConnect"]
        ),
        .target(name: "OpenCFMotoVideo", path: "OpenCFMoto/Video", exclude: ["README.md"]),
        .target(name: "ProtocolHarness", dependencies: ["OpenCFMotoCore", "OpenCFMotoVideo"], path: "Tools/ProtocolHarness"),
        .executableTarget(name: "ProtocolProbe", dependencies: ["ProtocolHarness"], path: "Tools/ProtocolProbe"),
        .executableTarget(name: "VideoInspector", path: "Tools/VideoInspector"),
        .testTarget(name: "OpenCFMotoCoreTests", dependencies: ["OpenCFMotoCore"], path: "OpenCFMotoTests", exclude: ["README.md"]),
        .testTarget(name: "ProtocolHarnessTests", dependencies: ["ProtocolHarness", "OpenCFMotoCore"], path: "Tests/ProtocolHarnessTests"),
        .testTarget(name: "OpenCFMotoVideoTests", dependencies: ["OpenCFMotoVideo"], path: "Tests/VideoTests")
    ]
)
