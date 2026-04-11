import RevenueCat
import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SubscriptionManager.self) private var subscriptionManager

    @State private var selectedPlan: Plan = .annual
    @State private var isPurchasing = false
    @State private var errorMessage: String?

    enum Plan { case weekly, annual }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                memoHeader

                Spacer().frame(height: 16)

                Image("mascot_paywall")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 200)

                Spacer().frame(height: 20)

                benefitsList
                    .padding(.horizontal, 24)

                Spacer().frame(height: 24)

                pricingCards
                    .padding(.horizontal, 24)

                Spacer().frame(height: 16)

                socialProof

                Spacer().frame(height: 24)

                ctaButton
                    .padding(.horizontal, 24)

                Spacer().frame(height: 8)

                trialDisclosure

                Spacer().frame(height: 20)

                footerButtons

                Spacer().frame(height: 16)
            }
        }
        .background(Color.white)
        .scrollIndicators(.hidden)
    }

    // MARK: - Memo Header

    private var memoHeader: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("INTERNAL MEMO")
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.3))
                .tracking(1.5)
                .padding(.bottom, 12)

            memoField(label: "TO", value: "New Employee")
            memoField(label: "FROM", value: "Dept. of Time Reclamation")
            memoField(label: "RE", value: "Promotion to Pro")
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardBackground)
        .overlay(
            Rectangle().fill(Theme.textPrimary.opacity(0.08)).frame(height: 1),
            alignment: .bottom
        )
    }

    private func memoField(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label + ":")
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.3))
                .frame(width: 44, alignment: .trailing)
            Text(value)
                .font(.system(.caption, design: .monospaced, weight: .medium))
                .foregroundStyle(Theme.textPrimary)
        }
        .padding(.vertical, 3)
    }

    // MARK: - Benefits

    private var benefitsList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PROMOTION PACKAGE")
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.3))
                .tracking(1.5)

            VStack(alignment: .leading, spacing: 8) {
                benefitRow("Classified reports (Month / Year / All)", included: true)
                benefitRow("Behavioral analytics & dossier", included: true)
                benefitRow("Full international rankings", included: true)
                benefitRow("Form accountability groups", included: true)
                benefitRow("Commendations & titles", included: true)
                benefitRow("Custom activity classifications", included: true)
                benefitRow("Data export & distribution rights", included: true)
            }
        }
    }

    private func benefitRow(_ text: String, included: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: included ? "checkmark.circle.fill" : "xmark.circle")
                .font(.system(.subheadline, weight: .medium))
                .foregroundStyle(included ? Theme.accent : Theme.textPrimary.opacity(0.15))
                .frame(width: 20)
            Text(text)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(included ? Theme.textPrimary.opacity(0.7) : Theme.textPrimary.opacity(0.3))
        }
    }

    // MARK: - Pricing Cards

    private var pricingCards: some View {
        HStack(spacing: 12) {
            pricingCard(
                plan: .weekly,
                title: "WEEKLY",
                price: "$4.99",
                period: "/week",
                subtitle: "$259.48/year",
                subtitleStrikethrough: true,
                badge: nil,
                trialText: nil
            )

            pricingCard(
                plan: .annual,
                title: "ANNUAL",
                price: "$39.99",
                period: "/year",
                subtitle: "$0.77/week",
                subtitleStrikethrough: false,
                badge: "BEST VALUE",
                trialText: "7-day free trial"
            )
        }
    }

    private func pricingCard(
        plan: Plan,
        title: String,
        price: String,
        period: String,
        subtitle: String,
        subtitleStrikethrough: Bool,
        badge: String?,
        trialText: String?
    ) -> some View {
        let isSelected = selectedPlan == plan

        return Button {
            Haptics.selection()
            selectedPlan = plan
        } label: {
            VStack(spacing: 8) {
                if let badge {
                    Text(badge)
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Theme.accent, in: Capsule())
                } else {
                    Spacer().frame(height: 18)
                }

                Text(title)
                    .font(.system(.caption2, design: .monospaced, weight: .bold))
                    .foregroundStyle(Theme.textPrimary.opacity(0.4))
                    .tracking(1)

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(price)
                        .font(.system(.title3, design: .monospaced, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(period)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(Theme.textPrimary.opacity(0.4))
                }

                if subtitleStrikethrough {
                    Text(subtitle)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(Theme.textPrimary.opacity(0.3))
                        .strikethrough()
                } else {
                    Text(subtitle)
                        .font(.system(.caption2, design: .monospaced, weight: .medium))
                        .foregroundStyle(Theme.money)
                }

                if plan == .annual {
                    Text("Save 85%")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Theme.money, in: Capsule())
                }

                if let trialText {
                    Text(trialText)
                        .font(.system(.caption2, design: .monospaced, weight: .medium))
                        .foregroundStyle(Theme.accent)
                } else {
                    Spacer().frame(height: 14)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Theme.accent.opacity(0.06) : Theme.cardBackground.opacity(0.5))
                    .stroke(isSelected ? Theme.accent : Theme.textPrimary.opacity(0.06), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Social Proof

    private var socialProof: some View {
        Text("12,000+ professionals reclaiming $2.4M+ this week")
            .font(.system(.caption2, design: .monospaced))
            .foregroundStyle(Theme.textPrimary.opacity(0.3))
            .multilineTextAlignment(.center)
    }

    // MARK: - CTA

    private var ctaButton: some View {
        Button {
            Haptics.medium()
            Task { await handlePurchase() }
        } label: {
            HStack(spacing: 8) {
                if isPurchasing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(selectedPlan == .annual ? "Start Free Trial" : "Subscribe for $4.99/week")
                        .font(.system(.headline, design: .monospaced))
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14))
        }
        .disabled(isPurchasing)
    }

    private var trialDisclosure: some View {
        Group {
            if selectedPlan == .annual {
                Text("7 days free, then $39.99/year. Cancel anytime.")
            } else {
                Text("$4.99/week. Cancel anytime.")
            }
        }
        .font(.system(.caption2, design: .monospaced))
        .foregroundStyle(Theme.textPrimary.opacity(0.4))
        .multilineTextAlignment(.center)
        .padding(.horizontal, 24)
    }

    // MARK: - Footer

    private var footerButtons: some View {
        VStack(spacing: 12) {
            Button {
                Haptics.light()
                dismiss()
            } label: {
                Text("Maybe later")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.4))
                    .padding(.vertical, 6)
            }

            Button {
                Haptics.light()
                Task { await handleRestore() }
            } label: {
                Text("Restore Purchases")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.35))
            }

            HStack(spacing: 8) {
                // TODO: Replace with real URLs
                Text("Terms")
                Text("\u{00B7}")
                Text("Privacy")
            }
            .font(.system(.caption, design: .monospaced))
            .foregroundStyle(Theme.textPrimary.opacity(0.35))

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(Theme.timer)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
        }
    }

    // MARK: - Purchase Logic

    private func handlePurchase() async {
        let package: Package?
        switch selectedPlan {
        case .weekly: package = subscriptionManager.weeklyPackage
        case .annual: package = subscriptionManager.annualPackage
        }

        guard let package else {
            errorMessage = "Promotion catalog temporarily unavailable."
            return
        }

        isPurchasing = true
        errorMessage = nil

        do {
            let success = try await subscriptionManager.purchase(package)
            if success {
                Haptics.success()
                dismiss()
            }
        } catch {
            errorMessage = "Transaction could not be processed. Try again."
        }

        isPurchasing = false
    }

    private func handleRestore() async {
        isPurchasing = true
        errorMessage = nil

        do {
            try await subscriptionManager.restorePurchases()
            if subscriptionManager.isProUser {
                Haptics.success()
                dismiss()
            } else {
                errorMessage = "No active subscription found."
            }
        } catch {
            errorMessage = "Restoration unsuccessful. Contact HR."
        }

        isPurchasing = false
    }
}
