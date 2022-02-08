// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "xcbump",
    platforms: [.macOS(.v10_15)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .executable(
            name: "xcbump",
            targets: ["xcbump"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.0.0"),
        .package(url: "https://github.com/jagreenwood/git-macOS.git", revision: "5418a00"),
        .package(url: "https://github.com/tuist/XcodeProj.git", from: "8.7.0")
         
    ],
    targets: [
        .executableTarget(
            name: "xcbump",
            dependencies: [
                "XcodeProj",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Git", package: "git-macos")
            ])
    ]
)
