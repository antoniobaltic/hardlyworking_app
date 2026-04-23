import Foundation

/// Computes the "three most-recently-used" substitute codes surfaced in the
/// Dynamic Island / Lock Screen live activity. Called from the app process
/// whenever the Live Activity's content state is constructed.
///
/// Compiled into both the main app and widget extension targets — the widget
/// target only needs it so dependent types (intents, the service) compile,
/// since `LiveActivityIntent.perform()` runs in the host app's process.
enum SubstituteResolver {
    /// Walk `historicalEntries` most-recent-first, collect unique category names
    /// (excluding `activeCategory`), then pad with defaults to always return
    /// exactly three entries — stable fallback for new users with no history.
    ///
    /// - Parameters:
    ///   - activeCategory: the currently-running category. Never surfaced as a chip.
    ///   - historicalEntries: any slice of `TimeEntry` — we filter to completed
    ///     ones and sort by `endTime` descending internally.
    ///   - customCategories: to resolve emoji for user-defined categories.
    static func compute(
        excluding activeCategory: String,
        historicalEntries: [TimeEntry],
        customCategories: [CustomCategory]
    ) -> [SubstituteCode] {
        let trimmedActive = activeCategory.trimmingCharacters(in: .whitespacesAndNewlines)
        var seen: Set<String> = [trimmedActive]
        var result: [SubstituteCode] = []

        let recent = historicalEntries
            .filter { $0.endTime != nil }
            .sorted { ($0.endTime ?? .distantPast) > ($1.endTime ?? .distantPast) }

        for entry in recent {
            if seen.contains(entry.category) { continue }
            seen.insert(entry.category)
            result.append(
                SubstituteCode(
                    name: entry.category,
                    emoji: SlackCategory.emoji(for: entry.category, custom: customCategories),
                    shortLabel: shortLabel(for: entry.category)
                )
            )
            if result.count == 3 { return result }
        }

        // Thin history → pad from defaults. Preserves the "escalation" order
        // (Coffee Run first, Long Lunch last) so first-session users see the
        // most-innocent codes up front.
        for category in SlackCategory.defaults {
            if seen.contains(category.name) { continue }
            seen.insert(category.name)
            result.append(
                SubstituteCode(
                    name: category.name,
                    emoji: category.emoji,
                    shortLabel: shortLabel(for: category.name)
                )
            )
            if result.count == 3 { return result }
        }

        return result
    }

    /// Maps a category name to a width-constrained chip label. Defaults have
    /// hand-picked shortenings; custom categories fall back to their own name
    /// (truncated if longer than ~8 chars, which rarely happens).
    static func shortLabel(for name: String) -> String {
        switch name {
        case "Coffee Run": return "Coffee"
        case "Bathroom Break": return "Bathroom"
        case "Chatting": return "Chat"
        case "Doom Scrolling": return "Scroll"
        case "Online Shopping": return "Shop"
        case "Errands": return "Errands"
        case "Looking Busy": return "Busy"
        case "\"Thinking\"": return "Think"
        case "Into the Void": return "Void"
        case "Long Lunch": return "Lunch"
        default:
            if name.count <= 8 { return name }
            return String(name.prefix(7)) + "\u{2026}"
        }
    }
}
