// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "KaitenSDK",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "KaitenSDK",
            targets: ["KaitenSDK"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-argument-parser",
            from: "1.5.0"
        ),
        .package(
            url: "https://github.com/apple/swift-openapi-generator",
            from: "1.7.0"
        ),
        .package(
            url: "https://github.com/apple/swift-openapi-runtime",
            from: "1.7.0"
        ),
        .package(
            url: "https://github.com/apple/swift-openapi-urlsession",
            from: "1.0.0"
        ),
        .package(
            url: "https://github.com/apple/swift-http-types",
            from: "1.3.0"
        ),
        .package(
            url: "https://github.com/apple/swift-configuration",
            from: "1.0.2",
            traits: ["JSON"]
        ),
        .package(
            url: "https://github.com/apple/swift-system",
            from: "1.4.0"
        ),
    ],
    targets: [
        .target(
            name: "KaitenSDK",
            dependencies: [
                .product(
                    name: "OpenAPIRuntime",
                    package: "swift-openapi-runtime"
                ),
                .product(
                    name: "OpenAPIURLSession",
                    package: "swift-openapi-urlsession"
                ),
                .product(
                    name: "HTTPTypes",
                    package: "swift-http-types"
                ),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ],
            plugins: [
                .plugin(
                    name: "OpenAPIGenerator",
                    package: "swift-openapi-generator"
                ),
            ]
        ),
        .executableTarget(
            name: "kaiten",
            dependencies: [
                "KaitenSDK",
                .product(
                    name: "OpenAPIRuntime",
                    package: "swift-openapi-runtime"
                ),
                .product(
                    name: "ArgumentParser",
                    package: "swift-argument-parser"
                ),
                .product(
                    name: "Configuration",
                    package: "swift-configuration"
                ),
                .product(
                    name: "SystemPackage",
                    package: "swift-system"
                ),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .testTarget(
            name: "KaitenSDKTests",
            dependencies: [
                "KaitenSDK",
                "kaiten",
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
    ]
)
