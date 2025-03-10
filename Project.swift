import ProjectDescription

let project = Project(
    name: "AsyncDownloader",
    settings: .settings(
        base: [
            "SWIFT_VERSION": "6.0",
            "CURRENT_PROJECT_VERSION": "1",
            "MARKETING_VERSION": "1.0",
            "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
            "CODE_SIGN_STYLE": "Automatic",
            "DEVELOPMENT_TEAM": "P5WD874MH2",
        ]
    ),
    targets: [
        .target(
            name: "AsyncDownloader",
            destinations: .macOS,
            product: .app,
            bundleId: "com.skt.AsyncDownloader",
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
                .external(name: "AsyncAlgorithms")
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
