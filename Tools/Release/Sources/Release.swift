import ArgumentParser
import CommandLineTools
import Foundation

@main
struct Release: AsyncParsableCommand {
    @Option(help: "An optional build number that will be appended to the generated version (e.g. 25.12.31-123). This option is ignored when a custom version is specified.")
    var buildNumber: Int? = nil
    
    @Option(help: "A custom version to use instead of generating a calendar version. This option takes precedence over --build-number.")
    var customVersion: String? = nil
    
    var version: String {
        customVersion ?? Date.now.calendarVersion(buildNumber: buildNumber)
    }
    
    @Flag(help: "Prevents the run from pushing anything to GitHub.")
    var localOnly = false
    
    var apiToken = (try? NetrcParser.parse(file: FileManager.default.homeDirectoryForCurrentUser.appending(component: ".netrc")))!
        .authorization(for: URL(string: "https://api.github.com")!)!
        .password
    
    var sourceRepo = Repository(owner: "matrix-org", name: "matrix-rust-sdk")
    var packageRepo = Repository(owner: "element-hq", name: "matrix-rust-components-swift")
    
    var packageDirectory = URL(fileURLWithPath: #file)
        .deletingLastPathComponent() // Release.swift
        .deletingLastPathComponent() // Sources
        .deletingLastPathComponent() // Release
        .deletingLastPathComponent() // Tools
    lazy var buildDirectory = packageDirectory
        .deletingLastPathComponent() // matrix-rust-components-swift
        .appending(component: "matrix-rust-sdk")
    
    mutating func run() async throws {
        let package = Package(repository: packageRepo, directory: packageDirectory, apiToken: apiToken, urlSession: localOnly ? .releaseMock : .shared)
        Zsh.defaultDirectory = package.directory
        
        Log.info("Build directory: \(buildDirectory.path())")
        
        let product = try build()
        let (zipFileURL, checksum) = try package.zipBinary(with: product)
        
        try await updatePackage(package, with: product, checksum: checksum)
        try commitAndPush(package, with: product)
        try await package.makeRelease(with: product, uploading: zipFileURL)
    }
    
    mutating func build() throws -> BuildProduct {
        let git = Git(directory: buildDirectory)
        let commitHash = try git.commitHash
        let branch = try git.branchName
        
        Log.info("Building \(branch) at \(commitHash)")
        
        // unset fixes an issue where swift compilation prevents building for targets other than macOS
        let cargoCommand = "cargo xtask swift build-framework --release --target aarch64-apple-ios --target aarch64-apple-ios-sim --target x86_64-apple-ios"
        try Zsh.run(command: "unset SDKROOT && \(cargoCommand)", directory: buildDirectory)
        
        return BuildProduct(sourceRepo: sourceRepo,
                            version: version,
                            commitHash: commitHash,
                            branch: branch,
                            directory: buildDirectory.appending(component: "bindings/apple/generated/"),
                            frameworkName: "MatrixSDKFFI.xcframework")
    }
    
    func updatePackage(_ package: Package, with product: BuildProduct, checksum: String) async throws {
        Log.info("Copying sources")
        let source = product.directory.appending(component: "swift", directoryHint: .isDirectory)
        let destination = package.directory.appending(component: "Sources/MatrixRustSDK", directoryHint: .isDirectory)
        try Zsh.run(command: "rsync -a --delete '\(source.path())' '\(destination.path())'")
        
        // Temporary workaround for https://github.com/mozilla/uniffi-rs/issues/2717
        let enumerator = FileManager.default.enumerator(at: destination, includingPropertiesForKeys: nil, options: .skipsSubdirectoryDescendants)
        while let fileURL = enumerator?.nextObject() as? URL {
            guard fileURL.pathExtension == "swift" else { continue }
            let fileName = fileURL.lastPathComponent
            let command = """
            gsed -i -E -z "s/(deinit[^{]*\\{[^\\n]*\\n)([[:space:]]*)(try! rustCall)/\\1\\2guard handle != 0 else { return }\\n\\2\\3/g" \(fileName)
            """
            try Zsh.run(command: command, directory: destination)
        }
        
        try await package.updateManifest(with: product, checksum: checksum)
    }
    
    func commitAndPush(_ package: Package, with product: BuildProduct) throws {
        Log.info("Pushing changes")
        
        let git = Git(directory: package.directory)
        try git.add(files: "Package.swift", "Sources")
        try git.commit(message: "Bump to version \(version) (\(product.sourceRepo.name)/\(product.branch) \(product.commitHash))")
        
        guard !localOnly else {
            Log.info("Skipping push for --local-only")
            return
        }
        
        try git.push()
    }
}
