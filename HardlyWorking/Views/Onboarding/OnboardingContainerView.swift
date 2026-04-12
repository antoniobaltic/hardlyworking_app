import SwiftUI

struct OnboardingContainerView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("hourlyRate") private var hourlyRate: Double = 15.0
    @AppStorage("currency") private var currency: String = "USD"
    @AppStorage("workHoursPerDay") private var workHoursPerDay: Double = 8.0
    @AppStorage("workDaysPerWeek") private var workDaysPerWeek: Int = 5
    @AppStorage("userCountry") private var userCountry: String = ""
    @AppStorage("userIndustry") private var userIndustry: String = ""
    @AppStorage("userMotivation") private var userMotivation: String = ""
    @AppStorage("userFrustration") private var userFrustration: String = ""
    @AppStorage("estimatedProductivity") private var estimatedProductivity: Int = 50
    @AppStorage("reclaimerLevel") private var reclaimerLevel: Int = 0
    @AppStorage("reclaimerTitle") private var reclaimerTitle: String = ""
    @AppStorage("hasCommitted") private var hasCommitted: Bool = false

    @State private var currentPage = 0
    @State private var showPaywall = false

    private let totalPages = 11

    // Deceleration curve — faster at start, slower at end
    private let progressValues: [Double] = [
        0.15, 0.27, 0.38, 0.48, 0.56, 0.63, 0.70, 0.78, 0.86, 0.93, 1.0,
    ]

    private let sectionHeaders = [
        "",
        "FORM HR-1: INTENT DECLARATION",
        "FORM HR-2: GRIEVANCE INTAKE",
        "FORM HR-3: COMPENSATION RECORD",
        "FORM HR-4: SCHEDULE ON FILE",
        "FORM HR-5: SELF-ASSESSMENT",
        "FORM HR-6: DEPARTMENT FILING",
        "CLEARANCE LEVEL ASSIGNED",
        "PRELIMINARY AUDIT FINDINGS",
        "FORM HR-7: EMPLOYEE PLEDGE",
        "DOSSIER COMPILATION",
    ]

    private var isLoadingScreen: Bool { currentPage == 10 }

    var body: some View {
        VStack(spacing: 0) {
            progressBar
                .padding(.top, 8)
                .padding(.horizontal, 24)

            if currentPage > 0 {
                Text(sectionHeaders[currentPage])
                    .font(.system(.caption2, design: .monospaced, weight: .bold))
                    .foregroundStyle(Theme.textPrimary.opacity(0.3))
                    .tracking(1.5)
                    .padding(.top, 12)
            }

            screenContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if !isLoadingScreen {
                navigationButtons
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
            }
        }
        .background(Color.white)
        .sheet(isPresented: $showPaywall, onDismiss: {
            hasCompletedOnboarding = true
            syncProfileToSupabase()
        }) {
            PaywallView()
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Screen Content

    @ViewBuilder
    private var screenContent: some View {
        switch currentPage {
        case 0:
            OnboardingWelcomeView()
        case 1:
            OnboardingMotivationView(userMotivation: $userMotivation)
        case 2:
            OnboardingFrustrationView(userFrustration: $userFrustration)
        case 3:
            OnboardingWageView(
                hourlyRate: $hourlyRate,
                currency: $currency,
                workHoursPerDay: $workHoursPerDay
            )
        case 4:
            OnboardingScheduleView(
                workHoursPerDay: $workHoursPerDay,
                workDaysPerWeek: $workDaysPerWeek
            )
        case 5:
            OnboardingHonestyView(estimatedProductivity: $estimatedProductivity)
        case 6:
            OnboardingDepartmentView(
                userIndustry: $userIndustry,
                userCountry: $userCountry
            )
        case 7:
            OnboardingPersonalityView(
                estimatedProductivity: estimatedProductivity,
                reclaimerLevel: $reclaimerLevel,
                reclaimerTitle: $reclaimerTitle
            )
        case 8:
            OnboardingInsightView(
                hourlyRate: hourlyRate,
                workHoursPerDay: workHoursPerDay,
                workDaysPerWeek: workDaysPerWeek,
                estimatedProductivity: estimatedProductivity,
                userIndustry: userIndustry,
                userCountry: userCountry
            )
        case 9:
            OnboardingCommitmentView(hasCommitted: $hasCommitted)
        case 10:
            OnboardingLoadingView {
                showPaywall = true
            }
        default:
            EmptyView()
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Theme.cardBackground)
                    .frame(height: 4)

                RoundedRectangle(cornerRadius: 2)
                    .fill(Theme.accent)
                    .frame(width: geo.size.width * progressValues[currentPage], height: 4)
                    .animation(.easeInOut(duration: 0.4), value: currentPage)
            }
        }
        .frame(height: 4)
    }

    // MARK: - Navigation

    private var navigationButtons: some View {
        VStack(spacing: 12) {
            Button {
                Haptics.medium()
                advancePage()
            } label: {
                Text(continueButtonText)
                    .font(.system(.headline, design: .monospaced))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        Theme.accent.opacity(canContinue ? 1 : 0.4),
                        in: RoundedRectangle(cornerRadius: 14)
                    )
            }
            .disabled(!canContinue)

            if currentPage > 0 {
                Button {
                    Haptics.light()
                    withAnimation(.easeInOut(duration: 0.25)) { currentPage -= 1 }
                } label: {
                    Text("Back")
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundStyle(Theme.textPrimary.opacity(0.5))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 24)
                }
            }
        }
    }

    private func advancePage() {
        withAnimation(.easeInOut(duration: 0.25)) {
            currentPage += 1
        }
    }

    private var continueButtonText: String {
        switch currentPage {
        case 0: return "Begin Orientation"
        case 6:
            let filled = !userIndustry.isEmpty && !userCountry.isEmpty
            return filled ? "Continue" : "Skip for now"
        case 9: return "Complete Enrollment"
        default: return "Continue"
        }
    }

    private var canContinue: Bool {
        switch currentPage {
        case 1: !userMotivation.isEmpty
        case 2: !userFrustration.isEmpty
        case 3: hourlyRate > 0
        case 9: hasCommitted
        default: true
        }
    }

    // MARK: - Supabase Sync

    private func syncProfileToSupabase() {
        Task {
            do {
                try await SupabaseManager.shared.syncProfile(
                    industry: userIndustry.isEmpty ? nil : userIndustry,
                    country: userCountry.isEmpty ? nil : userCountry,
                    hourlyRate: hourlyRate,
                    workHoursPerDay: workHoursPerDay,
                    workDaysPerWeek: workDaysPerWeek,
                    reclaimerLevel: reclaimerLevel > 0 ? reclaimerLevel : nil,
                    reclaimerTitle: reclaimerTitle.isEmpty ? nil : reclaimerTitle
                )
            } catch {
                print("[Sync] Profile sync failed: \(error)")
            }
        }
    }
}
