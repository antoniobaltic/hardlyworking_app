import AuthenticationServices
import Foundation
import Supabase

@Observable @MainActor
final class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private(set) var isAuthenticated = false
    private(set) var userId: UUID?

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: "https://earykashrprnkagzriyb.supabase.co")!,
            supabaseKey: "sb_publishable_zx0VYnM5xS8_-7-xW-iW3w_9QL3-r6c"
        )

        Task { await listenForAuthChanges() }
    }

    // MARK: - Auth State

    private func listenForAuthChanges() async {
        for await state in client.auth.authStateChanges {
            if [.initialSession, .signedIn, .signedOut].contains(state.event) {
                isAuthenticated = state.session != nil
                userId = state.session?.user.id
            }
        }
    }

    // MARK: - Sign in with Apple

    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws {
        guard let identityToken = credential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8)
        else {
            throw SupabaseAuthError.missingIdentityToken
        }

        try await client.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: tokenString
            )
        )
    }

    // MARK: - Sign Out

    func signOut() async throws {
        try await client.auth.signOut()
    }

    // MARK: - Delete Account

    /// Delete all user data from Supabase and sign out.
    /// Removes profile, daily stats, group memberships, and auth session.
    func deleteAccount() async throws {
        guard let userId else { return }
        let uid = userId.uuidString

        // Delete user data from all tables (order matters: memberships before groups)
        _ = try? await client.from("group_members").delete().eq("user_id", value: uid).execute()
        _ = try? await client.from("daily_stats").delete().eq("user_id", value: uid).execute()
        _ = try? await client.from("profiles").delete().eq("id", value: uid).execute()

        // Delete owned groups (cascade will remove their members)
        _ = try? await client.from("friend_groups").delete().eq("created_by", value: uid).execute()

        // Sign out to clear the session
        try await client.auth.signOut()
    }

    // MARK: - Profile

    func syncProfile(
        industry: String?,
        country: String?,
        hourlyRate: Double?,
        workHoursPerDay: Double?,
        workDaysPerWeek: Int?,
        reclaimerLevel: Int?,
        reclaimerTitle: String?
    ) async throws {
        guard let userId else { return }

        try await client
            .from("profiles")
            .update([
                "industry": industry.map { AnyJSON.string($0) } ?? .null,
                "country": country.map { AnyJSON.string($0) } ?? .null,
                "hourly_rate": hourlyRate.map { AnyJSON.double($0) } ?? .null,
                "work_hours_per_day": workHoursPerDay.map { AnyJSON.double($0) } ?? .null,
                "work_days_per_week": workDaysPerWeek.map { AnyJSON.integer(Int($0)) } ?? .null,
                "reclaimer_level": reclaimerLevel.map { AnyJSON.integer($0) } ?? .null,
                "reclaimer_title": reclaimerTitle.map { AnyJSON.string($0) } ?? .null,
                "updated_at": AnyJSON.string(ISO8601DateFormatter().string(from: .now)),
            ])
            .eq("id", value: userId.uuidString)
            .execute()
    }

    // MARK: - Daily Stats Sync

    func syncDailyStats(date: Date, totalSeconds: Int, sessionCount: Int, topCategory: String?) async throws {
        guard let userId else { return }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)

        try await client
            .from("daily_stats")
            .upsert([
                "user_id": AnyJSON.string(userId.uuidString),
                "date": AnyJSON.string(dateString),
                "total_seconds": AnyJSON.integer(totalSeconds),
                "session_count": AnyJSON.integer(sessionCount),
                "top_category": topCategory.map { AnyJSON.string($0) } ?? .null,
            ], onConflict: "user_id,date")
            .execute()
    }

    // MARK: - Benchmarks (RPC calls to SECURITY DEFINER functions)

    func fetchGlobalBenchmarks() async throws -> GlobalBenchmarkResponse? {
        try await client
            .rpc("get_global_benchmarks")
            .execute()
            .value
    }

    func fetchCountryBenchmarks() async throws -> [CountryBenchmarkResponse] {
        let result: [CountryBenchmarkResponse]? = try await client
            .rpc("get_country_benchmarks")
            .execute()
            .value
        return result ?? []
    }

    func fetchIndustryBenchmarks() async throws -> [IndustryBenchmarkResponse] {
        let result: [IndustryBenchmarkResponse]? = try await client
            .rpc("get_industry_benchmarks")
            .execute()
            .value
        return result ?? []
    }

    func fetchUserPercentile() async throws -> UserPercentileResponse? {
        try await client
            .rpc("get_user_percentile")
            .execute()
            .value
    }

    // MARK: - Friend Groups

    func createGroup(name: String, emoji: String, description: String?) async throws -> FriendGroupRecord {
        guard let userId else { throw SupabaseAuthError.missingIdentityToken }

        // Insert the group
        let group: FriendGroupRecord = try await client
            .from("friend_groups")
            .insert([
                "name": AnyJSON.string(name),
                "emoji": AnyJSON.string(emoji),
                "description": description.map { AnyJSON.string($0) } ?? .null,
                "created_by": AnyJSON.string(userId.uuidString),
            ])
            .select()
            .single()
            .execute()
            .value

        // Auto-add creator as a member
        try await client
            .from("group_members")
            .insert([
                "group_id": AnyJSON.string(group.id.uuidString),
                "user_id": AnyJSON.string(userId.uuidString),
            ])
            .execute()

        return group
    }

    func fetchUserGroups() async throws -> [FriendGroupRecord] {
        let result: [FriendGroupRecord]? = try await client
            .rpc("get_user_groups")
            .execute()
            .value
        return result ?? []
    }

    func lookupGroupByInviteCode(_ code: String) async throws -> FriendGroupRecord? {
        let results: [FriendGroupRecord] = try await client
            .from("friend_groups")
            .select("*, member_count:group_members(count)")
            .eq("invite_code", value: code)
            .execute()
            .value
        return results.first
    }

    func joinGroup(inviteCode: String) async throws {
        guard let userId else { throw SupabaseAuthError.missingIdentityToken }

        // Look up group
        guard let group = try await lookupGroupByInviteCode(inviteCode) else {
            throw GroupError.groupNotFound
        }

        // Check if already a member
        struct MemberRow: Decodable { let id: UUID }
        let existing: [MemberRow] = try await client
            .from("group_members")
            .select("id")
            .eq("group_id", value: group.id.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value

        if !existing.isEmpty {
            throw GroupError.alreadyMember
        }

        // Add as member
        try await client
            .from("group_members")
            .insert([
                "group_id": AnyJSON.string(group.id.uuidString),
                "user_id": AnyJSON.string(userId.uuidString),
            ])
            .execute()
    }

    func leaveGroup(groupId: UUID) async throws {
        guard let userId else { return }
        try await client
            .from("group_members")
            .delete()
            .eq("group_id", value: groupId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()
    }

    func deleteGroup(groupId: UUID) async throws {
        try await client
            .from("friend_groups")
            .delete()
            .eq("id", value: groupId.uuidString)
            .execute()
    }

    func removeGroupMember(groupId: UUID, memberId: UUID) async throws {
        try await client
            .from("group_members")
            .delete()
            .eq("group_id", value: groupId.uuidString)
            .eq("user_id", value: memberId.uuidString)
            .execute()
    }

    func fetchGroupLeaderboard(groupId: UUID) async throws -> [GroupLeaderboardEntry] {
        let result: [GroupLeaderboardEntry]? = try await client
            .rpc("get_group_leaderboard", params: ["group_id_param": AnyJSON.string(groupId.uuidString)])
            .execute()
            .value
        return result ?? []
    }

    func fetchGroupLeaderboardAllTime(groupId: UUID) async throws -> [GroupLeaderboardAllTimeEntry] {
        let result: [GroupLeaderboardAllTimeEntry]? = try await client
            .rpc("get_group_leaderboard_all_time", params: ["group_id_param": AnyJSON.string(groupId.uuidString)])
            .execute()
            .value
        return result ?? []
    }
}

// MARK: - Response Types

struct GlobalBenchmarkResponse: Decodable {
    let totalUsers: Int
    let globalAvgSecondsPerDay: Double
    let totalWagesReclaimed: Double
    let mostPopularCategory: String?

    enum CodingKeys: String, CodingKey {
        case totalUsers = "total_users"
        case globalAvgSecondsPerDay = "global_avg_seconds_per_day"
        case totalWagesReclaimed = "total_wages_reclaimed"
        case mostPopularCategory = "most_popular_category"
    }
}

struct CountryBenchmarkResponse: Decodable {
    let name: String
    let avgSecondsPerDay: Double
    let userCount: Int

    enum CodingKeys: String, CodingKey {
        case name
        case avgSecondsPerDay = "avg_seconds_per_day"
        case userCount = "user_count"
    }
}

struct IndustryBenchmarkResponse: Decodable {
    let industry: String
    let avgSecondsPerDay: Double
    let userCount: Int

    enum CodingKeys: String, CodingKey {
        case industry
        case avgSecondsPerDay = "avg_seconds_per_day"
        case userCount = "user_count"
    }
}

struct UserPercentileResponse: Decodable {
    let userAvgSecondsPerDay: Double
    let percentile: Int
    let totalActiveUsers: Int

    enum CodingKeys: String, CodingKey {
        case userAvgSecondsPerDay = "user_avg_seconds_per_day"
        case percentile
        case totalActiveUsers = "total_active_users"
    }
}

// MARK: - Group Types

struct FriendGroupRecord: Identifiable, Decodable {
    let id: UUID
    let name: String
    let emoji: String
    let description: String?
    let createdBy: UUID
    let inviteCode: String
    let createdAt: String
    let memberCount: Int?

    enum CodingKeys: String, CodingKey {
        case id, name, emoji, description
        case createdBy = "created_by"
        case inviteCode = "invite_code"
        case createdAt = "created_at"
        case memberCount = "member_count"
    }
}

struct GroupLeaderboardEntry: Identifiable, Decodable {
    let userId: UUID
    let industry: String?
    let reclaimerTitle: String?
    let totalSecondsThisWeek: Int
    let sessionCountThisWeek: Int

    var id: UUID { userId }

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case industry
        case reclaimerTitle = "reclaimer_title"
        case totalSecondsThisWeek = "total_seconds_this_week"
        case sessionCountThisWeek = "session_count_this_week"
    }
}

struct GroupLeaderboardAllTimeEntry: Identifiable, Decodable {
    let userId: UUID
    let industry: String?
    let reclaimerTitle: String?
    let totalSecondsAllTime: Int
    let sessionCountAllTime: Int

    var id: UUID { userId }

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case industry
        case reclaimerTitle = "reclaimer_title"
        case totalSecondsAllTime = "total_seconds_all_time"
        case sessionCountAllTime = "session_count_all_time"
    }
}

// MARK: - Errors

enum SupabaseAuthError: LocalizedError {
    case missingIdentityToken

    var errorDescription: String? {
        switch self {
        case .missingIdentityToken:
            "Identity verification incomplete. Credentials not received."
        }
    }
}

enum GroupError: LocalizedError {
    case groupNotFound
    case alreadyMember

    var errorDescription: String? {
        switch self {
        case .groupNotFound:
            "No unit found with that authorization code."
        case .alreadyMember:
            "You are already affiliated with this group."
        }
    }
}
