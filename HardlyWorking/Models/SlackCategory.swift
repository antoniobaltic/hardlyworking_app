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
}
