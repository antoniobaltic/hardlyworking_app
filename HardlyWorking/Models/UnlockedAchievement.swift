import Foundation
import SwiftData

@Model
final class UnlockedAchievement {
    var achievementId: String = ""
    var level: Int = 0
    var unlockedAt: Date = Date.now

    init(achievementId: String, level: Int, unlockedAt: Date = .now) {
        self.achievementId = achievementId
        self.level = level
        self.unlockedAt = unlockedAt
    }
}
