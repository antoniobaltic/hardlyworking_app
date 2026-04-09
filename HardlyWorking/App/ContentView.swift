import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Timer", systemImage: "timer") {
                TimerView()
            }
            Tab("The Evidence", systemImage: "chart.bar.fill") {
                DashboardView()
            }
            Tab("Wall of Shame", systemImage: "trophy.fill") {
                WallOfShameView()
            }
            Tab("Rap Sheet", systemImage: "person.fill") {
                ProfileView()
            }
        }
        .tint(Theme.accent)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: TimeEntry.self, inMemory: true)
}
