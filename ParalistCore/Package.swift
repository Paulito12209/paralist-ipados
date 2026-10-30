// swift-tools-version:6.0
// Zusammenhang: Sources/ParalistCore/*, Tests/ParalistCoreTests/*, Tests/ParalistCoreTests/Resources/spoken_corpus.tsv, project.yml
import PackageDescription

let package = Package(
    name: "ParalistCore",
    platforms: [.iOS("26.0"), .macOS("15.0")],
    products: [.library(name: "ParalistCore", targets: ["ParalistCore"])],
    targets: [
        .target(name: "ParalistCore"),
        .testTarget(name: "ParalistCoreTests", dependencies: ["ParalistCore"], resources: [.copy("Resources/spoken_corpus.tsv")]),
    ]
)
