// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "QueryStringCoder",
    products: [
        .library(
            name: "QueryStringCoder",
            targets: ["QueryStringCoder"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "QueryStringCoder",
            dependencies: []
        ),
        .testTarget(
            name: "QueryStringCoderTests",
            dependencies: ["QueryStringCoder"]
        ),
    ]
)
