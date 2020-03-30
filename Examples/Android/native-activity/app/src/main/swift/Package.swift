// swift-tools-version:5.0

import Foundation
import PackageDescription

let packageName = "native-activity"

// generated sources integration
let generatedName = "Generated"
// let generatedPath = ".build/\(generatedName.lowercased())"
let generatedPath = "SwiftGenerated"

let isSourcesGenerated: Bool = {
    let basePath = URL(fileURLWithPath: #file)
        .deletingLastPathComponent()
        .path

    let fileManager = FileManager()
    fileManager.changeCurrentDirectoryPath(basePath)

    var isDirectory: ObjCBool = false
    let exists = fileManager.fileExists(atPath: generatedPath, isDirectory: &isDirectory)

    return exists && isDirectory.boolValue
}()

func addGenerated(_ products: [Product]) -> [Product] {
    if isSourcesGenerated == false {
        return products
    }

    return products + [
        .library(name: packageName, type: .dynamic, targets: [generatedName]),
    ]
}

func addGenerated(_ targets: [Target]) -> [Target] {
    if isSourcesGenerated == false {
        return targets
    }

    return targets + [
        .target(
            name: generatedName,
            dependencies: [
                .byName(name: packageName),
                "java_swift",
                "Java",
                "JavaCoder",
            ],
            path: generatedPath
        ),
    ]
}

// generated sources integration end

let package = Package(
    name: packageName,
    products: addGenerated([
    ]),
    dependencies: [
        .package(url: "https://github.com/readdle/java_swift.git", .exact("2.1.9")),
        .package(url: "https://github.com/readdle/swift-java.git", .exact("0.2.4")),
        .package(url: "https://github.com/readdle/swift-java-coder.git", .exact("1.0.17")),
        .package(url: "https://github.com/Guang1234567/swift-android-logcat.git", .branch("master")),
        .package(url: "https://github.com/Guang1234567/swift-android-trace.git", .branch("master")),
        .package(url: "https://github.com/Guang1234567/swift-backtrace.git", .branch("master")),
        .package(url: "https://github.com/Guang1234567/Swift_OpenGL.git", .branch("gles32_egl15_android")),
        .package(path: "../../../../../../.."),
    ],
    /*
        targets: addGenerated([
            .target(name: "C_Android_Glue",
                    dependencies: []),
            .target(name: packageName,
                    dependencies: [
                        "java_swift",
                        "JavaCoder",
                        "AndroidSwiftLogcat",
                        "AndroidSwiftTrace",
                        "Backtrace",
                        "C_Android_Glue",
                    ],
                    path: "Sources/Swift_Android_Glue",

                    cSettings: [
                        .define("ENABLE_SOMETHING", .when(configuration: .debug)),
                        .define("DISABLE_SOMETHING",
                                .when(platforms: [.linux], configuration: .release)),
                    ],
                    swiftSettings: [
                        .define("ENABLE_SOMETHING", .when(configuration: .debug)),
                        .define("DISABLE_SOMETHING", .when(platforms: [.linux], configuration: .release)),
                    ],
                    linkerSettings: [
                        .linkedLibrary("openssl", .when(platforms: [.linux])),
                        .linkedFramework("openssl", .when(platforms: [.macOS, .tvOS])),
                        .unsafeFlags(["-Icfoo", "-L", "cbar"])
                    ]
            ),
        ])
        */

    targets: addGenerated([
        .target(name: packageName,
                dependencies: [
                    "java_swift",
                    "JavaCoder",
                    "AndroidSwiftLogcat",
                    "AndroidSwiftTrace",
                    "Backtrace",
                    "SGLEGL",
                    "SGLOpenGL",
                    "Swift_Android_Glue",
                ],
                swiftSettings: [
                    .define("ENABLE_SOMETHING", .when(configuration: .debug)),
                ]),
    ])
)
