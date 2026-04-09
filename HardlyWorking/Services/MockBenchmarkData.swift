import Foundation

enum Industry: String, CaseIterable, Identifiable, Codable {
    case officeDrone = "Office Drone"
    case techBro = "Tech Bro"
    case suitAndTie = "Suit & Tie"
    case scrubs = "Scrubs"
    case teachersLounge = "Teacher's Lounge"
    case bureaucrat = "Bureaucrat"
    case retailWarrior = "Retail Warrior"
    case blueCollar = "Blue Collar"
    case creative = "Creative"
    case callCenterSurvivor = "Call Center Survivor"
    case hospitality = "Hospitality"
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
    let totalUsersThisWeek: Int
    let totalWagesReclaimed: Double
    let globalAvgSecondsPerDay: TimeInterval
    let mostPopularCategory: String
    let mostPopularCategoryEmoji: String
}

enum MockBenchmarkData {
    static let countries: [BenchmarkCountry] = [
        BenchmarkCountry(name: "France", flag: "\u{1F1EB}\u{1F1F7}", avgSecondsPerDay: 7920, userCount: 2841),
        BenchmarkCountry(name: "Germany", flag: "\u{1F1E9}\u{1F1EA}", avgSecondsPerDay: 7560, userCount: 3102),
        BenchmarkCountry(name: "Spain", flag: "\u{1F1EA}\u{1F1F8}", avgSecondsPerDay: 7200, userCount: 1456),
        BenchmarkCountry(name: "United Kingdom", flag: "\u{1F1EC}\u{1F1E7}", avgSecondsPerDay: 6480, userCount: 2987),
        BenchmarkCountry(name: "Australia", flag: "\u{1F1E6}\u{1F1FA}", avgSecondsPerDay: 6120, userCount: 1823),
        BenchmarkCountry(name: "United States", flag: "\u{1F1FA}\u{1F1F8}", avgSecondsPerDay: 5760, userCount: 8432),
        BenchmarkCountry(name: "Canada", flag: "\u{1F1E8}\u{1F1E6}", avgSecondsPerDay: 5400, userCount: 2156),
        BenchmarkCountry(name: "Brazil", flag: "\u{1F1E7}\u{1F1F7}", avgSecondsPerDay: 5040, userCount: 1234),
        BenchmarkCountry(name: "India", flag: "\u{1F1EE}\u{1F1F3}", avgSecondsPerDay: 4320, userCount: 3567),
        BenchmarkCountry(name: "Japan", flag: "\u{1F1EF}\u{1F1F5}", avgSecondsPerDay: 3600, userCount: 1890),
    ]

    static let industries: [BenchmarkIndustry] = [
        BenchmarkIndustry(industry: .techBro, avgSecondsPerDay: 8640, userCount: 4521),
        BenchmarkIndustry(industry: .bureaucrat, avgSecondsPerDay: 7920, userCount: 2103),
        BenchmarkIndustry(industry: .officeDrone, avgSecondsPerDay: 7200, userCount: 5678),
        BenchmarkIndustry(industry: .creative, avgSecondsPerDay: 6840, userCount: 1987),
        BenchmarkIndustry(industry: .callCenterSurvivor, avgSecondsPerDay: 6480, userCount: 892),
        BenchmarkIndustry(industry: .suitAndTie, avgSecondsPerDay: 5760, userCount: 2345),
        BenchmarkIndustry(industry: .teachersLounge, avgSecondsPerDay: 5400, userCount: 1567),
        BenchmarkIndustry(industry: .scrubs, avgSecondsPerDay: 4320, userCount: 1234),
        BenchmarkIndustry(industry: .retailWarrior, avgSecondsPerDay: 3960, userCount: 987),
        BenchmarkIndustry(industry: .hospitality, avgSecondsPerDay: 3600, userCount: 756),
        BenchmarkIndustry(industry: .blueCollar, avgSecondsPerDay: 2880, userCount: 1432),
    ]

    static let global = GlobalBenchmark(
        totalUsersThisWeek: 12432,
        totalWagesReclaimed: 2_437_891,
        globalAvgSecondsPerDay: 5940,
        mostPopularCategory: "Doom Scrolling",
        mostPopularCategoryEmoji: "\u{1F4F1}"
    )
}
