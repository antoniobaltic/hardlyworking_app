import SwiftUI

struct CoverStoryEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    let field: PreferenceField

    @Binding var hourlyRate: Double
    @Binding var workHoursPerDay: Double
    @Binding var workDaysPerWeek: Int
    @Binding var userIndustry: String
    @Binding var userCountry: String
    @Binding var currency: String

    // Local editing state
    @State private var rateText: String = ""
    @State private var editHours: Double = 8
    @State private var editDays: Int = 5
    @State private var selectedIndustry: String = ""
    @State private var selectedCountry: String = ""
    @State private var selectedCurrency: String = "USD"
    @State private var countrySearch: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                content
                Spacer()
            }
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
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Haptics.medium()
                        save()
                        dismiss()
                    }
                    .font(.system(.body, design: .monospaced, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .disabled(!canSave)
                }
            }
            .onAppear { loadCurrentValues() }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 4) {
            Text(headerTitle)
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.5))
                .tracking(2)
            Text(headerValue)
                .font(.system(size: 36, weight: .light, design: .monospaced))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Theme.cardBackground)
        .overlay(
            Rectangle().fill(Theme.textPrimary.opacity(0.08)).frame(height: 1),
            alignment: .bottom
        )
    }

    private var headerTitle: String {
        switch field {
        case .hourlyRate: "HOURLY RATE"
        case .workSchedule: "WORK SCHEDULE"
        case .industry: "INDUSTRY"
        case .country: "REGION"
        case .currency: "CURRENCY"
        }
    }

    private var headerValue: String {
        switch field {
        case .hourlyRate:
            if let rate = Double(rateText), rate > 0 {
                return Theme.formatMoney(rate)
            }
            return "\(Theme.currencySymbol(for: UserDefaults.standard.string(forKey: "currency") ?? "USD"))0.00"
        case .workSchedule:
            return "\(Int(editHours))h \u{00D7} \(editDays)d"
        case .industry:
            return selectedIndustry.isEmpty ? "?" : (Industry(rawValue: selectedIndustry)?.emoji ?? "?")
        case .country:
            return selectedCountry.isEmpty ? "?" : selectedCountry
        case .currency:
            return selectedCurrency
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch field {
        case .hourlyRate: hourlyRateContent
        case .workSchedule: workScheduleContent
        case .industry: industryContent
        case .country: countryContent
        case .currency: currencyContent
        }
    }

    // MARK: - Hourly Rate

    private var hourlyRateContent: some View {
        formSection("AMOUNT") {
            HStack(spacing: 8) {
                Text(Theme.currencySymbol(for: UserDefaults.standard.string(forKey: "currency") ?? "USD"))
                    .font(.system(.title3, design: .monospaced, weight: .medium))
                    .foregroundStyle(Theme.textPrimary.opacity(0.5))

                TextField("0.00", text: $rateText)
                    .font(.system(.title3, design: .monospaced, weight: .medium))
                    .keyboardType(.decimalPad)
                    .foregroundStyle(Theme.textPrimary)

                Spacer()

                Text("/hr")
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.5))
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Work Schedule

    private var workScheduleContent: some View {
        VStack(spacing: 0) {
            formSection("HOURS PER DAY") {
                HStack {
                    Text(formattedHours)
                        .font(.system(.title3, design: .monospaced, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                        .frame(width: 60, alignment: .leading)

                    Spacer()

                    Stepper("", value: $editHours, in: 1...24, step: 0.5)
                        .labelsHidden()
                        .onChange(of: editHours) { Haptics.selection() }
                }
                .padding(.horizontal, 24)
            }

            Divider().padding(.horizontal, 24)

            formSection("DAYS PER WEEK") {
                HStack {
                    Text("\(editDays)")
                        .font(.system(.title3, design: .monospaced, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                        .frame(width: 60, alignment: .leading)

                    Spacer()

                    Stepper("", value: $editDays, in: 1...7)
                        .labelsHidden()
                        .onChange(of: editDays) { Haptics.selection() }
                }
                .padding(.horizontal, 24)
            }
        }
    }

    private var formattedHours: String {
        editHours.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(editHours))h"
            : String(format: "%.1fh", editHours)
    }

    // MARK: - Industry

    private var industryContent: some View {
        formSection("SELECT INDUSTRY") {
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(Industry.allCases) { industry in
                        Button {
                            Haptics.light()
                            selectedIndustry = industry.rawValue
                        } label: {
                            HStack(spacing: 4) {
                                Text(industry.emoji)
                                    .font(.caption)
                                Text(industry.rawValue)
                                    .font(.system(
                                        size: 11,
                                        weight: selectedIndustry == industry.rawValue ? .semibold : .regular,
                                        design: .monospaced
                                    ))
                                    .foregroundStyle(selectedIndustry == industry.rawValue ? .white : Theme.textPrimary)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selectedIndustry == industry.rawValue ? Theme.accent : Theme.cardBackground)
                                    .stroke(
                                        selectedIndustry == industry.rawValue ? Color.clear : Theme.textPrimary.opacity(0.1),
                                        lineWidth: 1
                                    )
                            )
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
            .scrollIndicators(.hidden)
        }
    }

    // MARK: - Country

    private var countryContent: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .font(.system(.caption, weight: .medium))
                    .foregroundStyle(Theme.textPrimary.opacity(0.5))
                TextField("Search countries...", text: $countrySearch)
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Theme.cardBackground)
            .overlay(
                Rectangle().fill(Theme.textPrimary.opacity(0.08)).frame(height: 1),
                alignment: .bottom
            )

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(filteredCountries.enumerated()), id: \.element) { index, country in
                        Button {
                            Haptics.light()
                            selectedCountry = country
                        } label: {
                            HStack {
                                Text(country)
                                    .font(.system(.subheadline, design: .monospaced, weight: selectedCountry == country ? .semibold : .regular))
                                    .foregroundStyle(Theme.textPrimary)
                                Spacer()
                                if selectedCountry == country {
                                    Image(systemName: "checkmark")
                                        .font(.system(.caption, weight: .bold))
                                        .foregroundStyle(Theme.accent)
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                selectedCountry == country
                                    ? Theme.accent.opacity(0.06)
                                    : (index.isMultiple(of: 2) ? Theme.cardBackground.opacity(0.4) : Color.clear)
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var filteredCountries: [String] {
        let all = Self.countryList
        if countrySearch.isEmpty { return all }
        return all.filter { $0.localizedCaseInsensitiveContains(countrySearch) }
    }

    // MARK: - Currency

    private var currencyContent: some View {
        formSection("SELECT CURRENCY") {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10),
                ],
                spacing: 10
            ) {
                ForEach(Self.currencyList, id: \.code) { curr in
                    Button {
                        Haptics.light()
                        selectedCurrency = curr.code
                    } label: {
                        VStack(spacing: 4) {
                            Text(curr.symbol)
                                .font(.system(.title3, design: .monospaced, weight: .medium))
                                .foregroundStyle(selectedCurrency == curr.code ? .white : Theme.textPrimary)
                            Text(curr.code)
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundStyle(selectedCurrency == curr.code ? .white.opacity(0.7) : Theme.textPrimary.opacity(0.5))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedCurrency == curr.code ? Theme.accent : Theme.cardBackground.opacity(0.6))
                                .stroke(
                                    selectedCurrency == curr.code ? Color.clear : Theme.textPrimary.opacity(0.06),
                                    lineWidth: 1
                                )
                        )
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Helpers

    private func formSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.5))
                .tracking(1.5)
                .padding(.horizontal, 24)
            content()
        }
        .padding(.vertical, 16)
    }

    private var canSave: Bool {
        switch field {
        case .hourlyRate:
            guard let rate = Double(rateText) else { return false }
            return rate > 0
        case .workSchedule:
            return editHours > 0 && editDays > 0
        case .industry:
            return !selectedIndustry.isEmpty
        case .country:
            return !selectedCountry.isEmpty
        case .currency:
            return !selectedCurrency.isEmpty
        }
    }

    private func loadCurrentValues() {
        rateText = hourlyRate > 0 ? String(format: "%.2f", hourlyRate) : ""
        editHours = workHoursPerDay
        editDays = workDaysPerWeek
        selectedIndustry = userIndustry
        selectedCountry = userCountry
        selectedCurrency = currency
    }

    private func save() {
        switch field {
        case .hourlyRate:
            if let rate = Double(rateText), rate > 0 {
                hourlyRate = rate
            }
        case .workSchedule:
            workHoursPerDay = editHours
            workDaysPerWeek = editDays
        case .industry:
            userIndustry = selectedIndustry
        case .country:
            userCountry = selectedCountry
        case .currency:
            currency = selectedCurrency
        }
    }

    // MARK: - Static Data

    private struct CurrencyOption {
        let code: String
        let symbol: String
    }

    private static let currencyList: [CurrencyOption] = [
        CurrencyOption(code: "USD", symbol: "$"),
        CurrencyOption(code: "EUR", symbol: "\u{20AC}"),
        CurrencyOption(code: "GBP", symbol: "\u{00A3}"),
        CurrencyOption(code: "CAD", symbol: "C$"),
        CurrencyOption(code: "AUD", symbol: "A$"),
        CurrencyOption(code: "JPY", symbol: "\u{00A5}"),
        CurrencyOption(code: "CHF", symbol: "Fr"),
        CurrencyOption(code: "CNY", symbol: "\u{00A5}"),
        CurrencyOption(code: "INR", symbol: "\u{20B9}"),
        CurrencyOption(code: "BRL", symbol: "R$"),
        CurrencyOption(code: "KRW", symbol: "\u{20A9}"),
        CurrencyOption(code: "MXN", symbol: "Mex$"),
    ]

    static let countryList: [String] = {
        Locale.Region.isoRegions.compactMap { region in
            Locale.current.localizedString(forRegionCode: region.identifier)
        }
        .sorted()
    }()
}
