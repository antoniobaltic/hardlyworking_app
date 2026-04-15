import RevenueCat
import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SubscriptionManager.self) private var subscriptionManager

    @State private var selectedPlan: Plan = .annual
    @State private var isPurchasing = false
    @State private var errorMessage: String?
    @State private var showContent = false
    @State private var savingsShimmer = false
    private let confettiParticles = ConfettiRainView.makeParticles()

    enum Plan { case weekly, annual }

    // MARK: - Localized Pricing

    private var weeklyPrice: String {
        subscriptionManager.weeklyPackage?.localizedPriceString ?? "$4.99"
    }

    private var annualPrice: String {
        subscriptionManager.annualPackage?.localizedPriceString ?? "$39.99"
    }

    private var annualPerWeek: String {
        if let pkg = subscriptionManager.annualPackage {
            let weekly = pkg.storeProduct.price as Decimal / 52
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = pkg.storeProduct.currencyCode
            formatter.maximumFractionDigits = 2
            return formatter.string(from: weekly as NSDecimalNumber) ?? "$0.77"
        }
        return "$0.77"
    }

    private var weeklyAnnualized: String {
        if let pkg = subscriptionManager.weeklyPackage {
            let yearly = pkg.storeProduct.price as Decimal * 52
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = pkg.storeProduct.currencyCode
            formatter.maximumFractionDigits = 0
            return formatter.string(from: yearly as NSDecimalNumber) ?? "$259"
        }
        return "$259"
    }

    var body: some View {
        VStack(spacing: 0) {
            memoHeader

            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 16)

                    Image("mascot_paywall")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 160)

                    Spacer().frame(height: 20)

                    headline

                    Spacer().frame(height: 24)

                    benefitsList
                        .padding(.horizontal, 24)

                    Spacer().frame(height: 28)

                    pricingCards
                        .padding(.horizontal, 24)

                    Spacer().frame(height: 24)

                    ctaButton
                        .padding(.horizontal, 24)

                    Spacer().frame(height: 8)

                    trialDisclosure

                    Spacer().frame(height: 24)

                    footer

                    Spacer().frame(height: 16)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
            }
            .scrollIndicators(.hidden)
        }
        .overlay { ConfettiRainView(particles: confettiParticles) .allowsHitTesting(false) }
        .background(Color.white)
        .transaction { $0.disablesAnimations = true }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(1.0)) {
                savingsShimmer = true
            }
        }
    }

    // MARK: - Memo Header

    private var memoHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("TO: You (Intern) · FROM: J. Pemberton, CSO")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.45))

                Text("RE: Promotion to Executive Status?")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.6))
            }

            Spacer()

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
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardBackground)
        .overlay(
            Rectangle().fill(Theme.textPrimary.opacity(0.08)).frame(height: 1),
            alignment: .bottom
        )
    }

    // MARK: - Headline

    private var headline: some View {
        VStack(spacing: 8) {
            Text("Someone put in a\ngood word...")
                .font(.system(size: 22, weight: .light, design: .monospaced))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            Text("Now about that, eh... facilitation fee?")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(0.5))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Benefits

    private var benefitsList: some View {
        VStack(alignment: .leading, spacing: 10) {
            benefitRow("Your full career dossier: records, streaks & Month/Year/Career dashboards")
            benefitRow("Global benchmarks by country & industry")
            benefitRow("Unlimited groups, custom activities & CSV export")
            benefitRow("Premium share cards (no watermark) & exclusive commendations")
        }
    }

    private func benefitRow(_ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(.subheadline, weight: .medium))
                .foregroundStyle(Theme.money)
                .frame(width: 20)
            Text(text)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(0.65))
        }
    }

    // MARK: - Pricing Cards

    private var pricingCards: some View {
        HStack(alignment: .top, spacing: 12) {
            pricingCardContent(plan: .weekly)
            pricingCardContent(plan: .annual)
        }
    }

    private func pricingCardContent(plan: Plan) -> some View {
        let isSelected = selectedPlan == plan
        let isAnnual = plan == .annual

        return Button {
            Haptics.selection()
            selectedPlan = plan
        } label: {
            VStack(spacing: 8) {
                // Row 1: Header (aligned across both cards)
                Text(isAnnual ? "ANNUAL" : "WEEKLY")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.6))
                    .tracking(1.5)

                // Row 2: Price (aligned across both cards)
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(isAnnual ? annualPrice : weeklyPrice)
                        .font(.system(.title3, design: .monospaced, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(isAnnual ? "/year" : "/week")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(Theme.textPrimary.opacity(0.4))
                }

                // Row 3: Annual gets trial text, weekly gets empty spacer to match
                if isAnnual {
                    Text("7-day free trial")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(Theme.accent)
                } else {
                    Text(" ")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Theme.accent.opacity(0.06) : Theme.cardBackground.opacity(0.5))
                    .stroke(isSelected ? Theme.accent : Theme.textPrimary.opacity(0.06), lineWidth: isSelected ? 2 : 1)
            )
            .overlay(alignment: .top) {
                if isAnnual {
                    Text("FOUNDING OFFER")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                        .tracking(1)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Theme.money)
                                .overlay(
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [.white.opacity(savingsShimmer ? 0.4 : 0), .white.opacity(0), .white.opacity(savingsShimmer ? 0 : 0.4)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                )
                                .clipShape(Capsule())
                        )
                        .offset(y: -10)
                }
            }
            .scaleEffect(isSelected && isAnnual ? 1.03 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(.plain)
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
                    Text(selectedPlan == .annual ? "Start Free Trial" : "Accept Weekly Contract")
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
                Text("7-day free trial, then \(annualPrice)/year. Cancel anytime.")
            } else {
                Text("\(weeklyPrice)/week. Cancel anytime.")
            }
        }
        .font(.system(.caption2, design: .monospaced))
        .foregroundStyle(Theme.textPrimary.opacity(0.55))
        .multilineTextAlignment(.center)
        .padding(.horizontal, 24)
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                Button {
                    Haptics.light()
                    Task { await handleRestore() }
                } label: {
                    Text("Restore")
                }
                Text("·")
                Link("Terms", destination: URL(string: "https://hardlyworking.app/terms")!)
                Text("·")
                Link("Privacy", destination: URL(string: "https://hardlyworking.app/privacy")!)
            }
            .font(.system(.caption2, design: .monospaced))
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
            errorMessage = "Transaction could not be processed. Please contact the department."
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
                errorMessage = "No prior employment record found."
            }
        } catch {
            errorMessage = "Records could not be retrieved. Contact HR."
        }

        isPurchasing = false
    }
}

