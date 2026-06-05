// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "PasteVox",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "PasteVox", targets: ["VoiceDock"])
    ],
    targets: [
        .executableTarget(
            name: "VoiceDock",
            path: "Sources/VoiceDock",
            exclude: ["Info.plist", "Resources/MenuBarIcon.backup.png"],
            resources: [
                .copy("Resources/AppIcon.png"),
                .copy("Resources/MenuBarIcon.png")
            ],
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "Sources/VoiceDock/Info.plist"
                ])
            ]
        ),
        .testTarget(
            name: "VoiceDockTests",
            dependencies: ["VoiceDock"],
            path: "Tests/VoiceDockTests"
        )
    ]
)
