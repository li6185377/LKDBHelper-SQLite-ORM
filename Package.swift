// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LKDBHelper",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(name: "LKDBHelper", targets: ["LKDBHelper"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/ccgus/fmdb.git", from: "2.7.8"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "LKDBHelper",
            dependencies: [.product(name: "FMDB", package: "fmdb")], path: "LKDBHelper/Helper",
            publicHeadersPath: "."
        ),
    ]
)
