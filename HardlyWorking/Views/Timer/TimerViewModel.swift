import Foundation
import SwiftData
import SwiftUI

@Observable @MainActor
final class TimerViewModel {
    var modelContext: ModelContext?

    func startSlacking(category: SlackCategory, entries: [TimeEntry]) {
        guard let modelContext else { return }

        // Stop any running entry first
        if let running = entries.first(where: \.isRunning) {
            running.endTime = .now
        }

        let entry = TimeEntry(category: category.name)
        modelContext.insert(entry)
        try? modelContext.save()
    }

    func stopSlacking(entries: [TimeEntry]) {
        guard let running = entries.first(where: \.isRunning) else { return }
        running.endTime = .now
        try? modelContext?.save()
    }

    func todayTotal(entries: [TimeEntry]) -> TimeInterval {
        entries.reduce(0) { $0 + $1.duration }
    }

    func todayMoney(entries: [TimeEntry], hourlyRate: Double) -> Double {
        todayTotal(entries: entries) / 3600.0 * hourlyRate
    }
}
