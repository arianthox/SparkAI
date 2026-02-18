// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "SparkAI",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "SparkAIApp", targets: ["App"]),
        .library(name: "SharedContracts", targets: ["SharedContracts"]),
        .library(name: "CoreDatabase", targets: ["CoreDatabase"]),
        .library(name: "CoreSecurity", targets: ["CoreSecurity"]),
        .library(name: "CoreLogging", targets: ["CoreLogging"]),
        .library(name: "CoreProviders", targets: ["CoreProviders"]),
        .library(name: "CoreSync", targets: ["CoreSync"]),
        .library(name: "FeatureDashboard", targets: ["FeatureDashboard"]),
        .library(name: "FeatureAccounts", targets: ["FeatureAccounts"]),
        .library(name: "FeatureSettings", targets: ["FeatureSettings"])
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.29.3")
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                "SharedContracts",
                "CoreDatabase",
                "CoreSecurity",
                "CoreLogging",
                "CoreProviders",
                "CoreSync",
                "FeatureDashboard",
                "FeatureAccounts",
                "FeatureSettings"
            ],
            path: "SparkAI/App"
        ),
        .target(
            name: "SharedContracts",
            path: "SparkAI/Shared/Contracts"
        ),
        .target(
            name: "CoreDatabase",
            dependencies: [
                "SharedContracts",
                .product(name: "GRDB", package: "GRDB.swift")
            ],
            path: "SparkAI/Core/Database"
        ),
        .target(
            name: "CoreSecurity",
            dependencies: ["SharedContracts"],
            path: "SparkAI/Core/Security"
        ),
        .target(
            name: "CoreLogging",
            path: "SparkAI/Core/Logging"
        ),
        .target(
            name: "CoreProviders",
            dependencies: ["SharedContracts", "CoreSecurity"],
            path: "SparkAI/Core/Providers"
        ),
        .target(
            name: "CoreSync",
            dependencies: [
                "SharedContracts",
                "CoreDatabase",
                "CoreProviders",
                "CoreLogging"
            ],
            path: "SparkAI/Core/Sync"
        ),
        .target(
            name: "FeatureDashboard",
            dependencies: ["SharedContracts", "CoreSync"],
            path: "SparkAI/Features/Dashboard"
        ),
        .target(
            name: "FeatureAccounts",
            dependencies: ["SharedContracts", "CoreSync", "CoreSecurity"],
            path: "SparkAI/Features/Accounts"
        ),
        .target(
            name: "FeatureSettings",
            dependencies: ["SharedContracts", "CoreSync", "CoreLogging"],
            path: "SparkAI/Features/Settings"
        ),
        .testTarget(
            name: "SparkAITests",
            dependencies: [
                "SharedContracts",
                "CoreDatabase",
                "CoreLogging",
                "CoreProviders",
                "CoreSync",
                "CoreSecurity",
                "FeatureAccounts",
                "FeatureSettings"
            ],
            path: "SparkAI/Tests"
        )
    ]
)
