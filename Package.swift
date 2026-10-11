// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "RenameConvert",
    platforms: [.macOS(.v15)],
    targets: [
        .executableTarget(
            name: "RenameConvert",
            path: "Sources/RenameConvert",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
