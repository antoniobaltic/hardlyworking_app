import Foundation

struct SlackCategory: Identifiable, Codable, Sendable {
    let id: UUID
    var name: String
    var emoji: String
    var isDefault: Bool

    init(
        id: UUID = UUID(),
        name: String,
        emoji: String,
        isDefault: Bool = true
    ) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.isDefault = isDefault
    }

    // Ordered by escalation: innocent → existential
    static let defaults: [SlackCategory] = [
        SlackCategory(name: "Coffee Run", emoji: "\u{2615}"),
        SlackCategory(name: "Bathroom Break", emoji: "\u{1F6BD}"),
        SlackCategory(name: "Chatting", emoji: "\u{1F5E3}"),
        SlackCategory(name: "Doom Scrolling", emoji: "\u{1F4F1}"),
        SlackCategory(name: "Online Shopping", emoji: "\u{1F6D2}"),
        SlackCategory(name: "Errands", emoji: "\u{1F4CB}"),
        SlackCategory(name: "Looking Busy", emoji: "\u{2328}"),
        SlackCategory(name: "\"Thinking\"", emoji: "\u{1F4AD}"),
        SlackCategory(name: "Into the Void", emoji: "\u{1F441}"),
        SlackCategory(name: "Long Lunch", emoji: "\u{1F37D}"),
    ]

    /// Combines default categories with user-created custom categories.
    static func allCategories(custom: [CustomCategory]) -> [SlackCategory] {
        let customs = custom.map {
            SlackCategory(id: $0.persistentModelID.hashValue == 0 ? UUID() : UUID(), name: $0.name, emoji: $0.emoji, isDefault: false)
        }
        return defaults + customs
    }

    /// Looks up the emoji for a category name, checking defaults first then custom.
    static func emoji(for categoryName: String, custom: [CustomCategory] = []) -> String {
        if let match = defaults.first(where: { $0.name == categoryName }) {
            return match.emoji
        }
        if let match = custom.first(where: { $0.name == categoryName }) {
            return match.emoji
        }
        return "\u{2753}" // ❓ fallback
    }

    /// Maps a category name to its parent (for custom categories).
    /// Returns the name unchanged if it's a default category.
    static func parentName(for categoryName: String, custom: [CustomCategory]) -> String {
        if defaults.contains(where: { $0.name == categoryName }) {
            return categoryName
        }
        return custom.first(where: { $0.name == categoryName })?.parentName ?? categoryName
    }
}
