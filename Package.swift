// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Swift_Android_Glue",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "Swift_Android_Glue",
            type: .dynamic,
            targets: ["Swift_Android_Glue"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/Guang1234567/swift-android-logcat.git", .branch("master")),
        .package(url: "https://github.com/Guang1234567/Swift_Android_NativeWindow.git", .branch("master")),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "Swift_Android_Glue",
            dependencies: ["C_Android_Glue", "AndroidSwiftLogcat", "Swift_Android_NativeWindow"]
        ),
        .target(name: "C_Android_Glue",
            dependencies: []
         ),
        .testTarget(
            name: "Swift_Android_GlueTests",
            dependencies: ["Swift_Android_Glue"]),
    ])
