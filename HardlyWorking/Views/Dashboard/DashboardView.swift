import SwiftData
import SwiftUI

struct DashboardView: View {
    @Query(sort: \TimeEntry.startTime, order: .reverse)
    private var allEntries: [TimeEntry]
    @Query(sort: \CustomCategory.createdAt)
    private var customCategories: [CustomCategory]
    @AppStorage("hourlyRate") private var hourlyRate: Double = 15.0
    @AppStorage("workHoursPerDay") private var workHoursPerDay: Double = 8.0
    @AppStorage("includeWeekends") private var includeWeekends: Bool = false
    @State private var viewModel = DashboardViewModel()
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @State private var showPaywall = false

    private var isProUser: Bool { subscriptionManager.isProUser }

    private func isPeriodLocked(_ period: TimePeriod) -> Bool {
        !isProUser && [.month, .year, .lifetime].contains(period)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                formulaBar
                periodSelector
                    .padding(.top, 16)
                    .padding(.bottom, viewModel.showsNavigator ? 8 : 20)

                if viewModel.showsNavigator {
                    dateNavigator
                        .padding(.bottom, 20)
                }

                if isPeriodLocked(viewModel.selectedPeriod) {
                    lockedPeriodContent
                } else if viewModel.filteredEntries(allEntries).isEmpty {
                    emptyState
                } else if viewModel.selectedPeriod == .lifetime {
                    lifetimeContent
                } else {
                    periodContent
                }
            }
        }
        .background(Color.white)
        .onAppear { viewModel.customCategories = customCategories }
        .onChange(of: customCategories) { viewModel.customCategories = customCategories }
        .sheet(isPresented: $showPaywall, onDismiss: {
            subscriptionManager.showProBannerIfPending()
        }) {
            PaywallView()
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Period Content (Day/Week/Month/Year)

    private var periodContent: some View {
        VStack(spacing: 28) {
            executiveSummary

            if viewModel.selectedPeriod != .day {
                Divider().padding(.horizontal, 24)
                PeriodChartView(
                    header: viewModel.chartHeader,
                    data: viewModel.chartBreakdown(allEntries, includeWeekends: includeWeekends)
                )
                .padding(.horizontal, 24)
            }

            Divider().padding(.horizontal, 24)
            CategoryChartView(data: viewModel.categoryBreakdown(allEntries))
                .padding(.horizontal, 24)

            if viewModel.selectedPeriod == .day {
                Divider().padding(.horizontal, 24)
                dayTimeline
            }

            if isProUser {
                Divider().padding(.horizontal, 24)
                InsightsView(insights: viewModel.generateInsights(allEntries, hourlyRate: hourlyRate, includeWeekends: includeWeekends))
                    .padding(.horizontal, 24)
            } else {
                Divider().padding(.horizontal, 24)
                ProLockedView(
                    title: "Audit Findings",
                    description: "Your behavioral analysis requires\nPro clearance to access.",
                    icon: "lightbulb.fill"
                ) { showPaywall = true }
                    .padding(.horizontal, 24)
            }
        }
        .padding(.bottom, 60)
    }

    // MARK: - Locked Period Content

    private var lockedPeriodContent: some View {
        return ProLockedView(
            title: "\(viewModel.selectedPeriod.rawValue) Report",
            description: "This report is classified.\nPro clearance required.",
            icon: "chart.bar.fill"
        ) { showPaywall = true }
            .padding(.horizontal, 24)
            .padding(.top, 40)
            .padding(.bottom, 60)
    }

    // MARK: - Lifetime Content

    private var lifetimeContent: some View {
        let stats = viewModel.careerStats(allEntries, hourlyRate: hourlyRate)
        let rankings = viewModel.categoryRankings(allEntries, hourlyRate: hourlyRate)

        return VStack(spacing: 28) {
            CareerStatsView(stats: stats)
                .padding(.horizontal, 24)

            Divider().padding(.horizontal, 24)

            CategoryRankingsView(rankings: rankings)
                .padding(.horizontal, 24)

            Divider().padding(.horizontal, 24)

            PersonalRecordsView(stats: stats)
                .padding(.horizontal, 24)

            Divider().padding(.horizontal, 24)

            InsightsView(insights: viewModel.generateInsights(allEntries, hourlyRate: hourlyRate))
                .padding(.horizontal, 24)
        }
        .padding(.bottom, 60)
    }

    // MARK: - Formula Bar

    private var formulaBar: some View {
        HStack(spacing: 0) {
            Text("B1")
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

                Text(viewModel.formulaText)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.5))

                Spacer()

                Text(Theme.formatMoney(viewModel.totalMoney(allEntries, hourlyRate: hourlyRate)))
                    .font(.system(.callout, design: .monospaced, weight: .bold))
                    .foregroundStyle(Theme.money)
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

    // MARK: - Period Selector

    private var periodSelector: some View {
        HStack(spacing: 0) {
            ForEach(TimePeriod.allCases) { period in
                let isSelected = viewModel.selectedPeriod == period
                let isLocked = isPeriodLocked(period)
                Button {
                    Haptics.selection()
                    if isLocked {
                        showPaywall = true
                    } else {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            viewModel.selectedPeriod = period
                            viewModel.selectedDate = .now
                        }
                    }
                } label: {
                    HStack(spacing: 3) {
                        Text(period.rawValue)
                            .font(.system(size: 12, weight: isSelected ? .semibold : .regular, design: .monospaced))
                        if isLocked {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 7, weight: .bold))
                        }
                    }
                    .foregroundStyle(
                        isLocked
                            ? Theme.textPrimary.opacity(0.2)
                            : (isSelected ? Theme.textPrimary : Theme.textPrimary.opacity(0.4))
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        isSelected && !isLocked
                            ? Color.white
                            : Theme.cardBackground
                    )
                    .overlay(
                        Rectangle()
                            .fill(isSelected && !isLocked ? Theme.accent : Color.clear)
                            .frame(height: 2),
                        alignment: .bottom
                    )
                }
            }
        }
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Theme.textPrimary.opacity(0.08))
        )
        .padding(.horizontal, 24)
    }

    // MARK: - Date Navigator

    private var dateNavigator: some View {
        HStack {
            Button {
                Haptics.light()
                withAnimation(.easeInOut(duration: 0.15)) {
                    viewModel.navigate(by: -1)
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(.caption, weight: .bold))
                    .foregroundStyle(viewModel.canGoBack ? Theme.accent : Theme.textPrimary.opacity(0.15))
                    .frame(width: 32, height: 32)
                    .background(
                        viewModel.canGoBack
                            ? Theme.accent.opacity(0.1)
                            : Theme.cardBackground,
                        in: RoundedRectangle(cornerRadius: 6)
                    )
            }
            .disabled(!viewModel.canGoBack)
            .accessibilityLabel("Previous period")

            Spacer()

            Text(viewModel.periodLabel)
                .font(.system(.subheadline, design: .monospaced, weight: .medium))
                .foregroundStyle(Theme.textPrimary)

            Spacer()

            Button {
                Haptics.light()
                withAnimation(.easeInOut(duration: 0.15)) {
                    viewModel.navigate(by: 1)
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(.caption, weight: .bold))
                    .foregroundStyle(viewModel.canGoForward ? Theme.accent : Theme.textPrimary.opacity(0.15))
                    .frame(width: 32, height: 32)
                    .background(
                        viewModel.canGoForward
                            ? Theme.accent.opacity(0.1)
                            : Theme.cardBackground,
                        in: RoundedRectangle(cornerRadius: 6)
                    )
            }
            .disabled(!viewModel.canGoForward)
            .accessibilityLabel("Next period")
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Executive Summary

    private var executiveSummary: some View {
        let totalTime = viewModel.totalTime(allEntries)
        let percentage = viewModel.reclaimPercentage(allEntries, workHoursPerDay: workHoursPerDay)
        let count = viewModel.entryCount(allEntries)

        return VStack(alignment: .leading, spacing: 16) {
            Text("EXECUTIVE SUMMARY")
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.3))
                .tracking(1.5)

            HStack(alignment: .firstTextBaseline) {
                Text(Theme.formatDuration(totalTime))
                    .font(.system(size: 36, weight: .light, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary)
                Text("reclaimed")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.4))
                Text("\u{00B7}")
                    .foregroundStyle(Theme.textPrimary.opacity(0.2))
                Text("\(count) \(count == 1 ? "entry" : "entries")")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.4))
            }

            if percentage > 0 {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("RECLAIM RATE (\(Int(workHoursPerDay))H/DAY)")
                            .font(.system(.caption2, design: .monospaced, weight: .bold))
                            .foregroundStyle(Theme.textPrimary.opacity(0.3))
                            .tracking(1.5)
                        Spacer()
                        Text("\(Int(percentage * 100))%")
                            .font(.system(.caption, design: .monospaced, weight: .bold))
                            .foregroundStyle(percentage > 0.5 ? Theme.timer : Theme.accent)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Theme.cardBackground)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(percentage > 0.5 ? Theme.timer : Theme.accent)
                                .frame(width: geo.size.width * percentage)
                        }
                    }
                    .frame(height: 8)
                }
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Day Timeline

    private var dayTimeline: some View {
        let entries = viewModel.filteredEntries(allEntries)
            .sorted { $0.startTime > $1.startTime }

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(viewModel.timelineHeader)
                    .font(.system(.caption2, design: .monospaced, weight: .bold))
                    .foregroundStyle(Theme.textPrimary.opacity(0.3))
                    .tracking(1.5)
                Spacer()
                Text("\(entries.count) \(entries.count == 1 ? "entry" : "entries")")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.25))
            }

            ForEach(Array(entries.enumerated()), id: \.element.persistentModelID) { index, entry in
                HStack(spacing: 10) {
                    // Time column
                    VStack(spacing: 2) {
                        Text(entry.startTime, format: .dateTime.hour().minute())
                        Text(entry.endTime ?? .now, format: .dateTime.hour().minute())
                            .foregroundStyle(Theme.textPrimary.opacity(0.3))
                    }
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.45))
                    .frame(width: 44, alignment: .trailing)

                    // Dot + line
                    VStack(spacing: 0) {
                        Circle()
                            .fill(Theme.accent)
                            .frame(width: 8, height: 8)
                        if index < entries.count - 1 {
                            Rectangle()
                                .fill(Theme.textPrimary.opacity(0.15))
                                .frame(width: 2)
                                .frame(maxHeight: .infinity)
                        }
                    }
                    .frame(width: 8)

                    // Entry details
                    HStack {
                        if let cat = SlackCategory.defaults.first(where: { $0.name == entry.category }) {
                            Text(cat.emoji)
                                .font(.caption)
                        }
                        Text(entry.category)
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                        Text(Theme.formatDuration(entry.duration))
                            .font(.system(.caption, design: .monospaced, weight: .medium))
                            .foregroundStyle(Theme.accent)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(index.isMultiple(of: 2) ? Theme.cardBackground.opacity(0.4) : Color.clear)
                    )
                }
                .frame(minHeight: 44)
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("#REF!")
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(0.06))
            Text("Insufficient data for analysis.")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(0.25))
            Text("Get back to not working.")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(0.2))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 100)
    }
}

