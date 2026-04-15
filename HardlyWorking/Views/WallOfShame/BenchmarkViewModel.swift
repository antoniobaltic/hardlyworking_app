import Foundation

@Observable @MainActor
final class BenchmarkViewModel {
    private(set) var globalStats: GlobalBenchmark = EmptyBenchmarkData.global
    private(set) var countries: [BenchmarkCountry] = EmptyBenchmarkData.countries
    private(set) var industries: [BenchmarkIndustry] = EmptyBenchmarkData.industries
    private(set) var userPercentile: Int?
    private(set) var isLoading = false
    private(set) var isLiveData = false
    private var lastFetchTime: Date?

    /// Load benchmarks, but skip if data was fetched recently (within 2 minutes).
    /// Use `forceRefresh: true` for pull-to-refresh.
    func loadBenchmarks(forceRefresh: Bool = false) async {
        // Skip if we fetched recently (unless forced)
        if !forceRefresh, isLiveData, let lastFetch = lastFetchTime, Date.now.timeIntervalSince(lastFetch) < 120 {
            return
        }

        isLoading = true
        defer {
            isLoading = false
            lastFetchTime = .now
        }

        async let globalTask = loadGlobalStats()
        async let countriesTask = loadCountries()
        async let industriesTask = loadIndustries()
        async let percentileTask = loadPercentile()

        _ = await (globalTask, countriesTask, industriesTask, percentileTask)
    }

    // MARK: - Global Stats

    private func loadGlobalStats() async {
        do {
            guard let response = try await SupabaseManager.shared.fetchGlobalBenchmarks() else { return }
            guard response.totalUsers > 0 else { return }

            let categoryEmoji = categoryEmojiLookup(response.mostPopularCategory)

            globalStats = GlobalBenchmark(
                totalUsers: response.totalUsers,
                totalWagesReclaimed: response.totalWagesReclaimed,
                totalHoursReclaimed: response.totalHoursReclaimed,
                globalAvgSecondsPerDay: response.globalAvgSecondsPerDay,
                mostPopularCategory: response.mostPopularCategory ?? "",
                mostPopularCategoryEmoji: categoryEmoji
            )
            isLiveData = true
        } catch {
            print("[Benchmarks] Global stats failed: \(error)")
        }
    }

    // MARK: - Country Rankings

    /// Max number of rows shown in both Country and Industry rankings.
    /// Server returns the full sorted list; we cap client-side so the list
    /// stays scannable and doesn't balloon as more countries/industries sign up.
    private static let maxRankingRows = 10

    private func loadCountries() async {
        do {
            let response = try await SupabaseManager.shared.fetchCountryBenchmarks()

            countries = response.prefix(Self.maxRankingRows).map { country in
                BenchmarkCountry(
                    name: country.name,
                    flag: flagEmoji(for: country.name),
                    avgSecondsPerDay: country.avgSecondsPerDay,
                    userCount: country.userCount
                )
            }
        } catch {
            print("[Benchmarks] Country rankings failed: \(error)")
        }
    }

    // MARK: - Industry Rankings

    private func loadIndustries() async {
        do {
            let response = try await SupabaseManager.shared.fetchIndustryBenchmarks()

            industries = response
                .compactMap { item -> BenchmarkIndustry? in
                    guard let industry = Industry(rawValue: item.industry) else { return nil }
                    return BenchmarkIndustry(
                        industry: industry,
                        avgSecondsPerDay: item.avgSecondsPerDay,
                        userCount: item.userCount
                    )
                }
                .prefix(Self.maxRankingRows)
                .map { $0 }
        } catch {
            print("[Benchmarks] Industry rankings failed: \(error)")
        }
    }

    // MARK: - User Percentile

    private func loadPercentile() async {
        do {
            guard let response = try await SupabaseManager.shared.fetchUserPercentile() else { return }
            if response.totalActiveUsers > 0 {
                userPercentile = response.percentile
            }
        } catch {
            print("[Benchmarks] User percentile failed: \(error)")
        }
    }

    // MARK: - Helpers

    private func categoryEmojiLookup(_ name: String?) -> String {
        guard let name else { return "\u{1F4F1}" }
        return SlackCategory.defaults.first { $0.name == name }?.emoji ?? "\u{1F4F1}"
    }

    private func flagEmoji(for countryName: String) -> String {
        let locales = Locale.availableIdentifiers.compactMap { Locale(identifier: $0).language.region }
        for region in locales {
            if Locale.current.localizedString(forRegionCode: region.identifier) == countryName {
                let base: UInt32 = 127397
                let flag = region.identifier.unicodeScalars.compactMap { UnicodeScalar(base + $0.value) }
                    .map { String($0) }.joined()
                if !flag.isEmpty { return flag }
            }
        }
        return "\u{1F30D}"
    }
}
