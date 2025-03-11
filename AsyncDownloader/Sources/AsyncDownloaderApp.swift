import SwiftUI

@main
struct AsyncDownloaderApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(ModelManagement.shared)
        }
    }
}
