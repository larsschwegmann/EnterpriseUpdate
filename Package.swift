// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "EnterpriseUpdate",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "EnterpriseUpdate",
            targets: ["EnterpriseUpdate"]),
    ],
    dependencies: [
        .package(url: "https://github.com/mxcl/Version.git", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "EnterpriseUpdate",
            dependencies: ["Version"]),
        .testTarget(
            name: "EnterpriseUpdateTests",
            dependencies: ["EnterpriseUpdate"]),
    ]
)
