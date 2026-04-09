import SwiftUI

enum Theme {
    // MARK: - Brand Colors
    // Slightly-off primaries — faded under fluorescent office lighting

    static let bloodRed = Color(hex: 0xE63946)
    static let deadBlue = Color(hex: 0x457B9D)
    static let cautionYellow = Color(hex: 0xF4A261)
    static let reclaimedGreen = Color(hex: 0x2A9D8F)
    static let textPrimary = Color(hex: 0x1D3557)
    static let cardBackground = Color(hex: 0xF1FAEE)

    // MARK: - Semantic Aliases

    static let money = reclaimedGreen
    static let timer = bloodRed
    static let accent = deadBlue

    // MARK: - Chart Colors

    static let chartPalette: [Color] = [
        bloodRed, deadBlue, cautionYellow, reclaimedGreen,
        textPrimary.opacity(0.3),
        bloodRed.opacity(0.5), deadBlue.opacity(0.5),
        cautionYellow.opacity(0.5), reclaimedGreen.opacity(0.5),
        textPrimary.opacity(0.15),
    ]

    // MARK: - Formatters

    /// Timer display: `00:12` or `1:05:30` (with seconds)
    static func formatTimer(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(max(0, interval))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// Dashboard display: `4h 32m` or `12m` (no seconds)
    static func formatDuration(_ interval: TimeInterval) -> String {
        let totalMinutes = Int(interval) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    /// Money display: `$185.10`
    static func formatMoney(_ amount: Double) -> String {
        String(format: "$%.2f", amount)
    }
}

extension Color {
    init(hex: UInt, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}
