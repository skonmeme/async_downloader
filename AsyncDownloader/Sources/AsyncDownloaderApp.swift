import AppKit
import SwiftUI

//create a class to use as your app's delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        Task {
            do {
                try await ModelLoader().loadModels()
            } catch {
                fatalError("Failed to load models: \(error)")
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    //...add any other NSApplicationDelegate methods you need to use
}

@main
struct AsyncDownloaderApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @State private var modelStates: ModelStates = ModelStates.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(modelStates)
        }
    }
}
