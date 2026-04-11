import Foundation
import SwiftData

@Model
final class TimeEntry {
    #Index<TimeEntry>([\.startTime])

    var category: String = ""
    var startTime: Date = Date.now
    var endTime: Date?
    var isManual: Bool = false

    var duration: TimeInterval {
        let end = endTime ?? .now
        return end.timeIntervalSince(startTime)
    }

    var isRunning: Bool {
        endTime == nil
    }

    init(
        category: String,
        startTime: Date = .now,
        endTime: Date? = nil,
        isManual: Bool = false
    ) {
        self.category = category
        self.startTime = startTime
        self.endTime = endTime
        self.isManual = isManual
    }
}
