import Foundation

/// Centralized recording constraints to maintain data quality.
enum RecordingLimits {
    /// Soft cap: show "Still slacking?" prompt after this duration.
    static let softCapSeconds: TimeInterval = 2 * 3600 // 2 hours

    /// Hard cap: auto-stop timer after this duration.
    static let hardCapSeconds: TimeInterval = 4 * 3600 // 4 hours

    /// Maximum lookback for retroactive entries (days).
    static let retroactiveLookbackDays: Int = 7

    /// Returns the daily cap in seconds based on user's configured work hours.
    /// Falls back to 8 hours if workHoursPerDay is 0 or negative.
    static func dailyCapSeconds(workHoursPerDay: Double) -> TimeInterval {
        let hours = workHoursPerDay > 0 ? workHoursPerDay : 8.0
        return hours * 3600
    }

    // MARK: - Session Validation

    static func hasExceededHardCap(_ entry: TimeEntry) -> Bool {
        entry.isRunning && entry.duration >= hardCapSeconds
    }

    static func hasExceededSoftCap(_ entry: TimeEntry) -> Bool {
        entry.isRunning && entry.duration >= softCapSeconds
    }

    static func isDailyCapReached(todayEntries: [TimeEntry], workHoursPerDay: Double) -> Bool {
        let total = todayEntries.reduce(0.0) { $0 + $1.duration }
        return total >= dailyCapSeconds(workHoursPerDay: workHoursPerDay)
    }

    static func remainingToday(todayEntries: [TimeEntry], workHoursPerDay: Double) -> TimeInterval {
        let total = todayEntries.reduce(0.0) { $0 + $1.duration }
        return max(0, dailyCapSeconds(workHoursPerDay: workHoursPerDay) - total)
    }

    // MARK: - Retroactive Entry Validation

    enum ValidationError: LocalizedError {
        case durationExceedsHardCap
        case dailyCapExceeded
        case overlapsExisting
        case tooFarInPast
        case inFuture
        case endBeforeStart

        var errorDescription: String? {
            switch self {
            case .durationExceedsHardCap:
                "Maximum session duration is 4 hours. File multiple entries for longer periods."
            case .dailyCapExceeded:
                "Daily reclamation allocation exceeded. You've already reclaimed your full workday."
            case .overlapsExisting:
                "This entry overlaps with an existing session. Concurrent reclamation is not permitted."
            case .tooFarInPast:
                "Retroactive entries are limited to the past 7 days. Older records cannot be amended."
            case .inFuture:
                "Future entries are not authorized. Time reclamation must be documented after the fact."
            case .endBeforeStart:
                "End time must be after start time. Please review your timestamps."
            }
        }
    }

    static func validate(
        start: Date,
        end: Date,
        existingEntries: [TimeEntry],
        excludingEntryID: TimeEntry? = nil,
        workHoursPerDay: Double
    ) -> ValidationError? {
        guard end > start else { return .endBeforeStart }
        guard start <= .now && end <= .now else { return .inFuture }

        let duration = end.timeIntervalSince(start)
        guard duration <= hardCapSeconds else { return .durationExceedsHardCap }

        let lookbackDate = Calendar.current.date(byAdding: .day, value: -retroactiveLookbackDays, to: .now) ?? .now
        guard start >= lookbackDate else { return .tooFarInPast }

        let otherEntries = existingEntries.filter { entry in
            if let excluding = excludingEntryID, entry.persistentModelID == excluding.persistentModelID {
                return false
            }
            return !entry.isRunning && entry.endTime != nil
        }

        for existing in otherEntries {
            guard let existingEnd = existing.endTime else { continue }
            if start < existingEnd && end > existing.startTime {
                return .overlapsExisting
            }
        }

        let entryDay = Calendar.current.startOfDay(for: start)
        let sameDayEntries = otherEntries.filter {
            Calendar.current.startOfDay(for: $0.startTime) == entryDay
        }
        let existingDayTotal = sameDayEntries.reduce(0.0) { $0 + $1.duration }
        let dailyCap = dailyCapSeconds(workHoursPerDay: workHoursPerDay)
        guard existingDayTotal + duration <= dailyCap else { return .dailyCapExceeded }

        return nil
    }

    // MARK: - Overnight Detection

    static func isLikelyOvernight(_ entry: TimeEntry) -> Bool {
        guard entry.isRunning else { return false }
        let startDay = Calendar.current.startOfDay(for: entry.startTime)
        let today = Calendar.current.startOfDay(for: .now)
        return startDay < today || entry.duration >= hardCapSeconds
    }
}
