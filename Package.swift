// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription
let checksum = "06f633f104067edf0d458e09101630ec9652a4242129ef57ebea7425e1362e5f"
let version = "25.03.11"
let url = "https://github.com/element-hq/matrix-rust-components-swift/releases/download/\(version)/MatrixSDKFFI.xcframework.zip"
let package = Package(
    name: "MatrixRustSDK",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(name: "MatrixRustSDK", type: .dynamic, targets: ["MatrixRustSDK"]),
    ],
    targets: [
        .binaryTarget(name: "MatrixSDKFFI", url: url, checksum: checksum),
        .target(name: "MatrixRustSDK", dependencies: [.target(name: "MatrixSDKFFI")])
    ]
)
