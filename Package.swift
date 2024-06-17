// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription
let checksum = "f4081f37f28dacd5644367919a17d115b39b597f2fad47cfaa5aa3cc2968f234"
let version = "v1.0.14"
let url = "https://github.com/element-hq/matrix-rust-components-swift/releases/download/\(version)/MatrixSDKFFI.xcframework.zip"
let package = Package(
    name: "MatrixRustSDK",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(name: "MatrixRustSDK", targets: ["MatrixRustSDK"]),
    ],
    targets: [
        .binaryTarget(name: "MatrixSDKFFI", url: url, checksum: checksum),
        .target(name: "MatrixRustSDK", dependencies: [.target(name: "MatrixSDKFFI")])
    ]
)
