// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "PasteVox",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "PasteVox", targets: ["PasteVox"])
    ],
    targets: [
        .executableTarget(
            name: "PasteVox",
            path: "Sources/PasteVox",
            exclude: ["Info.plist", "Resources/MenuBarIcon.backup.png"],
            resources: [
                .copy("Resources/AppIcon.png"),
                .copy("Resources/MenuBarIcon.png"),
                .process("Resources/en.lproj/Localizable.strings"),
                .process("Resources/ru.lproj/Localizable.strings")
            ],
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "Sources/PasteVox/Info.plist"
                ])
            ]
        ),
        .testTarget(
            name: "PasteVoxTests",
            dependencies: ["PasteVox"],
            path: "Tests/PasteVoxTests"
        )
    ]
)