#Preview {
    let container = try! ModelContainer(for: TimeEntry.self, configurations: .init(isStoredInMemoryOnly: true))
    let context = container.mainContext

    let calendar = Calendar.current
    let today = calendar.startOfDay(for: .now)

    let sampleData: [(Int, String, Int, Int, Int)] = [
        (0, "Coffee Run", 9, 15, 18),
        (0, "Doom Scrolling", 10, 30, 45),
        (0, "Chatting", 14, 0, 22),
        (1, "Bathroom Break", 9, 45, 12),
        (1, "Looking Busy", 11, 0, 65),
        (1, "Online Shopping", 15, 30, 30),
        (2, "\"Thinking\"", 10, 0, 40),
        (2, "Into the Void", 13, 15, 25),
        (2, "Coffee Run", 16, 0, 15),
        (3, "Doom Scrolling", 9, 30, 55),
        (3, "Errands", 14, 0, 35),
        (4, "Long Lunch", 12, 0, 45),
        (4, "Chatting", 15, 0, 20),
        (4, "Doom Scrolling", 16, 30, 40),
    ]

    for (daysAgo, category, hour, minute, duration) in sampleData {
        let day = calendar.date(byAdding: .day, value: -daysAgo, to: today) ?? today
        let start = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
        let end = start.addingTimeInterval(Double(duration) * 60)
        let entry = TimeEntry(category: category, startTime: start, endTime: end)
        context.insert(entry)
    }

    return DashboardView()
        .modelContainer(container)
}
