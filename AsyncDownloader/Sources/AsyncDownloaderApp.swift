import SwiftUI

@main
struct AsyncDownloaderApp: App {
    @State private var modelState: ModelState = ModelState.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(modelState)
        }
    }
}
