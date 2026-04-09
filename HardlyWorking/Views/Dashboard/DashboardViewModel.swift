import Foundation

enum TimePeriod: String, CaseIterable, Identifiable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
    case year = "Year"
    case lifetime = "All"

    var id: String { rawValue }
}

struct ChartBar: Identifiable {
    let id = UUID()
    let date: Date
    let label: String
    let totalDuration: TimeInterval
    let isCurrent: Bool
}

struct CategorySlack: Identifiable {
    let id = UUID()
    let name: String
    let emoji: String
    let totalDuration: TimeInterval
    let percentage: Double
}

struct Insight: Identifiable {
    let id = UUID()
    let text: String
}

@Observable @MainActor
final class DashboardViewModel {
    var selectedPeriod: TimePeriod = .week
    var selectedDate: Date = .now

    // MARK: - Date Navigation

    private var calendar: Calendar { Calendar.current }

    var isCurrent: Bool {
        switch selectedPeriod {
        case .day: calendar.isDateInToday(selectedDate)
        case .week: calendar.isDate(selectedDate, equalTo: .now, toGranularity: .weekOfYear)
        case .month: calendar.isDate(selectedDate, equalTo: .now, toGranularity: .month)
        case .year: calendar.isDate(selectedDate, equalTo: .now, toGranularity: .year)
        case .lifetime: true
        }
    }

    var canGoForward: Bool {
        selectedPeriod == .lifetime ? false : !isCurrent
    }

    var canGoBack: Bool {
        if selectedPeriod == .lifetime { return false }
        return dateRange(for: selectedPeriod).start > calendar.startOfDay(for: earliestDate)
    }

    var showsNavigator: Bool {
        selectedPeriod != .lifetime
    }

    private var earliestDate: Date {
        switch selectedPeriod {
        case .day: calendar.date(byAdding: .day, value: -90, to: .now)!
        case .week: calendar.date(byAdding: .weekOfYear, value: -50, to: .now)!
        case .month: calendar.date(byAdding: .month, value: -24, to: .now)!
        case .year: calendar.date(byAdding: .year, value: -10, to: .now)!
        case .lifetime: .distantPast
        }
    }

    func navigate(by offset: Int) {
        if selectedPeriod == .lifetime { return }

        let component: Calendar.Component = switch selectedPeriod {
        case .day: .day
        case .week: .weekOfYear
        case .month: .month
        case .year, .lifetime: .year
        }

        guard let newDate = calendar.date(byAdding: component, value: offset, to: selectedDate) else { return }
        let today = calendar.startOfDay(for: .now)
        let candidateStart = calendar.startOfDay(for: newDate)

        if candidateStart >= calendar.startOfDay(for: earliestDate) && candidateStart <= today {
            selectedDate = newDate
        }
    }

    var periodLabel: String {
        switch selectedPeriod {
        case .day:
            if calendar.isDateInToday(selectedDate) { return "Today" }
            if calendar.isDateInYesterday(selectedDate) { return "Yesterday" }
            let f = DateFormatter()
            f.dateFormat = "EEE, MMM d"
            return f.string(from: selectedDate)

        case .week:
            if isCurrent { return "This Week" }
            let range = dateRange(for: .week)
            let f = DateFormatter()
            f.dateFormat = "MMM d"
            let endDate = calendar.date(byAdding: .day, value: -1, to: calendar.date(byAdding: .weekOfYear, value: 1, to: range.start)!)!
            return "\(f.string(from: range.start)) – \(f.string(from: endDate))"

        case .month:
            if isCurrent { return "This Month" }
            let f = DateFormatter()
            f.dateFormat = "MMMM yyyy"
            return f.string(from: selectedDate)

        case .year:
            if isCurrent { return "This Year" }
            let f = DateFormatter()
            f.dateFormat = "yyyy"
            return f.string(from: selectedDate)

        case .lifetime:
            return "All Time"
        }
    }

