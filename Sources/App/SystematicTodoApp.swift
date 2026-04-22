import SwiftUI

@main
struct SystematicTodoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 700, idealWidth: 1000, minHeight: 500, idealHeight: 700)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1000, height: 700)
    }
}
