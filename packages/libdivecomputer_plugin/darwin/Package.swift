// swift-tools-version: 5.9
// Derived from Submersion (https://github.com/submersion-app/submersion), commit e78a87cb, GPL-3.0. Modified for DiveDown.
import PackageDescription

let package = Package(
    name: "LibDCDarwin",
    platforms: [.iOS(.v14), .macOS(.v11)],
    products: [
        .library(name: "LibDCDarwin", targets: ["LibDCDarwin"]),
    ],
    targets: [
        .target(
            name: "LibDCDarwin",
            path: "Sources/LibDCDarwin"
        ),
    ]
)
