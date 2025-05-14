import ProjectDescription

let project = Project(
    name: "AsyncDownloader",
    packages: [
        .remote(
            url: "https://github.com/ml-explore/mlx-swift-examples/",
            //requirement: .upToNextMajor(from: "2.21.2")
            requirement: .branch("main")
        )
    ],
    settings: .settings(
        base: [
            "SWIFT_VERSION": "6.0",
            "CURRENT_PROJECT_VERSION": "1",
            "MARKETING_VERSION": "1.0",
            "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
            "CODE_SIGN_STYLE": "Automatic",
            "DEVELOPMENT_TEAM": "P5WD874MH2",
            //"LIBRARY_SEARCH_PATHS": ["$(inherited)", "$(PROJECT_DIR)/3rdparty/mlc_llm/ios/MLCChat/dist/lib"],
            //"OTHER_LDFLAGS": [
            //    "-ObjC",
            //    "-Wl,-all_load",
            //    "-lmodel_iphone", "-lmlc_llm", "-ltvm_runtime", "-ltokenizers_cpp",
            //    "-lsentencepiece", "-ltokenizers_c",
            //],
        ]
    ),
    targets: [
        .target(
            name: "AsyncDownloader",
            destinations: .macOS,
            //destinations: .iOS
            product: .app,
            bundleId: "com.skt.AsyncDownloader",
            deploymentTargets: .macOS("15.0"),
            //deploymentTargets: .iOS("18.0"),
            infoPlist: .extendingDefault(
                with: [
                    "CFBundleVersion": "$(MARKETING_VERSION)",
                    "CFBundleShortVersionString": "$(CURRENT_PROJECT_VERSION)",
                    "LSApplicationCategoryType": "public.app-category.developer-tools",
                ]
            ),
            sources: ["AsyncDownloader/Sources/**"],
            resources: ["AsyncDownloader/Resources/**"],
            dependencies: [
                .external(name: "AsyncAlgorithms"),
                //.external(name: "MLX"),
                //.external(name: "MLXRandom"),
                //.external(name: "MLXNN"),
                //.external(name: "MLXOptimizers"),
                //.external(name: "MLXFFT"),
                //.external(name: "Transformers"),
                .package(product: "MLX"),
                .package(product: "MLXRandom"),
                .package(product: "MLXNN"),
                .package(product: "MLXOptimizers"),
                .package(product: "MLXFFT"),
                .package(product: "Transformers"),
                .package(product: "MLXLLM"),
                .external(name: "MarkdownUI"),
            ]
        ),
        .target(
            name: "AsyncDownloaderTests",
            destinations: .macOS,
            product: .unitTests,
            bundleId: "io.tuist.AsyncDownloaderTests",
            infoPlist: .default,
            sources: ["AsyncDownloader/Tests/**"],
            resources: [],
            dependencies: [.target(name: "AsyncDownloader")]
        ),
    ]
)
