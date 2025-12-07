// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription
let checksum = "97c960bb01bd17301fc3ecb6fc5c14b96971ea86fc35e811b138fcf462ca1b87"
let version = "25.12.07"
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