    var formulaText: String {
        switch selectedPeriod {
        case .day:
            if calendar.isDateInToday(selectedDate) {
                return "=SUM(today_reclaimed)"
            }
            let f = DateFormatter()
            f.dateFormat = "MMM_d"
            return "=SUM(\(f.string(from: selectedDate).lowercased())_reclaimed)"
        case .week: return "=SUM(weekly_reclaimed)"
        case .month: return "=SUM(monthly_reclaimed)"
        case .year: return "=SUM(annual_reclaimed)"
        case .lifetime: return "=SUM(lifetime_reclaimed)"
        }
    }

    var timelineHeader: String {
        calendar.isDateInToday(selectedDate) ? "TODAY'S TIMELINE" : "TIMELINE"
    }

    // MARK: - Period Filtering

    func dateRange(for period: TimePeriod) -> (start: Date, end: Date) {
        switch period {
        case .day:
            let start = calendar.startOfDay(for: selectedDate)
            let end = calendar.date(byAdding: .day, value: 1, to: start)!
            return (start, isCurrent ? .now : end)

        case .week:
            let comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate)
            let start = calendar.date(from: comps)!
            if isCurrent { return (start, .now) }
            let end = calendar.date(byAdding: .weekOfYear, value: 1, to: start)!
            return (start, end)

        case .month:
            let comps = calendar.dateComponents([.year, .month], from: selectedDate)
            let start = calendar.date(from: comps)!
            if isCurrent { return (start, .now) }
            let end = calendar.date(byAdding: .month, value: 1, to: start)!
            return (start, end)

        case .year:
            let comps = calendar.dateComponents([.year], from: selectedDate)
            let start = calendar.date(from: comps)!
            if isCurrent { return (start, .now) }
            let end = calendar.date(byAdding: .year, value: 1, to: start)!
            return (start, end)

        case .lifetime:
            return (.distantPast, .now)
        }
    }

    func filteredEntries(_ entries: [TimeEntry]) -> [TimeEntry] {
        let range = dateRange(for: selectedPeriod)
        return entries.filter { !$0.isRunning && $0.startTime >= range.start && $0.startTime < range.end }
    }

    // MARK: - Summary Stats

    func totalTime(_ entries: [TimeEntry]) -> TimeInterval {
        filteredEntries(entries).reduce(0) { $0 + $1.duration }
    }

    func totalMoney(_ entries: [TimeEntry], hourlyRate: Double) -> Double {
        totalTime(entries) / 3600.0 * hourlyRate
    }

    func entryCount(_ entries: [TimeEntry]) -> Int {
        filteredEntries(entries).count
    }

    // MARK: - Lifetime Stats

    struct CareerStats {
        let totalTime: TimeInterval
        let totalMoney: Double
        let totalSessions: Int
        let daysActive: Int
        let avgPerWorkDay: TimeInterval
        let longestSession: (duration: TimeInterval, category: String, date: Date)?
        let laziestDay: (duration: TimeInterval, date: Date)?
        let mostSessionsDay: (count: Int, date: Date)?
    }

    func careerStats(_ entries: [TimeEntry], hourlyRate: Double) -> CareerStats {
        let filtered = filteredEntries(entries)
        let total = filtered.reduce(0.0) { $0 + $1.duration }

        // Days active
        var uniqueDays = Set<String>()
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "yyyy-MM-dd"
        for entry in filtered {
            uniqueDays.insert(dayFormatter.string(from: entry.startTime))
        }

        // Average per work day
        let avgPerDay = uniqueDays.isEmpty ? 0 : total / Double(uniqueDays.count)

        // Longest single session
        let longest = filtered.max(by: { $0.duration < $1.duration })

        // Laziest single day
        var dayTotals: [String: (duration: TimeInterval, date: Date)] = [:]
        for entry in filtered {
            let key = dayFormatter.string(from: entry.startTime)
            let existing = dayTotals[key]?.duration ?? 0
            dayTotals[key] = (existing + entry.duration, entry.startTime)
        }
        let laziest = dayTotals.values.max(by: { $0.duration < $1.duration })

        // Most sessions in one day
        var dayCounts: [String: (count: Int, date: Date)] = [:]
        for entry in filtered {
            let key = dayFormatter.string(from: entry.startTime)
            let existing = dayCounts[key]?.count ?? 0
            dayCounts[key] = (existing + 1, entry.startTime)
        }
        let mostSessions = dayCounts.values.max(by: { $0.count < $1.count })

        return CareerStats(
            totalTime: total,
            totalMoney: total / 3600.0 * hourlyRate,
            totalSessions: filtered.count,
            daysActive: uniqueDays.count,
            avgPerWorkDay: avgPerDay,
            longestSession: longest.map { ($0.duration, $0.category, $0.startTime) },
            laziestDay: laziest,
            mostSessionsDay: mostSessions
        )
    }

    struct CategoryRank: Identifiable {
        let id = UUID()
        let rank: Int
        let name: String
        let emoji: String
        let totalDuration: TimeInterval
        let totalMoney: Double
        let percentage: Double
    }

    func categoryRankings(_ entries: [TimeEntry], hourlyRate: Double) -> [CategoryRank] {
        let categories = categoryBreakdown(entries)
        return categories.enumerated().map { index, cat in
            CategoryRank(
                rank: index + 1,
                name: cat.name,
                emoji: cat.emoji,
                totalDuration: cat.totalDuration,
                totalMoney: cat.totalDuration / 3600.0 * hourlyRate,
                percentage: cat.percentage
            )
        }
    }

    func reclaimPercentage(_ entries: [TimeEntry], workHoursPerDay: Double) -> Double {
        if selectedPeriod == .day {
            let weekday = calendar.component(.weekday, from: selectedDate)
            let isWeekend = weekday == 1 || weekday == 7
            if isWeekend { return 0 }
            let workSeconds = workHoursPerDay * 3600
            guard workSeconds > 0 else { return 0 }
            return min(1.0, totalTime(entries) / workSeconds)
        }

        if selectedPeriod == .lifetime {
            let filtered = filteredEntries(entries)
            guard let earliest = filtered.min(by: { $0.startTime < $1.startTime })?.startTime else { return 0 }
            let days = max(1, calendar.dateComponents([.day], from: earliest, to: .now).day ?? 1)
            let weekdays = countWeekdays(from: earliest, days: days)
            let workSeconds = Double(weekdays) * workHoursPerDay * 3600
            guard workSeconds > 0 else { return 0 }
            return min(1.0, totalTime(entries) / workSeconds)
        }

        let range = dateRange(for: selectedPeriod)
        let days = max(1, calendar.dateComponents([.day], from: range.start, to: range.end).day ?? 1)
        let weekdays = countWeekdays(from: range.start, days: days)
        let workSeconds = Double(weekdays) * workHoursPerDay * 3600
        guard workSeconds > 0 else { return 0 }
        return min(1.0, totalTime(entries) / workSeconds)
    }

    // MARK: - Chart Breakdown

    var chartHeader: String {
        switch selectedPeriod {
        case .day: "DAILY RECLAIM REPORT"
        case .week: "DAILY RECLAIM REPORT"
        case .month: "WEEKLY RECLAIM REPORT"
        case .year: "MONTHLY RECLAIM REPORT"
        case .lifetime: lifetimeSpansMultipleYears ? "YEARLY RECLAIM REPORT" : "MONTHLY RECLAIM REPORT"
        }
    }

    private var lifetimeSpansMultipleYears: Bool {
        let yearNow = calendar.component(.year, from: .now)
        let yearStart = calendar.component(.year, from: selectedDate)
        return yearNow > yearStart
    }

    func chartBreakdown(_ entries: [TimeEntry], includeWeekends: Bool) -> [ChartBar] {
        switch selectedPeriod {
        case .week: weeklyDailyBreakdown(entries, includeWeekends: includeWeekends)
        case .month: monthlyWeeklyBreakdown(entries)
        case .year: yearlyMonthlyBreakdown(entries)
        case .lifetime: lifetimeBreakdown(entries)
        case .day: []
        }
    }

    // Week → daily bars (Mon-Fri)
    private func weeklyDailyBreakdown(_ entries: [TimeEntry], includeWeekends: Bool) -> [ChartBar] {
        let filtered = filteredEntries(entries)
        let today = calendar.startOfDay(for: .now)
        let range = dateRange(for: selectedPeriod)
        let weekStart = calendar.startOfDay(for: range.start)
        let endDate = calendar.date(byAdding: .day, value: includeWeekends ? 6 : 4, to: weekStart)!

        var days: [Date] = []
        var current = weekStart
        while current <= endDate {
            let weekday = calendar.component(.weekday, from: current)
            let isWeekend = weekday == 1 || weekday == 7
            if includeWeekends || !isWeekend {
                days.append(current)
            }
            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"

        return days.map { day in
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: day)!
            let total = filtered.filter { $0.startTime >= day && $0.startTime < dayEnd }
                .reduce(0.0) { $0 + $1.duration }
            return ChartBar(
                date: day,
                label: formatter.string(from: day),
                totalDuration: total,
                isCurrent: calendar.isDate(day, inSameDayAs: today)
            )
        }
    }

    // Month → weekly bars, split at month boundaries
    private func monthlyWeeklyBreakdown(_ entries: [TimeEntry]) -> [ChartBar] {
        let filtered = filteredEntries(entries)
        let today = calendar.startOfDay(for: .now)

        let monthComps = calendar.dateComponents([.year, .month], from: selectedDate)
        let monthStart = calendar.date(from: monthComps)!
        let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart)!

        var weekCursor = monthStart
        let wd = calendar.component(.weekday, from: weekCursor)
        let daysFromMonday = (wd + 5) % 7
        weekCursor = calendar.date(byAdding: .day, value: -daysFromMonday, to: weekCursor)!

        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "d"

        let monthDayFormatter = DateFormatter()
        monthDayFormatter.dateFormat = "MMM d"

        var bars: [ChartBar] = []

        while weekCursor < monthEnd {
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekCursor)!
            let clampedStart = max(weekCursor, monthStart)
            let clampedEnd = min(weekEnd, monthEnd)
            let labelEnd = calendar.date(byAdding: .day, value: -1, to: clampedEnd)!

            let startLabel = monthDayFormatter.string(from: clampedStart)
            let endDay = dayFormatter.string(from: labelEnd)
            let label = calendar.isDate(clampedStart, inSameDayAs: labelEnd)
                ? startLabel
                : "\(startLabel)\u{2013}\(endDay)"

            let total = filtered
                .filter { $0.startTime >= clampedStart && $0.startTime < clampedEnd }
                .reduce(0.0) { $0 + $1.duration }

            bars.append(ChartBar(
                date: clampedStart,
                label: label,
                totalDuration: total,
                isCurrent: weekCursor <= today && today < weekEnd
            ))

            weekCursor = weekEnd
        }

        return bars
    }

    // Year → all 12 monthly bars (Jan-Dec)
    private func yearlyMonthlyBreakdown(_ entries: [TimeEntry]) -> [ChartBar] {
        let filtered = filteredEntries(entries)
        let today = calendar.startOfDay(for: .now)

        let yearComps = calendar.dateComponents([.year], from: selectedDate)
        let yearStart = calendar.date(from: yearComps)!

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"

        return (0..<12).map { monthOffset in
            let month = calendar.date(byAdding: .month, value: monthOffset, to: yearStart)!
            let monthEnd = calendar.date(byAdding: .month, value: 1, to: month)!
            let total = filtered
                .filter { $0.startTime >= month && $0.startTime < monthEnd }
                .reduce(0.0) { $0 + $1.duration }
            return ChartBar(
                date: month,
                label: formatter.string(from: month),
                totalDuration: total,
                isCurrent: calendar.isDate(month, equalTo: today, toGranularity: .month)
            )
        }
    }

    // Lifetime → yearly bars if multi-year, monthly bars if single year
    private func lifetimeBreakdown(_ entries: [TimeEntry]) -> [ChartBar] {
        let filtered = filteredEntries(entries)
        guard let earliest = filtered.min(by: { $0.startTime < $1.startTime })?.startTime else { return [] }

        let today = calendar.startOfDay(for: .now)
        let startYear = calendar.component(.year, from: earliest)
        let currentYear = calendar.component(.year, from: today)

        if currentYear > startYear {
            // Multi-year: yearly bars
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy"

            return (startYear...currentYear).map { year in
                let yearStart = calendar.date(from: DateComponents(year: year))!
                let yearEnd = calendar.date(from: DateComponents(year: year + 1))!
                let total = filtered
                    .filter { $0.startTime >= yearStart && $0.startTime < yearEnd }
                    .reduce(0.0) { $0 + $1.duration }
                return ChartBar(
                    date: yearStart,
                    label: formatter.string(from: yearStart),
                    totalDuration: total,
                    isCurrent: year == currentYear
                )
            }
        } else {
            // Single year: monthly bars (inline, no state mutation)
            let yearComps = calendar.dateComponents([.year], from: Date.now)
            let yearStart = calendar.date(from: yearComps)!
            let fmt = DateFormatter()
            fmt.dateFormat = "MMM"

            return (0..<12).map { offset in
                let month = calendar.date(byAdding: .month, value: offset, to: yearStart)!
                let monthEnd = calendar.date(byAdding: .month, value: 1, to: month)!
                let total = filtered
                    .filter { $0.startTime >= month && $0.startTime < monthEnd }
                    .reduce(0.0) { $0 + $1.duration }
                return ChartBar(
                    date: month,
                    label: fmt.string(from: month),
                    totalDuration: total,
                    isCurrent: calendar.isDate(month, equalTo: today, toGranularity: .month)
                )
            }
        }
    }

    // MARK: - Category Breakdown

    func categoryBreakdown(_ entries: [TimeEntry]) -> [CategorySlack] {
        let filtered = filteredEntries(entries)
        let total = filtered.reduce(0.0) { $0 + $1.duration }
        guard total > 0 else { return [] }

        var grouped: [String: TimeInterval] = [:]
        for entry in filtered {
            grouped[entry.category, default: 0] += entry.duration
        }

        return grouped
            .sorted { $0.value > $1.value }
            .map { name, duration in
                let emoji = SlackCategory.defaults.first { $0.name == name }?.emoji ?? "\u{2753}"
                return CategorySlack(
                    name: name,
                    emoji: emoji,
                    totalDuration: duration,
                    percentage: duration / total
                )
            }
    }

    // MARK: - Insights

    func generateInsights(_ entries: [TimeEntry], hourlyRate: Double, includeWeekends: Bool = false) -> [Insight] {
        let filtered = filteredEntries(entries)
        guard !filtered.isEmpty else { return [] }

        switch selectedPeriod {
        case .day:
            return generateDailyInsights(filtered, hourlyRate: hourlyRate)
        case .month:
            return generateMonthlyInsights(filtered, hourlyRate: hourlyRate, allEntries: entries, includeWeekends: includeWeekends)
        case .year:
            return generateYearlyInsights(filtered, hourlyRate: hourlyRate, allEntries: entries)
        case .lifetime:
            return generateLifetimeInsights(filtered, hourlyRate: hourlyRate)
        case .week:
            return generateMultiDayInsights(filtered, hourlyRate: hourlyRate, allEntries: entries)
        }
    }

    private func generateDailyInsights(_ filtered: [TimeEntry], hourlyRate: Double) -> [Insight] {
        var insights: [Insight] = []
        let total = filtered.reduce(0.0) { $0 + $1.duration }
        let categories = categoryBreakdown(filtered)
        let isToday = calendar.isDateInToday(selectedDate)

        let count = filtered.count
        if count > 0 {
            let avgMinutes = Int(total / Double(count) / 60)
            insights.append(Insight(text: "\(count) \(count == 1 ? "session" : "sessions")\(isToday ? " today" : ""), averaging \(avgMinutes)m each."))
        }

        if let top = categories.first {
            let pct = Int(top.percentage * 100)
            insights.append(Insight(text: "\(top.emoji) \(top.name) dominated\(isToday ? " today" : "") at \(pct)% of reclaimed time."))
        }

        var hourTotals: [Int: TimeInterval] = [:]
        for entry in filtered {
            let hour = calendar.component(.hour, from: entry.startTime)
            hourTotals[hour, default: 0] += entry.duration
        }
        if let peakHour = hourTotals.max(by: { $0.value < $1.value }) {
            let formatted = String(format: "%d:00", peakHour.key)
            let quip = switch peakHour.key {
            case 0..<9: "Early bird gets the slack."
            case 9..<12: "Morning productivity is a myth."
            case 12..<14: "The lunch coma hits hard."
            case 14..<17: "The afternoon slump is real."
            default: "Overtime slacking. Dedication."
            }
            insights.append(Insight(text: "Peak slacking hour: \(formatted). \(quip)"))
        }

        if categories.contains(where: { $0.name == "Bathroom Break" }) {
            let bathroomCount = filtered.filter { $0.category == "Bathroom Break" }.count
            if bathroomCount >= 3 {
                insights.append(Insight(text: "\(bathroomCount) bathroom breaks. Hydration or avoidance?"))
            }
        }

        if let lookingBusy = categories.first(where: { $0.name == "Looking Busy" }) {
            let minutes = Int(lookingBusy.totalDuration / 60)
            if minutes > 0 {
                insights.append(Insight(text: "\(minutes)m spent looking busy. Oscar-worthy performance."))
            }
        }

        return Array(insights.prefix(3))
    }

    private func generateMultiDayInsights(_ filtered: [TimeEntry], hourlyRate: Double, allEntries: [TimeEntry]) -> [Insight] {
        var insights: [Insight] = []
        let total = filtered.reduce(0.0) { $0 + $1.duration }

        if let comparison = previousPeriodComparison(allEntries: allEntries, currentTotal: total) {
            insights.append(comparison)
        }

        var dayTotals: [Int: TimeInterval] = [:]
        for entry in filtered {
            let weekday = calendar.component(.weekday, from: entry.startTime)
            dayTotals[weekday, default: 0] += entry.duration
        }
        if dayTotals.count > 1, let laziest = dayTotals.max(by: { $0.value < $1.value }) {
            let dayName = calendar.weekdaySymbols[laziest.key - 1]
            let pct = Int((laziest.value / max(1, total)) * 100)
            insights.append(Insight(text: "\(dayName) is your laziest day. \(pct)% of all reclaimed time happens on \(dayName)s."))
        }

        let range = dateRange(for: selectedPeriod)
        let periodDays = max(1, calendar.dateComponents([.day], from: range.start, to: range.end).day ?? 1)
        let dailyRate = (total / 3600.0 * hourlyRate) / Double(periodDays)
        let annualProjection = dailyRate * 260
        if annualProjection > 100 {
            insights.append(Insight(text: "At this rate, you'll reclaim $\(Int(annualProjection).formatted()) this year."))
        }

        let categories = categoryBreakdown(allEntries)
        if let top = categories.first {
            let pct = Int(top.percentage * 100)
            insights.append(Insight(text: "\(top.emoji) \(top.name) accounts for \(pct)% of your portfolio. Diversify."))
        }

        if let bathroom = categories.first(where: { $0.name == "Bathroom Break" }) {
            let bathroomEntries = filtered.filter { $0.category == "Bathroom Break" }
            let avgMinutes = Int(bathroom.totalDuration / Double(max(1, bathroomEntries.count)) / 60)
            if avgMinutes > 0 {
                insights.append(Insight(text: "Your average bathroom break is \(avgMinutes) minutes. HR has been notified."))
            }
        }

        if let lookingBusy = categories.first(where: { $0.name == "Looking Busy" }) {
            let hours = lookingBusy.totalDuration / 3600
            if hours >= 1 {
                insights.append(Insight(text: "You've spent \(String(format: "%.1f", hours))h looking busy. Employee of the month."))
            }
        }

        return Array(insights.prefix(3))
    }

    private func previousPeriodComparison(allEntries: [TimeEntry], currentTotal: TimeInterval) -> Insight? {
        if selectedPeriod == .lifetime { return nil }

        let component: Calendar.Component = switch selectedPeriod {
        case .day: .day
        case .week: .weekOfYear
        case .month: .month
        case .year, .lifetime: .year
        }

        guard let prevDate = calendar.date(byAdding: component, value: -1, to: selectedDate) else { return nil }

        let prevTotal = entries(for: selectedPeriod, date: prevDate, from: allEntries)
            .reduce(0.0) { $0 + $1.duration }

        guard prevTotal > 0 else { return nil }

        let change = ((currentTotal - prevTotal) / prevTotal) * 100
        let periodName = switch selectedPeriod {
        case .day: "yesterday"
        case .week: "last week"
        case .month: "last month"
        case .year, .lifetime: "last year"
        }

        if abs(change) < 5 {
            return Insight(text: "About the same as \(periodName). Consistent slacker.")
        } else if change > 0 {
            return Insight(text: "You reclaimed \(Int(change))% more than \(periodName). Momentum.")
        } else {
            return Insight(text: "You reclaimed \(Int(abs(change)))% less than \(periodName). Slacking off from slacking off.")
        }
    }

    private func generateYearlyInsights(_ filtered: [TimeEntry], hourlyRate: Double, allEntries: [TimeEntry]) -> [Insight] {
        var insights: [Insight] = []
        let total = filtered.reduce(0.0) { $0 + $1.duration }

        if let comparison = previousPeriodComparison(allEntries: allEntries, currentTotal: total) {
            insights.append(comparison)
        }

        let monthlyData = yearlyMonthlyBreakdown(filtered)
        let nonEmpty = monthlyData.filter { $0.totalDuration > 0 }
        if nonEmpty.count > 1 {
            if let laziest = nonEmpty.max(by: { $0.totalDuration < $1.totalDuration }) {
                insights.append(Insight(text: "\(laziest.label) was your laziest month at \(Theme.formatDuration(laziest.totalDuration)). Peak performance."))
            }
        }

        let monthsWithData = max(1, nonEmpty.count)
        let avgPerMonth = total / Double(monthsWithData)
        if avgPerMonth > 0 {
            insights.append(Insight(text: "You averaged \(Theme.formatDuration(avgPerMonth)) per month this year."))
        }

        let categories = categoryBreakdown(allEntries)
        if let top = categories.first {
            let pct = Int(top.percentage * 100)
            insights.append(Insight(text: "\(top.emoji) \(top.name) accounts for \(pct)% of your annual portfolio. Diversify."))
        }

        let totalMoney = total / 3600.0 * hourlyRate
        if totalMoney > 0 {
            insights.append(Insight(text: "Total wages reclaimed this year: \(Theme.formatMoney(totalMoney)). Not bad."))
        }

        return Array(insights.prefix(3))
    }

    private func generateMonthlyInsights(_ filtered: [TimeEntry], hourlyRate: Double, allEntries: [TimeEntry], includeWeekends: Bool) -> [Insight] {
        var insights: [Insight] = []
        let total = filtered.reduce(0.0) { $0 + $1.duration }

        if let comparison = previousPeriodComparison(allEntries: allEntries, currentTotal: total) {
            insights.append(comparison)
        }

        let weeklyData = monthlyWeeklyBreakdown(filtered)
        let nonEmpty = weeklyData.filter { $0.totalDuration > 0 }
        if nonEmpty.count > 1 {
            if let best = nonEmpty.max(by: { $0.totalDuration < $1.totalDuration }) {
                insights.append(Insight(text: "\(best.label) was your laziest week at \(Theme.formatDuration(best.totalDuration)). Well done."))
            }
        }

        let weekCount = max(1, weeklyData.count)
        let avgPerWeek = total / Double(weekCount)
        if avgPerWeek > 0 {
            insights.append(Insight(text: "You averaged \(Theme.formatDuration(avgPerWeek)) per week this month."))
        }

        let range = dateRange(for: selectedPeriod)
        let periodDays = max(1, calendar.dateComponents([.day], from: range.start, to: range.end).day ?? 1)
        let dailyRate = (total / 3600.0 * hourlyRate) / Double(periodDays)
        let annualProjection = dailyRate * 260
        if annualProjection > 100 {
            insights.append(Insight(text: "At this rate, you'll reclaim $\(Int(annualProjection).formatted()) this year."))
        }

        let categories = categoryBreakdown(allEntries)
        if let top = categories.first {
            let pct = Int(top.percentage * 100)
            insights.append(Insight(text: "\(top.emoji) \(top.name) accounts for \(pct)% of your portfolio. Diversify."))
        }

        return Array(insights.prefix(3))
    }

    private func generateLifetimeInsights(_ filtered: [TimeEntry], hourlyRate: Double) -> [Insight] {
        var insights: [Insight] = []
        let total = filtered.reduce(0.0) { $0 + $1.duration }
        let categories = categoryBreakdown(filtered)

        // 1. Career summary
        let totalMoney = total / 3600.0 * hourlyRate
        if totalMoney > 0 {
            insights.append(Insight(text: "Career wages reclaimed: \(Theme.formatMoney(totalMoney)). A true professional."))
        }

        // 2. Total sessions + average
        let count = filtered.count
        if count > 0 {
            let avgMinutes = Int(total / Double(count) / 60)
            insights.append(Insight(text: "\(count) sessions lifetime, averaging \(avgMinutes)m each."))
        }

        // 3. All-time favorite category
        if let top = categories.first {
            let pct = Int(top.percentage * 100)
            insights.append(Insight(text: "\(top.emoji) \(top.name) is your all-time favorite at \(pct)%. Committed."))
        }

        // 4. Best month ever
        let chartData = lifetimeBreakdown(filtered)
        let nonEmpty = chartData.filter { $0.totalDuration > 0 }
        if nonEmpty.count > 1 {
            if let best = nonEmpty.max(by: { $0.totalDuration < $1.totalDuration }) {
                insights.append(Insight(text: "\(best.label) was your most productive unproductive period at \(Theme.formatDuration(best.totalDuration))."))
            }
        }

        // 5. Laziest day of the week (all-time)
        var dayTotals: [Int: TimeInterval] = [:]
        for entry in filtered {
            let weekday = calendar.component(.weekday, from: entry.startTime)
            dayTotals[weekday, default: 0] += entry.duration
        }
        if dayTotals.count > 1, let laziest = dayTotals.max(by: { $0.value < $1.value }) {
            let dayName = calendar.weekdaySymbols[laziest.key - 1]
            insights.append(Insight(text: "\(dayName) is your all-time laziest day. The data is clear."))
        }

        return Array(insights.prefix(3))
    }

    // MARK: - Helpers

    /// Pure date range computation — does NOT read selectedDate/selectedPeriod
    private func dateRange(for period: TimePeriod, referenceDate: Date) -> (start: Date, end: Date) {
        let isCurrentPeriod: Bool = switch period {
        case .day: calendar.isDateInToday(referenceDate)
        case .week: calendar.isDate(referenceDate, equalTo: .now, toGranularity: .weekOfYear)
        case .month: calendar.isDate(referenceDate, equalTo: .now, toGranularity: .month)
        case .year: calendar.isDate(referenceDate, equalTo: .now, toGranularity: .year)
        case .lifetime: true
        }

        switch period {
        case .day:
            let start = calendar.startOfDay(for: referenceDate)
            let end = calendar.date(byAdding: .day, value: 1, to: start)!
            return (start, isCurrentPeriod ? .now : end)
        case .week:
            let comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: referenceDate)
            let start = calendar.date(from: comps)!
            if isCurrentPeriod { return (start, .now) }
            return (start, calendar.date(byAdding: .weekOfYear, value: 1, to: start)!)
        case .month:
            let comps = calendar.dateComponents([.year, .month], from: referenceDate)
            let start = calendar.date(from: comps)!
            if isCurrentPeriod { return (start, .now) }
            return (start, calendar.date(byAdding: .month, value: 1, to: start)!)
        case .year:
            let comps = calendar.dateComponents([.year], from: referenceDate)
            let start = calendar.date(from: comps)!
            if isCurrentPeriod { return (start, .now) }
            return (start, calendar.date(byAdding: .year, value: 1, to: start)!)
        case .lifetime:
            return (.distantPast, .now)
        }
    }

    private func entries(for period: TimePeriod, date: Date, from allEntries: [TimeEntry]) -> [TimeEntry] {
        let range = dateRange(for: period, referenceDate: date)
        return allEntries.filter { !$0.isRunning && $0.startTime >= range.start && $0.startTime < range.end }
    }

    private func countWeekdays(from start: Date, days: Int) -> Int {
        let calendar = Calendar.current
        var count = 0
        for i in 0..<days {
            if let date = calendar.date(byAdding: .day, value: i, to: start) {
                let weekday = calendar.component(.weekday, from: date)
                if weekday != 1 && weekday != 7 { count += 1 }
            }
        }
        return max(1, count)
    }
}
