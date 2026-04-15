import SwiftUI

struct OnboardingWageView: View {
    @Binding var hourlyRate: Double
    @Binding var currency: String
    @Binding var workHoursPerDay: Double
    @Binding var workDaysPerWeek: Int

    @State private var rateText: String = ""
    @State private var showMascot = false
    @State private var showBubble = false
    @State private var dialogueStage = 0
    @State private var showReplyButton = false
    @State private var replyPulse = false
    @State private var showSubtitle = false
    @State private var showCurrency = false
    @State private var showInput = false
    @State private var moneyPulse = false

    private var weeklyPotential: Double {
        (Double(rateText) ?? 0) * workHoursPerDay * Double(workDaysPerWeek)
    }

    private var currentSymbol: String {
        Theme.currencySymbol(for: currency)
    }

    private var bubbleText: String {
        switch dialogueStage {
        case 1: "Yes. That's the only thing\nwe're not joking about."
        case 2: "It _is_ good to know."
        default: "Your data is 100% safe,\nby the way."
        }
    }

    private var replyText: String {
        switch dialogueStage {
        case 0: "Really?"
        case 1: "Good to know."
        default: ""
        }
    }

    @FocusState private var isRateFocused: Bool

    var body: some View {
        ScrollViewReader { proxy in
        ScrollView {
            VStack(spacing: 0) {
                Spacer().frame(height: 20)

                ZStack(alignment: .top) {
                    Image("mascot_wage")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 200)
                        .padding(.top, 56)

                    if showBubble {
                        speechBubble
                            .offset(x: 60)
                            .transition(.scale(scale: 0, anchor: .bottom).combined(with: .opacity))
                    }

                    if showReplyButton {
                        replyButton
                            .scaleEffect(replyPulse ? 1.08 : 1.0)
                            .offset(x: 110, y: 72)
                            .transition(.scale(scale: 0, anchor: .topLeading).combined(with: .opacity))
                    }
                }
                .offset(y: showMascot ? 0 : 30)
                .opacity(showMascot ? 1 : 0)

                Spacer().frame(height: 24)

                Text("For reclamation calculations,\ndisclose your gross hourly pay.")
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .opacity(showSubtitle ? 1 : 0)

                Spacer().frame(height: 28)

                currencyPills
                    .opacity(showCurrency ? 1 : 0)
                    .offset(y: showCurrency ? 0 : 10)

                Spacer().frame(height: 20)

                rateInput
                    .id("rateInput")
                    .opacity(showInput ? 1 : 0)
                    .offset(y: showInput ? 0 : 10)

                Spacer().frame(height: 20)

                if let rate = Double(rateText), rate > 0 {
                    VStack(spacing: 8) {
                        Text("Weekly reclamation potential:")
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundStyle(Theme.textPrimary.opacity(0.5))

                        Text(Theme.formatMoney(weeklyPotential))
                            .font(.system(.title2, design: .monospaced, weight: .bold))
                            .foregroundStyle(Theme.money)
                            .scaleEffect(moneyPulse ? 1.05 : 1.0)
                            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: moneyPulse)
                            .onAppear { moneyPulse = true }
                    }
                    .multilineTextAlignment(.center)
                    .transition(.opacity)
                }

                Spacer().frame(height: 80)
            }
            .padding(.horizontal, 24)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .onTapGesture { isRateFocused = false }
        .onChange(of: isRateFocused) {
            if isRateFocused {
                withAnimation {
                    proxy.scrollTo("rateInput", anchor: .center)
                }
            }
        }
        } // ScrollViewReader
        .onAppear {
            if hourlyRate > 0 {
                rateText = String(format: "%.2f", hourlyRate)
            }
            startSequence()
        }
        .onChange(of: rateText) {
            if let rate = Double(rateText) {
                hourlyRate = rate
            }
        }
    }

    // MARK: - Speech Bubble

    private var speechBubble: some View {
        Text(LocalizedStringKey(bubbleText))
            .font(.system(.caption, design: .monospaced, weight: .medium))
            .foregroundStyle(Theme.textPrimary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background {
                WageBubbleShape(tailOffset: -20)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
            }
            .background {
                WageBubbleShape(tailOffset: -20)
                    .stroke(Theme.textPrimary.opacity(0.12), lineWidth: 1)
            }
            .animation(.easeInOut(duration: 0.3), value: dialogueStage)
    }

    // MARK: - Reply Button

    private var replyButton: some View {
        Button {
            Haptics.light()
            let nextStage = dialogueStage + 1

            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showReplyButton = false
                replyPulse = false
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    dialogueStage = nextStage
                }

                if nextStage < 2 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                            showReplyButton = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                                replyPulse = true
                            }
                        }
                    }
                }
            }
        } label: {
            Text(replyText)
                .font(.system(.caption, design: .monospaced, weight: .medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Theme.accent)
                        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
                }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Animation

    private func startSequence() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            showMascot = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { showBubble = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { showReplyButton = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    replyPulse = true
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeOut(duration: 0.4)) { showSubtitle = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 0.4)) { showCurrency = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeOut(duration: 0.4)) { showInput = true }
        }
    }

    // MARK: - Currency Pills

    private var currencyPills: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(Self.currencies, id: \.code) { curr in
                    Button {
                        Haptics.light()
                        currency = curr.code
                    } label: {
                        HStack(spacing: 4) {
                            Text(curr.symbol)
                                .font(.system(.caption, design: .monospaced, weight: .medium))
                                .foregroundStyle(currency == curr.code ? .white : Theme.textPrimary)
                            Text(curr.code)
                                .font(.system(size: 11, weight: currency == curr.code ? .semibold : .regular, design: .monospaced))
                                .foregroundStyle(currency == curr.code ? .white : Theme.textPrimary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(currency == curr.code ? Theme.accent : Theme.cardBackground)
                                .stroke(
                                    currency == curr.code ? Color.clear : Theme.textPrimary.opacity(0.1),
                                    lineWidth: 1
                                )
                        )
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Rate Input

    private var rateInput: some View {
        HStack(spacing: 8) {
            Text(currentSymbol)
                .font(.system(.title2, design: .monospaced, weight: .medium))
                .foregroundStyle(Theme.textPrimary.opacity(0.3))

            TextField("0.00", text: $rateText)
                .font(.system(.title2, design: .monospaced, weight: .medium))
                .keyboardType(.decimalPad)
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
                .focused($isRateFocused)

            Text("/hr")
                .font(.system(.subheadline, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(0.3))
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.cardBackground.opacity(0.5))
                .stroke(Theme.textPrimary.opacity(0.06), lineWidth: 1)
        )
    }

    // MARK: - Data

    private struct CurrencyInfo: Hashable {
        let code: String
        let symbol: String
    }

    private static let currencies: [CurrencyInfo] = [
        CurrencyInfo(code: "USD", symbol: "$"),
        CurrencyInfo(code: "EUR", symbol: "\u{20AC}"),
        CurrencyInfo(code: "GBP", symbol: "\u{00A3}"),
        CurrencyInfo(code: "CAD", symbol: "C$"),
        CurrencyInfo(code: "AUD", symbol: "A$"),
        CurrencyInfo(code: "JPY", symbol: "\u{00A5}"),
        CurrencyInfo(code: "CHF", symbol: "Fr"),
        CurrencyInfo(code: "INR", symbol: "\u{20B9}"),
        CurrencyInfo(code: "BRL", symbol: "R$"),
        CurrencyInfo(code: "KRW", symbol: "\u{20A9}"),
        CurrencyInfo(code: "MXN", symbol: "Mex$"),
    ]
}

// MARK: - Bubble Shape

private struct WageBubbleShape: Shape {
    var tailOffset: CGFloat = 0
    var cornerRadius: CGFloat = 10
    var tailWidth: CGFloat = 12
    var tailHeight: CGFloat = 8

    func path(in rect: CGRect) -> Path {
        let r = cornerRadius
        let tailCenterX = rect.midX + tailOffset
        let tailLeft = tailCenterX - tailWidth / 2
        let tailRight = tailCenterX + tailWidth / 2

        var p = Path()
        p.move(to: CGPoint(x: rect.minX + r, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
        p.addArc(center: CGPoint(x: rect.maxX - r, y: rect.minY + r),
                 radius: r, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
        p.addArc(center: CGPoint(x: rect.maxX - r, y: rect.maxY - r),
                 radius: r, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        p.addLine(to: CGPoint(x: tailRight, y: rect.maxY))
        p.addLine(to: CGPoint(x: tailCenterX, y: rect.maxY + tailHeight))
        p.addLine(to: CGPoint(x: tailLeft, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX + r, y: rect.maxY))
        p.addArc(center: CGPoint(x: rect.minX + r, y: rect.maxY - r),
                 radius: r, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
        p.addArc(center: CGPoint(x: rect.minX + r, y: rect.minY + r),
                 radius: r, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        p.closeSubpath()
        return p
    }
}
