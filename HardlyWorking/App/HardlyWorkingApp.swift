import SwiftData
import SwiftUI

@main
struct HardlyWorkingApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: TimeEntry.self)
    }
}
