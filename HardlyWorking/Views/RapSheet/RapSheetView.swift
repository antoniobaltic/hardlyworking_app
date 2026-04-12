import SwiftData
import SwiftUI
import UIKit
import UserNotifications

struct RapSheetView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TimeEntry.startTime, order: .forward)
    private var allEntries: [TimeEntry]
    @AppStorage("hourlyRate") private var hourlyRate: Double = 15.0
    @AppStorage("workHoursPerDay") private var workHoursPerDay: Double = 8.0
    @AppStorage("workDaysPerWeek") private var workDaysPerWeek: Int = 5
    @AppStorage("includeWeekends") private var includeWeekends: Bool = false
    @AppStorage("userCountry") private var userCountry: String = ""
    @AppStorage("userIndustry") private var userIndustry: String = ""
    @AppStorage("currency") private var currency: String = "USD"

    @State private var viewModel = DashboardViewModel()
    @State private var editingField: PreferenceField?
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(AchievementManager.self) private var achievementManager
    @Query(sort: \CustomCategory.createdAt)
    private var customCategories: [CustomCategory]
    @State private var isRestoring = false
    @State private var restoreMessage: String?
    @State private var showPaywall = false
    @State private var exportURL: URL?
    @State private var showShareSheet = false
    @State private var showDeleteConfirmation = false
    @State private var isSigningOut = false
    @State private var isDeletingAccount = false
    @State private var profileSyncError: String?

    private var completedEntries: [TimeEntry] {
        allEntries.filter { !$0.isRunning }
    }

    private var careerStats: DashboardViewModel.CareerStats {
        viewModel.selectedPeriod = .lifetime
        return viewModel.careerStats(allEntries, hourlyRate: hourlyRate)
    }

    private var careerMoney: Double {
        let completed = completedEntries
        let total = completed.reduce(0.0) { $0 + $1.duration }
        return total / 3600.0 * hourlyRate
    }

    private var isActive: Bool {
        guard let latest = completedEntries.last else { return false }
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        return latest.startTime >= weekAgo
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                formulaBar
                if let profileSyncError {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.icloud")
                            .font(.system(.caption2))
                        Text(profileSyncError)
                            .font(.system(.caption2, design: .monospaced))
                    }
                    .foregroundStyle(Theme.cautionYellow)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(Theme.cautionYellow.opacity(0.08))
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                VStack(spacing: 28) {
                    BookingHeaderView(
                        hourlyRate: hourlyRate,
                        userCountry: userCountry,
                        userIndustry: userIndustry,
                        firstEntryDate: completedEntries.first?.startTime,
                        isActive: isActive
                    )
                    .padding(.horizontal, 24)

                    Divider().padding(.horizontal, 24)

                    RapSheetStatsView(stats: careerStats)
                        .padding(.horizontal, 24)

                    Divider().padding(.horizontal, 24)

                    achievementsSection
                        .padding(.horizontal, 24)

                    Divider().padding(.horizontal, 24)

                    shareSection
                        .padding(.horizontal, 24)

                    Divider().padding(.horizontal, 24)

                    CoverStoryView(
                        hourlyRate: hourlyRate,
                        workHoursPerDay: workHoursPerDay,
                        workDaysPerWeek: workDaysPerWeek,
                        includeWeekends: $includeWeekends,
                        userIndustry: userIndustry,
                        userCountry: userCountry,
                        currency: currency,
                        onEdit: { field in
                            Haptics.light()
                            editingField = field
                        }
                    )
                    .padding(.horizontal, 24)

                    Divider().padding(.horizontal, 24)

                    exportSection
                        .padding(.horizontal, 24)

                    Divider().padding(.horizontal, 24)

                    subscriptionSection
                        .padding(.horizontal, 24)

                    Divider().padding(.horizontal, 24)

                    accountSection
                        .padding(.horizontal, 24)

                    Divider().padding(.horizontal, 24)

                    supportSection
                        .padding(.horizontal, 24)

                    aboutSection
                        .padding(.horizontal, 24)
                }
                .padding(.top, 20)
                .padding(.bottom, 60)
            }
        }
        .background(Color.white)
        .sheet(item: $editingField, onDismiss: syncProfileToSupabase) { field in
            CoverStoryEditSheet(
                field: field,
                hourlyRate: $hourlyRate,
                workHoursPerDay: $workHoursPerDay,
                workDaysPerWeek: $workDaysPerWeek,
                userIndustry: $userIndustry,
                userCountry: $userCountry,
                currency: $currency
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showPaywall, onDismiss: {
            subscriptionManager.showProBannerIfPending()
        }) {
            PaywallView()
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(
                data: buildShareCardData(),
                isProUser: subscriptionManager.isProUser
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            achievementManager.modelContext = modelContext
        }
        .alert("TERMINATE EMPLOYMENT", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete Everything", role: .destructive) {
                Haptics.warning()
                Task { await deleteAccount() }
            }
        } message: {
            Text("This will permanently delete your account, all recorded sessions, commendations, and reclamation unit memberships. This cannot be undone.")
        }
    }

    // MARK: - Formula Bar

    private var formulaBar: some View {
        HStack(spacing: 0) {
            Text("E1")
                .font(.system(.caption2, design: .monospaced, weight: .medium))
                .foregroundStyle(Theme.textPrimary.opacity(0.4))
                .frame(width: 28)
                .padding(.vertical, 8)
                .background(Theme.cardBackground)
                .overlay(alignment: .trailing) {
                    Rectangle()
                        .fill(Theme.textPrimary.opacity(0.1))
                        .frame(width: 1)
                }

            HStack {
                Text("fx")
                    .font(.system(.caption2, design: .serif, weight: .bold))
                    .italic()
                    .foregroundStyle(Theme.textPrimary.opacity(0.3))

                Text("=VLOOKUP(\"employee\", records, 4, FALSE)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.5))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer()

                if completedEntries.isEmpty {
                    Text("#N/A")
                        .font(.system(.callout, design: .monospaced, weight: .bold))
                        .foregroundStyle(Theme.textPrimary.opacity(0.3))
                } else {
                    Text(Theme.formatMoney(careerMoney))
                        .font(.system(.callout, design: .monospaced, weight: .bold))
                        .foregroundStyle(Theme.money)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .background(Theme.cardBackground)
        .overlay(
            Rectangle().fill(Theme.textPrimary.opacity(0.08)).frame(height: 1),
            alignment: .top
        )
        .overlay(
            Rectangle().fill(Theme.textPrimary.opacity(0.08)).frame(height: 1),
            alignment: .bottom
        )
    }

    // MARK: - Achievements

    // MARK: - Share

    private var shareSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("DISTRIBUTE")
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.3))
                .tracking(1.5)

            Button {
                Haptics.medium()
                showShareSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(.caption, weight: .medium))
                    Text("Generate Share Card")
                        .font(.system(.caption, design: .monospaced, weight: .medium))
                }
                .foregroundStyle(Theme.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Theme.accent, lineWidth: 1)
                )
            }

            Text("Share your performance review.\nFree cards include attribution.")
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(0.3))
        }
    }

    private func buildShareCardData() -> ShareCardData {
        let stats = careerStats
        let rankings = viewModel.categoryRankings(allEntries, hourlyRate: hourlyRate)
        return ShareCardData.build(
            stats: stats,
            rankings: rankings,
            percentile: nil, // Would need BenchmarkViewModel — keep nil for now
            industry: userIndustry.isEmpty ? nil : userIndustry,
            country: userCountry.isEmpty ? nil : userCountry,
            hourlyRate: hourlyRate,
            customCategories: customCategories
        )
    }

    private var achievementsSection: some View {
        AchievementsView(achievementManager: achievementManager)
    }

    // MARK: - Data Export

    private var exportSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("DATA EXPORT")
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.3))
                .tracking(1.5)

            if subscriptionManager.isProUser {
                VStack(spacing: 12) {
                    if let exportURL {
                        ShareLink(
                            item: exportURL,
                            subject: Text("Hardly Working Corp. — Data Export"),
                            message: Text("Your complete time reclamation records. Handle with discretion.")
                        ) {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(.caption, weight: .medium))
                                Text("Share CSV")
                                    .font(.system(.caption, design: .monospaced, weight: .medium))
                            }
                            .foregroundStyle(Theme.accent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Theme.accent, lineWidth: 1)
                            )
                        }
                    }

                    Button {
                        Haptics.medium()
                        generateExport()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "doc.text")
                                .font(.system(.caption, weight: .medium))
                            Text(exportURL == nil ? "Generate CSV" : "Regenerate CSV")
                                .font(.system(.caption, design: .monospaced, weight: .medium))
                        }
                        .foregroundStyle(Theme.textPrimary.opacity(0.5))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Theme.cardBackground.opacity(0.5))
                                .stroke(Theme.textPrimary.opacity(0.06), lineWidth: 1)
                        )
                    }

                    Text("\(completedEntries.count) entries on file.")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(Theme.textPrimary.opacity(0.25))
                        .frame(maxWidth: .infinity)
                }
            } else {
                ProLockedView(
                    title: "Data Export",
                    description: "Your records require Executive clearance\nfor external distribution.",
                    icon: "doc.text"
                ) { showPaywall = true }
            }
        }
    }

    private func generateExport() {
        exportURL = CSVExporter.generateCSV(
            entries: completedEntries,
            customCategories: customCategories,
            hourlyRate: hourlyRate,
            currency: currency,
            workHoursPerDay: workHoursPerDay,
            workDaysPerWeek: workDaysPerWeek,
            userCountry: userCountry,
            userIndustry: userIndustry
        )
        if exportURL != nil {
            Haptics.success()
        }
    }

    // MARK: - Subscription

    private var subscriptionSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("CLEARANCE LEVEL")
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.3))
                .tracking(1.5)

            HStack {
                Text("Classification")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.5))
                Spacer()
                Text(subscriptionManager.isProUser ? "Executive" : "Intern")
                    .font(.system(.subheadline, design: .monospaced, weight: .medium))
                    .foregroundStyle(subscriptionManager.isProUser ? Theme.money : Theme.textPrimary.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.cardBackground.opacity(0.5))
                    .stroke(Theme.textPrimary.opacity(0.06), lineWidth: 1)
            )

            Button {
                Haptics.light()
                Task { await restorePurchases() }
            } label: {
                HStack(spacing: 6) {
                    if isRestoring {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(.caption, weight: .medium))
                    }
                    Text("Restore Purchases")
                        .font(.system(.caption, design: .monospaced))
                }
                .foregroundStyle(Theme.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Theme.accent.opacity(0.3), lineWidth: 1)
                )
            }
            .disabled(isRestoring)

            if let restoreMessage {
                Text(restoreMessage)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(restoreMessage.contains("No") ? Theme.textPrimary.opacity(0.4) : Theme.money)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Account

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("ACCOUNT")
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.3))
                .tracking(1.5)

            Button {
                Haptics.light()
                Task { await signOut() }
            } label: {
                HStack(spacing: 8) {
                    if isSigningOut {
                        ProgressView().scaleEffect(0.8)
                    } else {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(.caption, weight: .medium))
                    }
                    Text("Sign Out")
                        .font(.system(.caption, design: .monospaced, weight: .medium))
                }
                .foregroundStyle(Theme.textPrimary.opacity(0.5))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Theme.cardBackground.opacity(0.5))
                        .stroke(Theme.textPrimary.opacity(0.06), lineWidth: 1)
                )
            }
            .disabled(isSigningOut)

            Button {
                Haptics.warning()
                showDeleteConfirmation = true
            } label: {
                HStack(spacing: 8) {
                    if isDeletingAccount {
                        ProgressView().scaleEffect(0.8)
                    } else {
                        Image(systemName: "trash")
                            .font(.system(.caption, weight: .medium))
                    }
                    Text("Delete Account")
                        .font(.system(.caption, design: .monospaced, weight: .medium))
                }
                .foregroundStyle(Theme.timer)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Theme.timer.opacity(0.2), lineWidth: 1)
                )
            }
            .disabled(isDeletingAccount)

            Text("Deleting your account removes all data\nfrom our servers. Local data is also erased.")
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(0.3))
        }
    }

    // MARK: - Support

    private static let supportEmail = "antoniobaltic@icloud.com"

    private var supportSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("HELP DESK")
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.3))
                .tracking(1.5)

            Button {
                Haptics.light()
                openSupportEmail()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "envelope")
                        .font(.system(.caption, weight: .medium))
                    Text("Contact Support")
                        .font(.system(.caption, design: .monospaced, weight: .medium))
                }
                .foregroundStyle(Theme.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Theme.accent.opacity(0.3), lineWidth: 1)
                )
            }

            Text(Self.supportEmail)
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(0.3))
        }
    }

    private func openSupportEmail() {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = Self.supportEmail
        components.queryItems = [
            URLQueryItem(name: "subject", value: "Hardly Working \u{2014} Support Request"),
        ]

        guard let url = components.url else { return }

        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            // No mail app configured — copy email to clipboard
            UIPasteboard.general.string = Self.supportEmail
            Haptics.success()
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Version")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.3))
                Spacer()
                Text("\(appVersion) (\(buildNumber))")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.3))
            }
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    // MARK: - Account Actions

    /// All UserDefaults keys used across the app (except onboarding flags which trigger view transition).
    private static let allUserDefaultsKeys = [
        // Work profile
        "hourlyRate", "workHoursPerDay", "workDaysPerWeek",
        "includeWeekends", "userCountry", "userIndustry", "currency",
        // Onboarding answers
        "userMotivation", "userFrustration", "estimatedProductivity",
        "reclaimerLevel", "reclaimerTitle", "hasCommitted", "isSignedIn",
        // Achievement / feature flags
        "hasEditedEntry", "hasRequestedNotificationPermission",
        "cachedProStatus",
        // Rating system
        "rating_installDate", "rating_happinessScore", "rating_lastScoreUpdate",
        "rating_completedSessions", "rating_lastPromptDate",
        "rating_lastPromptedVersion", "rating_totalPromptsShown",
    ]

    private func signOut() async {
        isSigningOut = true

        // Best-effort Supabase sign out — proceed locally even if network fails
        do {
            try await SupabaseManager.shared.signOut()
        } catch {
            print("[Account] Supabase sign out failed (proceeding locally): \(error)")
        }

        // Clear auth-related keys so onboarding shows sign-in button
        UserDefaults.standard.removeObject(forKey: "isSignedIn")

        // Trigger view transition last — this tears down RapSheetView
        withAnimation(.easeInOut(duration: 0.3)) {
            UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
            UserDefaults.standard.set(false, forKey: "hasSeenATTPrompt")
        }
    }

    private func deleteAccount() async {
        isDeletingAccount = true

        // 1. Delete server-side data (best-effort — proceed even if partial failure)
        do {
            try await SupabaseManager.shared.deleteAccount()
        } catch {
            print("[Account] Supabase delete failed (proceeding with local cleanup): \(error)")
        }

        // 2. Wipe local SwiftData
        do {
            try modelContext.delete(model: TimeEntry.self)
            try modelContext.delete(model: UnlockedAchievement.self)
            try modelContext.delete(model: CustomCategory.self)
            try modelContext.save()
        } catch {
            print("[Account] SwiftData delete failed: \(error)")
        }

        // 3. Cancel any pending notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        Haptics.success()

        // 4. Clear ALL UserDefaults keys
        for key in Self.allUserDefaultsKeys {
            UserDefaults.standard.removeObject(forKey: key)
        }

        // 5. Trigger view transition last — tears down this view
        withAnimation(.easeInOut(duration: 0.3)) {
            UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
            UserDefaults.standard.set(false, forKey: "hasSeenATTPrompt")
        }
    }

    private func syncProfileToSupabase() {
        Task {
            do {
                try await SupabaseManager.shared.syncProfile(
                    industry: userIndustry.isEmpty ? nil : userIndustry,
                    country: userCountry.isEmpty ? nil : userCountry,
                    hourlyRate: hourlyRate,
                    workHoursPerDay: workHoursPerDay,
                    workDaysPerWeek: workDaysPerWeek,
                    reclaimerLevel: nil,
                    reclaimerTitle: nil
                )
                profileSyncError = nil
            } catch {
                print("[Sync] Profile sync failed: \(error)")
                profileSyncError = "Profile sync pending — changes saved locally."
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(5))
                    if profileSyncError != nil { profileSyncError = nil }
                }
            }
        }
    }

    private func restorePurchases() async {
        isRestoring = true
        restoreMessage = nil

        do {
            try await subscriptionManager.restorePurchases()
            if subscriptionManager.isProUser {
                restoreMessage = "Clearance level upgraded. Welcome back."
                Haptics.success()
            } else {
                restoreMessage = "No prior authorization on file."
            }
        } catch {
            restoreMessage = "Restoration unsuccessful. Contact your department."
        }

        isRestoring = false
    }
}

#Preview {
    let container = try! ModelContainer(for: TimeEntry.self, configurations: .init(isStoredInMemoryOnly: true))
    let context = container.mainContext
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: .now)

    for daysAgo in 0..<5 {
        let day = calendar.date(byAdding: .day, value: -daysAgo, to: today) ?? today
        let start = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: day) ?? day
        let end = start.addingTimeInterval(Double.random(in: 900...3600))
        let entry = TimeEntry(
            category: SlackCategory.defaults.randomElement()!.name,
            startTime: start,
            endTime: end
        )
        context.insert(entry)
    }

    return RapSheetView()
        .modelContainer(container)
}
