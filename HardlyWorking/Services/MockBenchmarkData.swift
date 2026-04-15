import Foundation

enum Industry: String, CaseIterable, Identifiable, Codable {
    case officeDrone = "Office Drone"
    case techBro = "Tech Bro"
    case creative = "Creative"
    case bureaucrat = "Bureaucrat"
    case suitAndTie = "Suit & Tie"
    case legal = "Legal"
    case remoteWorker = "Remote Worker"
    case teachersLounge = "Teacher's Lounge"
    case callCenterSurvivor = "Call Center Survivor"
    case scrubs = "Scrubs"
    case retailWarrior = "Retail Warrior"
    case hospitality = "Hospitality"
    case blueCollar = "Blue Collar"
    case other = "Other"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .officeDrone: "\u{1F4BB}"
        case .techBro: "\u{1F5A5}"
        case .suitAndTie: "\u{1F3E6}"
        case .scrubs: "\u{1F3E5}"
        case .teachersLounge: "\u{1F4DA}"
        case .bureaucrat: "\u{1F3DB}"
        case .retailWarrior: "\u{1F6D2}"
        case .blueCollar: "\u{1F3D7}"
        case .creative: "\u{1F3A8}"
        case .callCenterSurvivor: "\u{1F4DE}"
        case .hospitality: "\u{1F37D}"
        case .remoteWorker: "\u{1F3E0}"
        case .legal: "\u{2696}\u{FE0F}"
        case .other: "\u{2753}"
        }
    }
}

struct BenchmarkCountry: Identifiable {
    let id = UUID()
    let name: String
    let flag: String
    let avgSecondsPerDay: TimeInterval
    let userCount: Int
}

struct BenchmarkIndustry: Identifiable {
    let id = UUID()
    let industry: Industry
    let avgSecondsPerDay: TimeInterval
    let userCount: Int
}

struct GlobalBenchmark {
    let totalUsers: Int
    let totalWagesReclaimed: Double
    let totalHoursReclaimed: Double
    let globalAvgSecondsPerDay: TimeInterval
    let mostPopularCategory: String
    let mostPopularCategoryEmoji: String
}

/// Empty defaults — all benchmark data comes from Supabase.
enum EmptyBenchmarkData {
    static let countries: [BenchmarkCountry] = []
    static let industries: [BenchmarkIndustry] = []
    static let global = GlobalBenchmark(
        totalUsers: 0,
        totalWagesReclaimed: 0,
        totalHoursReclaimed: 0,
        globalAvgSecondsPerDay: 0,
        mostPopularCategory: "",
        mostPopularCategoryEmoji: ""
    )
}
