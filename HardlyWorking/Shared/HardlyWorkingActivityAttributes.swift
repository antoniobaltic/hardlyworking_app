import ActivityKit
import Foundation

/// A single substitute-code chip surfaced in the Dynamic Island / Lock Screen Live Activity.
/// Carried in the activity payload so the widget process doesn't have to query SwiftData.
public struct SubstituteCode: Codable, Hashable, Sendable {
    public var name: String
    public var emoji: String
    /// Pre-computed short label (e.g. "Coffee" for "Coffee Run") so the widget can render
    /// a narrow chip without needing a lookup table.
    public var shortLabel: String

    public init(name: String, emoji: String, shortLabel: String) {
        self.name = name
        self.emoji = emoji
        self.shortLabel = shortLabel
    }
}

/// Live Activity payload describing an in-progress reclamation session.
/// Compiled into BOTH the main app and the widget extension targets.
struct HardlyWorkingActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var categoryName: String
        var categoryEmoji: String
        var startDate: Date
        var hourlyRate: Double
        var currencySymbol: String
        /// Up to 3 most-recently-used categories to offer as quick-switch chips,
        /// always excluding `categoryName`. Computed in the app process on
        /// start/update/reattach and delivered here so the widget can render
        /// without SwiftData access.
        var substitutes: [SubstituteCode]
    }
}
