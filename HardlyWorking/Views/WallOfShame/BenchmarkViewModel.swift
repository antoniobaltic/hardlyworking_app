import Foundation

@Observable @MainActor
final class BenchmarkViewModel {
    private(set) var globalStats: GlobalBenchmark = MockBenchmarkData.global
    private(set) var countries: [BenchmarkCountry] = MockBenchmarkData.countries
    private(set) var industries: [BenchmarkIndustry] = MockBenchmarkData.industries
    private(set) var userPercentile: Int?
    private(set) var isLoading = false
    private(set) var isLiveData = false

    func loadBenchmarks() async {
        guard SupabaseManager.shared.isAuthenticated else { return }

        isLoading = true
        defer { isLoading = false }

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

            // Only use live data if there are enough users
            guard response.totalUsers >= 5 else { return }

            let categoryEmoji = categoryEmojiLookup(response.mostPopularCategory)

            globalStats = GlobalBenchmark(
                totalUsersThisWeek: response.totalUsers,
                totalWagesReclaimed: response.totalWagesReclaimed,
                globalAvgSecondsPerDay: response.globalAvgSecondsPerDay,
                mostPopularCategory: response.mostPopularCategory ?? "Doom Scrolling",
                mostPopularCategoryEmoji: categoryEmoji
            )
            isLiveData = true
        } catch {
            print("[Benchmarks] Global stats failed, using mock: \(error)")
        }
    }

    // MARK: - Country Rankings

    private func loadCountries() async {
        do {
            let response = try await SupabaseManager.shared.fetchCountryBenchmarks()

            // Only use live data if we have enough countries
            guard response.count >= 3 else { return }

            countries = response.map { country in
                BenchmarkCountry(
                    name: country.name,
                    flag: flagEmoji(for: country.name),
                    avgSecondsPerDay: country.avgSecondsPerDay,
                    userCount: country.userCount
                )
            }
        } catch {
            print("[Benchmarks] Country rankings failed, using mock: \(error)")
        }
    }

    // MARK: - Industry Rankings

    private func loadIndustries() async {
        do {
            let response = try await SupabaseManager.shared.fetchIndustryBenchmarks()

            // Only use live data if we have enough industries
            guard response.count >= 3 else { return }

            industries = response.compactMap { item in
                guard let industry = Industry(rawValue: item.industry) else { return nil }
                return BenchmarkIndustry(
                    industry: industry,
                    avgSecondsPerDay: item.avgSecondsPerDay,
                    userCount: item.userCount
                )
            }
        } catch {
            print("[Benchmarks] Industry rankings failed, using mock: \(error)")
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
        // Try to find the country code from the name, then convert to flag emoji
        let locales = Locale.availableIdentifiers.compactMap { Locale(identifier: $0).language.region }
        for region in locales {
            if Locale.current.localizedString(forRegionCode: region.identifier) == countryName {
                let base: UInt32 = 127397
                let flag = region.identifier.unicodeScalars.compactMap { UnicodeScalar(base + $0.value) }
                    .map { String($0) }.joined()
                if !flag.isEmpty { return flag }
            }
        }
        return "\u{1F30D}" // Globe fallback
    }
}
