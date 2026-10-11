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
        // Запуск: scripts/test.sh (без Xcode нужны флаги для Testing.framework из Command Line Tools).
        .testTarget(
            name: "RenameConvertTests",
            dependencies: ["RenameConvert"],
            path: "Tests/RenameConvertTests",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
