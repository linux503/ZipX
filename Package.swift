// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ZipX",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "ZipX", targets: ["ZipX"])
    ],
    targets: [
        .executableTarget(
            name: "ZipX",
            path: "Sources/ZipX",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI"),
                .linkedFramework("UniformTypeIdentifiers")
            ]
        )
    ]
)
