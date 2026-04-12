import SwiftUI

struct OnboardingWageView: View {
    @Binding var hourlyRate: Double
    @Binding var currency: String
    @Binding var workHoursPerDay: Double

    @State private var rateText: String = ""

    private var dailyPotential: Double {
        (Double(rateText) ?? 0) * workHoursPerDay
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer().frame(height: 16)

                Image("mascot_wage")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 200)

                Spacer().frame(height: 24)

                Text("For reclamation calculations,\ndisclose your hourly compensation rate.")
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.5))
                    .multilineTextAlignment(.center)

                Spacer().frame(height: 28)

                currencyPills

                Spacer().frame(height: 20)

                rateInput

                Spacer().frame(height: 20)

                if let rate = Double(rateText), rate > 0 {
                    Text("Daily reclamation potential: \(Text(Theme.formatMoney(dailyPotential)).font(.system(.subheadline, design: .monospaced, weight: .semibold)).foregroundStyle(Theme.money)).")
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundStyle(Theme.textPrimary.opacity(0.5))
                }
            }
            .padding(.horizontal, 24)
        }
        .scrollIndicators(.hidden)
        .onAppear {
            if hourlyRate > 0 {
                rateText = String(format: "%.2f", hourlyRate)
            }
        }
        .onChange(of: rateText) {
            if let rate = Double(rateText), rate > 0 {
                hourlyRate = rate
            }
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
            Text("$")
                .font(.system(.title2, design: .monospaced, weight: .medium))
                .foregroundStyle(Theme.textPrimary.opacity(0.3))

            TextField("0.00", text: $rateText)
                .font(.system(.title2, design: .monospaced, weight: .medium))
                .keyboardType(.decimalPad)
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)

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