// MARK: - Confetti Rain

struct ConfettiRainView: View {
    struct Particle: Identifiable {
        let id: Int
        let x: Double
        let speed: Double
        let size: Double
        let wobbleSpeed: Double
        let wobbleAmount: Double
        let rotation: Double
        let opacity: Double
        let shade: Color
    }

    let particles: [Particle]

    static func makeParticles(count: Int = 40) -> [Particle] {
        let shades: [Color] = [
            Theme.accent,
            Theme.accent.opacity(0.7),
            Theme.accent.opacity(0.4),
            Theme.deadBlue.opacity(0.3),
        ]
        return (0..<count).map { i in
            Particle(
                id: i,
                x: Double.random(in: 0...1),
                speed: Double.random(in: 0.3...1.0),
                size: Double.random(in: 3...7),
                wobbleSpeed: Double.random(in: 0.5...2.0),
                wobbleAmount: Double.random(in: 8...20),
                rotation: Double.random(in: 0...360),
                opacity: Double.random(in: 0.15...0.4),
                shade: shades[i % shades.count]
            )
        }
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            Canvas { context, size in
                for p in particles {
                    let cycleTime = 8.0 / p.speed
                    let progress = (time / cycleTime).truncatingRemainder(dividingBy: 1.0)
                    let y = progress * (size.height + 40) - 20
                    let wobble = sin(time * p.wobbleSpeed) * p.wobbleAmount
                    let x = p.x * size.width + wobble
                    let angle = Angle.degrees(time * 40 * p.speed + p.rotation)

                    context.opacity = p.opacity
                    context.translateBy(x: x, y: y)
                    context.rotate(by: angle)

                    let rect = CGRect(x: -p.size / 2, y: -p.size / 2, width: p.size, height: p.size * 0.6)
                    context.fill(Path(rect), with: .color(p.shade))

                    context.rotate(by: -angle)
                    context.translateBy(x: -x, y: -y)
                }
            }
        }
    }
}
