import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(RatingManager.self) private var ratingManager
    @Environment(AchievementManager.self) private var achievementManager
    @Environment(SubscriptionManager.self) private var subscriptionManager

    var body: some View {
        @Bindable var ratingBinding = ratingManager

        ZStack(alignment: .top) {
            TabView {
                Tab("Time Sheet", systemImage: "timer") {
                    TimerView()
                }
                Tab("Performance", systemImage: "chart.bar.fill") {
                    DashboardView()
                }
                Tab("Benchmarks", systemImage: "trophy.fill") {
                    WallOfShameView()
                }
                Tab("Groups", systemImage: "person.2.fill") {
                    GroupsView()
                }
                Tab("Profile", systemImage: "person.fill") {
                    RapSheetView()
                }
            }
            .tint(Theme.accent)

            // Banner overlays — only one at a time, achievements take priority
            if let unlock = achievementManager.recentUnlock {
                AchievementUnlockBanner(event: unlock) {
                    achievementManager.dismissUnlock()
                }
                .padding(.top, 50)
                .zIndex(100)
            } else if subscriptionManager.showProUpgradeBanner {
                ProUpgradeBanner {
                    subscriptionManager.showProUpgradeBanner = false
                }
                .padding(.top, 50)
                .zIndex(100)
            }
        }
        .sheet(isPresented: $ratingBinding.showSatisfactionSurvey, onDismiss: {
            ratingManager.dismissSurvey()
        }) {
            SatisfactionSurveyView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                achievementManager.resetForNewSession()
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: TimeEntry.self, inMemory: true)
}
