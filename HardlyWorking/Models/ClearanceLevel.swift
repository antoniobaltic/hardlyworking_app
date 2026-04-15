import SwiftUI

enum ClearanceLevel: Int, CaseIterable, Comparable, Sendable {
    case underObservation = 1
    case onProbation = 2
    case standardIssue = 3
    case classified = 4
    case redacted = 5

    static func < (lhs: ClearanceLevel, rhs: ClearanceLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    // MARK: - Factory

    static func from(estimatedProductivity: Int) -> ClearanceLevel {
        switch estimatedProductivity {
        case 0...20: .underObservation
        case 21...40: .onProbation
        case 41...60: .standardIssue
        case 61...80: .classified
        default: .redacted
        }
    }

    static func from(title: String?) -> ClearanceLevel? {
        guard let title else { return nil }
        return ClearanceLevel.allCases.first { $0.title == title }
    }

    static func from(level: Int) -> ClearanceLevel {
        ClearanceLevel(rawValue: level) ?? .standardIssue
    }

    // MARK: - Display

    var title: String {
        switch self {
        case .underObservation: "Under Observation"
        case .onProbation: "On Probation"
        case .standardIssue: "Standard Issue"
        case .classified: "Classified"
        case .redacted: "Redacted"
        }
    }

    var description: String {
        switch self {
        case .underObservation: "Almost no non-productive activity\ndetected. Are you okay?"
        case .onProbation: "Some non-productive activity\ndetected. We see promise."
        case .standardIssue: "You have been filed with\nthe others. Blend in."
        case .classified: "Sustained, deliberate\nunderperformance. This takes discipline."
        case .redacted: "You have transcended\nthe employment contract."
        }
    }

    // MARK: - Colors

    var color: Color {
        switch self {
        case .underObservation: Color(hex: 0xE8E8E8)
        case .onProbation: Theme.clearanceBronze
        case .standardIssue: Theme.clearanceSilver
        case .classified: Theme.clearanceGold
        case .redacted: Theme.clearanceBlack
        }
    }

    var textColor: Color {
        switch self {
        case .underObservation: Theme.textPrimary.opacity(0.5)
        case .redacted: Theme.clearanceGold
        default: .white
        }
    }

    var secondaryTextColor: Color {
        switch self {
        case .underObservation: Theme.textPrimary.opacity(0.3)
        case .redacted: Theme.clearanceGold.opacity(0.6)
        default: .white.opacity(0.6)
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .underObservation: [Color(hex: 0xF5F5F5), Color(hex: 0xE8E8E8), Color(hex: 0xDDDDDD)]
        case .onProbation: [Color(hex: 0xD4956A), Theme.clearanceBronze, Color(hex: 0x8B5E3C)]
        case .standardIssue: [Color(hex: 0xBCC3CF), Theme.clearanceSilver, Color(hex: 0x6B7A8D)]
        case .classified: [Color(hex: 0xE8C060), Theme.clearanceGold, Color(hex: 0x9A7020)]
        case .redacted: [Color(hex: 0x3A3A3C), Theme.clearanceBlack, Color(hex: 0x000000)]
        }
    }

    var sheenColor: Color {
        switch self {
        case .underObservation: .white.opacity(0.4)
        case .redacted: Theme.clearanceGold.opacity(0.08)
        default: .white.opacity(0.15)
        }
    }

    var borderColor: Color {
        switch self {
        case .underObservation: Theme.textPrimary.opacity(0.08)
        case .redacted: Theme.clearanceGold.opacity(0.15)
        default: .white.opacity(0.1)
        }
    }
}
