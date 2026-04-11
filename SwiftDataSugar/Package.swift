// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "SwiftDataSugar",
  platforms: [.macOS(.v26), .iOS(.v26), .visionOS(.v26)],
  products: [.library(name: "SwiftDataSugar", targets: ["SwiftDataSugar"])],
  targets: [
    .target(
      name: "SwiftDataSugar",
      path: "Sources",
      swiftSettings: [.enableExperimentalFeature("StrictConcurrency")]
    ), .testTarget(name: "SwiftDataSugarTests", dependencies: ["SwiftDataSugar"], path: "Tests"),
  ],
  swiftLanguageModes: [.v6]
)
