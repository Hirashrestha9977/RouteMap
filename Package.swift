// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RouteMap",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(name: "RouteMap", targets: ["RouteMap"])
    ],
    targets: [
        .target(name: "RouteMap"),
        .testTarget(name: "RouteMapTests", dependencies: ["RouteMap"])
    ]
)
