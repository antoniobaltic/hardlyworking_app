import Foundation
import SwiftData

@Model
final class CustomCategory {
    var name: String = ""
    var emoji: String = ""
    var parentName: String = ""
    var createdAt: Date = Date.now

    init(name: String, emoji: String, parentName: String, createdAt: Date = .now) {
        self.name = name
        self.emoji = emoji
        self.parentName = parentName
        self.createdAt = createdAt
    }
}
