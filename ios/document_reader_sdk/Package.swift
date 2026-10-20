// swift-tools-version: 5.9
// Flutter plugin package for document_reader_sdk (CocoaPods + SwiftPM).
// Requires Frameworks/documentlivenesssdk.xcframework next to this file — on macOS run:
//   dart run tool/bootstrap.dart
// or: cd example/ios && pod install
// after placing ios/Frameworks/documentlivenesssdk.framework.
//
// Note: local path checkouts whose folder name is not `document_reader_sdk`
// (e.g. ID-Document-Recognition-Liveness-Detection-Flutter) hit Flutter SPM identity bugs
// (flutter/flutter#186881). The example disables SPM and uses CocoaPods.

import PackageDescription

let package = Package(
  name: "document_reader_sdk",
  platforms: [
    .iOS("15.0")
  ],
  products: [
    .library(name: "document-reader-sdk", targets: ["document_reader_sdk"])
  ],
  dependencies: [
    // Required by Flutter tooling when SPM is enabled (ephemeral Packages/.packages).
    .package(name: "FlutterFramework", path: "../FlutterFramework")
  ],
  targets: [
    // Must live inside this package directory. Relative `../Frameworks` breaks
    // when Flutter links the package under ephemeral/Packages/.packages/.
    .binaryTarget(
      name: "documentlivenesssdk",
      path: "Frameworks/documentlivenesssdk.xcframework"
    ),
    .target(
      name: "document_reader_sdk",
      dependencies: [
        "documentlivenesssdk",
        .product(name: "FlutterFramework", package: "FlutterFramework")
      ],
      publicHeadersPath: ".",
      cSettings: [
        .headerSearchPath(".")
      ],
      linkerSettings: [
        .linkedFramework("UIKit"),
        .linkedFramework("Foundation")
      ]
    )
  ]
)
