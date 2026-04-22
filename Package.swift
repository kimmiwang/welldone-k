// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SystematicTodo",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "SystematicTodoShared",
            targets: ["SystematicTodoShared"]
        )
    ],
    targets: [
        .target(
            name: "SystematicTodoShared",
            path: "Sources/Shared"
        )
    ]
)
