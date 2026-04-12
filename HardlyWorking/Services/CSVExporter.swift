import Foundation

enum CSVExporter {
    static func generateCSV(
        entries: [TimeEntry],
        customCategories: [CustomCategory],
        hourlyRate: Double,
        currency: String,
        workHoursPerDay: Double,
        workDaysPerWeek: Int,
        userCountry: String,
        userIndustry: String
    ) -> URL? {
        var csv = ""

        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        // Metadata
        csv += "# HARDLY WORKING CORP. — DATA EXPORT\n"
        csv += "# Generated: \(displayFormatter.string(from: .now))\n"
        csv += "# Compensation: \(String(format: "%.2f", hourlyRate)) \(currency)/hr\n"
        csv += "# Schedule: \(Int(workHoursPerDay))h/day, \(workDaysPerWeek) days/week\n"
        if !userCountry.isEmpty { csv += "# Region: \(userCountry)\n" }
        if !userIndustry.isEmpty { csv += "# Department: \(userIndustry)\n" }
        csv += "#\n"

        // Summary
        let completed = entries.filter { !$0.isRunning }
        let totalSeconds = completed.reduce(0.0) { $0 + $1.duration }
        let totalHours = totalSeconds / 3600.0
        let totalMoney = totalHours * hourlyRate

        csv += "# SUMMARY\n"
        csv += "# Total Entries: \(completed.count)\n"
        csv += "# Total Hours Reclaimed: \(String(format: "%.2f", totalHours))\n"
        csv += "# Total Wages Reclaimed: \(String(format: "%.2f", totalMoney)) \(currency)\n"
        if let earliest = completed.min(by: { $0.startTime < $1.startTime })?.startTime,
           let latest = completed.max(by: { $0.startTime < $1.startTime })?.startTime {
            csv += "# Date Range: \(displayFormatter.string(from: earliest)) to \(displayFormatter.string(from: latest))\n"
        }
        csv += "#\n"

        // Time entries
        csv += "Category,Parent Category,Start Time,End Time,Duration (seconds),Duration,Amount Reclaimed (\(currency)),Manual Entry\n"

        for entry in completed.sorted(by: { $0.startTime < $1.startTime }) {
            let parentName = SlackCategory.parentName(for: entry.category, custom: customCategories)
            let endTimeStr = entry.endTime.map { displayFormatter.string(from: $0) } ?? ""
            let amountReclaimed = entry.duration / 3600.0 * hourlyRate

            csv += "\(escapeCSV(entry.category)),"
            csv += "\(escapeCSV(parentName)),"
            csv += "\(displayFormatter.string(from: entry.startTime)),"
            csv += "\(endTimeStr),"
            csv += "\(Int(entry.duration)),"
            csv += "\(Theme.formatDuration(entry.duration)),"
            csv += "\(String(format: "%.2f", amountReclaimed)),"
            csv += "\(entry.isManual)\n"
        }

        // Custom categories
        if !customCategories.isEmpty {
            csv += "\n# CUSTOM ACTIVITY CLASSIFICATIONS\n"
            csv += "Name,Emoji,Parent Category,Created\n"
            for cat in customCategories.sorted(by: { $0.createdAt < $1.createdAt }) {
                csv += "\(escapeCSV(cat.name)),"
                csv += "\(escapeCSV(cat.emoji)),"
                csv += "\(escapeCSV(cat.parentName)),"
                csv += "\(displayFormatter.string(from: cat.createdAt))\n"
            }
        }

        // Write to temp file
        let dateFmt = DateFormatter()
        dateFmt.dateFormat = "yyyy-MM-dd"
        let fileName = "hardly-working-export-\(dateFmt.string(from: .now)).csv"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try csv.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            print("[CSVExporter] Write failed: \(error)")
            return nil
        }
    }

    private static func escapeCSV(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
}
