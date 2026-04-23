import SwiftData
import SwiftUI
import UIKit
import UserNotifications

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(RatingManager.self) private var ratingManager
    @Query(sort: \TimeEntry.startTime, order: .forward)
    private var allEntries: [TimeEntry]
    @Query(sort: \CustomCategory.createdAt)
    private var customCategories: [CustomCategory]

    @AppStorage("hourlyRate") private var hourlyRate: Double = 15.0
    @AppStorage("workHoursPerDay") private var workHoursPerDay: Double = 8.0
    @AppStorage("workDaysPerWeek") private var workDaysPerWeek: Int = 5
    @AppStorage("includeWeekends") private var includeWeekends: Bool = false
    @AppStorage("userCountry") private var userCountry: String = ""
    @AppStorage("userIndustry") private var userIndustry: String = ""
    @AppStorage("currency") private var currency: String = "USD"

    @State private var editingField: PreferenceField?
    @State private var isRestoring = false
    @State private var restoreMessage: String?
    @State private var exportURL: URL?
    @State private var showPaywall = false
    @State private var showDeleteConfirmation = false
    @State private var isSigningOut = false
    @State private var isDeletingAccount = false
    @State private var profileSyncError: String?

    private var completedEntries: [TimeEntry] {
        allEntries.filter { !$0.isRunning }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
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

                    Divider()

                    exportSection

                    Divider()

                    restoreSection

                    Divider()

                    accountSection

                    Divider()

                    supportSection
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
            .background(Color.white)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        Haptics.light()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 30, height: 30)
                            .background(Theme.bloodRed, in: Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .toolbarBackground(Theme.cardBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
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
        .fullScreenCover(isPresented: $showPaywall, onDismiss: {
            subscriptionManager.showProBannerIfPending()
        }) {
            PaywallView()
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

    // MARK: - Data Export

    private var exportSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("DATA EXPORT")
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.5))
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
                        .foregroundStyle(Theme.textPrimary.opacity(0.65))
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
                        .foregroundStyle(Theme.textPrimary.opacity(0.4))
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

    // MARK: - Restore

    private var restoreSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("SUBSCRIPTION")
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.5))
                .tracking(1.5)

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
                    .foregroundStyle(restoreMessage.contains("No") ? Theme.textPrimary.opacity(0.5) : Theme.money)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Account

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("ACCOUNT")
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.5))
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
                .foregroundStyle(Theme.textPrimary.opacity(0.65))
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
                .foregroundStyle(Theme.textPrimary.opacity(0.5))
        }
    }

    // MARK: - Support

    private static let supportEmail = "antoniobaltic@icloud.com"

    private var supportSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("HELP DESK")
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.5))
                .tracking(1.5)

            // Version row first inside the section
            HStack {
                Text("Version")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.5))
                Spacer()
                Text("\(appVersion) (\(buildNumber))")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.5))
            }

            Button {
                Haptics.light()
                ratingManager.recordUserInitiatedRating()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "star")
                        .font(.system(.caption, weight: .medium))
                    Text("Rate Hardly Working")
                        .font(.system(.caption, design: .monospaced, weight: .medium))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Theme.accent, in: RoundedRectangle(cornerRadius: 10))
            }

            // Fallback for users whose 3-per-365-days quota is already used:
            // direct link to the App Store write-review page. iOS will
            // silently no-op `requestReview` once the quota is hit, so
            // without this the primary button could appear broken.
            Button {
                Haptics.light()
                ratingManager.openAppStoreReviewPage()
            } label: {
                Text("Or write a review on the App Store")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.5))
                    .underline()
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, -2)

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

            // Centered, separator-dot styled links
            HStack(spacing: 10) {
                Link(destination: URL(string: "https://hardlyworking.app/privacy")!) {
                    Text("Privacy Policy")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(Theme.textPrimary.opacity(0.5))
                }
                Text("\u{B7}")
                    .font(.system(.caption, design: .monospaced, weight: .bold))
                    .foregroundStyle(Theme.textPrimary.opacity(0.3))
                Link(destination: URL(string: "https://hardlyworking.app/terms")!) {
                    Text("Terms of Service")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(Theme.textPrimary.opacity(0.5))
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 4)
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    // MARK: - Actions

    private static let allUserDefaultsKeys = [
        "hourlyRate", "workHoursPerDay", "workDaysPerWeek",
        "includeWeekends", "userCountry", "userIndustry", "currency",
        "userMotivation", "userFrustration", "estimatedProductivity",
        "reclaimerLevel", "reclaimerTitle", "hasCommitted", "isSignedIn",
        "hasEditedEntry", "hasRequestedNotificationPermission",
        "cachedProStatus", "employeeId",
        // RatingManager keys — keep in sync with `RatingManager.Keys`.
        // The legacy `_happinessScore` / `_lastScoreUpdate` / `_lastPromptedVersion`
        // / `_totalPromptsShown` keys are also listed so any pre-update
        // residue is wiped on reset, even though the new manager doesn't
        // write them. Cheap belt-and-braces.
        "rating_installDate", "rating_completedSessions", "rating_lastPromptDate",
        "rating_firedOnboarding", "rating_firedFirstShare",
        "rating_firedProPurchase", "rating_firedThirdSession",
        "rating_happinessScore", "rating_lastScoreUpdate",
        "rating_lastPromptedVersion", "rating_totalPromptsShown",
    ]

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

    private func restorePurchases() async {
        isRestoring = true
        restoreMessage = nil

        let wasPro = subscriptionManager.isProUser
        do {
            try await subscriptionManager.restorePurchases()
            if subscriptionManager.isProUser {
                Haptics.success()
                if !wasPro {
                    // Genuine upgrade — dismiss the sheet so the root-level
                    // celebration banner can slide down over the tab.
                    isRestoring = false
                    dismiss()
                    return
                } else {
                    restoreMessage = "Clearance already active."
                }
            } else {
                restoreMessage = "No prior authorization on file."
            }
        } catch {
            restoreMessage = "Restoration unsuccessful. Contact your department."
        }

        isRestoring = false
    }

    private func signOut() async {
        isSigningOut = true

        do {
            try await SupabaseManager.shared.signOut()
        } catch {
            print("[Account] Supabase sign out failed (proceeding locally): \(error)")
        }

        UserDefaults.standard.removeObject(forKey: "isSignedIn")

        withAnimation(.easeInOut(duration: 0.3)) {
            UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        }
    }

    private func deleteAccount() async {
        isDeletingAccount = true
        defer { isDeletingAccount = false }

        do {
            try await SupabaseManager.shared.deleteAccount()
        } catch {
            print("[Account] Supabase delete failed (proceeding with local cleanup): \(error)")
        }

        do {
            try modelContext.delete(model: TimeEntry.self)
            try modelContext.delete(model: UnlockedAchievement.self)
            try modelContext.delete(model: CustomCategory.self)
            try modelContext.save()
        } catch {
            print("[Account] SwiftData delete failed: \(error)")
        }

        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        Haptics.success()

        for key in Self.allUserDefaultsKeys {
            UserDefaults.standard.removeObject(forKey: key)
        }

        // Routes the app back to onboarding. UserDefaults writes don't
        // animate view transitions on their own, so no animation wrapper.
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
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
            } catch {
                print("[Sync] Profile sync failed: \(error)")
            }
        }
    }

    private func openSupportEmail() {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = Self.supportEmail
        components.queryItems = [
            URLQueryItem(name: "subject", value: "Hardly Working Corp. \u{2014} Support Request"),
        ]

        guard let url = components.url else { return }

        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            UIPasteboard.general.string = Self.supportEmail
            Haptics.success()
        }
    }
}
