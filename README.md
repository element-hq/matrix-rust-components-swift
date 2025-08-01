# Element's build of the Matrix Rust SDK for Swift

This repository provides a cutdown Swift Package for distributing releases of the [Matrix Rust SDK](https://github.com/matrix-org/matrix-rust-sdk) for use by Element. It only supports iOS and the iOS simulator. The official components provide documentation and support more Apple platforms. These can be found here: https://github.com/matrix-org/matrix-rust-components-swift/

Note: The versioning used for this package does not correspond in any way with the official package.

## Releasing

Whenever a new release of the underlying components is available, we need to tag a new release in this repo to make them available to Swift components. This is done with the [release script](Tools/Release/README.md) found in the Tools directory.
