// swift-tools-version: 6.0
import PackageDescription

#if TUIST
    import struct ProjectDescription.PackageSettings

    let packageSettings = PackageSettings(
        // Customize the product types for specific package product
        // Default is .staticFramework
        // productTypes: ["Alamofire": .framework,]
        productTypes: [:]
    )
#endif

let package = Package(
    name: "AsyncDownloader",
    dependencies: [
        // Add your own dependencies here:
        // .package(url: "https://github.com/Alamofire/Alamofire", from: "5.0.0"),
        // You can read more about dependencies here: https://docs.tuist.io/documentation/tuist/dependencies
        .package(url: "https://github.com/apple/swift-async-algorithms", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/ml-explore/mlx-swift", .upToNextMajor(from: "0.10.0")),
        .package(url: "https://github.com/huggingface/swift-transformers", .upToNextMajor(from: "0.1.17")),
        .package(url: "https://github.com/gonzalezreal/swift-markdown-ui", .upToNextMajor(from: "2.0.2")),
    ]
)
