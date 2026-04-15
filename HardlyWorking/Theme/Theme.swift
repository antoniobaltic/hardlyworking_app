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

    // MARK: - Clearance Level Colors

    static let clearanceGray = Color(hex: 0x9CA3AF)
    static let clearanceBronze = Color(hex: 0xB07D4F)
    static let clearanceSilver = Color(hex: 0x8E9AAB)
    static let clearanceGold = Color(hex: 0xC9952D)
    static let clearanceBlack = Color(hex: 0x1D1D1F)

    // MARK: - Chart Colors

    /// Legacy palette — use `categoryColor(for:)` instead for consistent per-category colors.
    static let chartPalette: [Color] = [
        bloodRed, deadBlue, cautionYellow, reclaimedGreen,
        textPrimary.opacity(0.3),
        bloodRed.opacity(0.5), deadBlue.opacity(0.5),
        cautionYellow.opacity(0.5), reclaimedGreen.opacity(0.5),
        textPrimary.opacity(0.15),
    ]

    // MARK: - Fixed Category Colors

    /// Fixed colors for each default category — same color every time, everywhere.
    private static let defaultCategoryColors: [String: Color] = [
        "Coffee Run":       Color(hex: 0x8B5E3C),  // coffee brown
        "Bathroom Break":   Color(hex: 0x5B9BD5),  // porcelain blue
        "Chatting":         bloodRed,               // social red
        "Doom Scrolling":   Color(hex: 0x6C5CE7),  // screen purple
        "Online Shopping":  cautionYellow,          // impulse yellow
        "Errands":          Color(hex: 0xE17055),   // errand orange
        "Looking Busy":     textPrimary.opacity(0.35), // bland gray
        "\"Thinking\"":     reclaimedGreen,         // teal green
        "Into the Void":    Color(hex: 0x2D3436),   // void dark
        "Long Lunch":       Color(hex: 0xFDAA5E),   // lunch warm orange
    ]

    /// Extra colors for custom categories — cycled deterministically by name hash.
    private static let customCategoryPalette: [Color] = [
        Color(hex: 0xD63031),  // coral red
        Color(hex: 0x0984E3),  // bright blue
        Color(hex: 0x00B894),  // mint green
        Color(hex: 0xE84393),  // hot pink
        Color(hex: 0xFDCB6E),  // warm gold
        Color(hex: 0x6C5CE7),  // purple
        Color(hex: 0x00CEC9),  // cyan
        Color(hex: 0xE17055),  // salmon
        Color(hex: 0x55A3E8),  // sky blue
        Color(hex: 0xA29BFE),  // lavender
        Color(hex: 0xFF7675),  // soft red
        Color(hex: 0x74B9FF),  // light blue
    ]

    /// Returns the chart color for a category name. Default categories get fixed colors.
    /// Custom categories get a deterministic color based on their name (always the same).
    static func categoryColor(for name: String) -> Color {
        if let fixed = defaultCategoryColors[name] {
            return fixed
        }
        // Deterministic hash — same name always gets same color
        let hash = abs(name.hashValue)
        return customCategoryPalette[hash % customCategoryPalette.count]
    }

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

    /// Money display using the user's selected currency: `$185.10`, `€185.10`, etc.
    static func formatMoney(_ amount: Double) -> String {
        let symbol = currencySymbol(for: UserDefaults.standard.string(forKey: "currency") ?? "USD")
        return "\(symbol)\(String(format: "%.2f", amount))"
    }

    static func currencySymbol(for code: String) -> String {
        switch code {
        case "EUR": return "\u{20AC}"
        case "GBP": return "\u{00A3}"
        case "CAD": return "C$"
        case "AUD": return "A$"
        case "JPY": return "\u{00A5}"
        case "CHF": return "Fr"
        case "INR": return "\u{20B9}"
        case "BRL": return "R$"
        case "KRW": return "\u{20A9}"
        case "MXN": return "Mex$"
        default: return "$"
        }
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
