import Foundation

@Observable @MainActor
final class GroupsViewModel {
    private(set) var groups: [FriendGroupRecord] = []
    private(set) var leaderboard: [GroupLeaderboardEntry] = []
    private(set) var leaderboardAllTime: [GroupLeaderboardAllTimeEntry] = []
    private(set) var isLoading = false
    private(set) var isLoadingLeaderboard = false
    private(set) var error: String?

    var groupCount: Int { groups.count }

    var formulaValue: String {
        groups.isEmpty ? "#N/A" : "\(groups.count)"
    }

    // MARK: - Load

    func loadGroups() async {
        guard SupabaseManager.shared.isAuthenticated else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            groups = try await SupabaseManager.shared.fetchUserGroups()
        } catch {
            print("[Groups] Failed to load: \(error)")
        }
    }

    func loadLeaderboard(groupId: UUID) async {
        isLoadingLeaderboard = true
        defer { isLoadingLeaderboard = false }

        do {
            async let weekly = SupabaseManager.shared.fetchGroupLeaderboard(groupId: groupId)
            async let allTime = SupabaseManager.shared.fetchGroupLeaderboardAllTime(groupId: groupId)
            leaderboard = try await weekly
            leaderboardAllTime = try await allTime
        } catch {
            print("[Groups] Leaderboard failed: \(error)")
        }
    }

    // MARK: - Create

    private var isCreating = false

    func createGroup(name: String, emoji: String, description: String?) async -> Bool {
        guard !isCreating else { return false }
        isCreating = true
        defer { isCreating = false }
        do {
            _ = try await SupabaseManager.shared.createGroup(name: name, emoji: emoji, description: description)
            await loadGroups()
            return true
        } catch {
            self.error = "Unit formation denied. Try again."
            print("[Groups] Create failed: \(error)")
            return false
        }
    }

    // MARK: - Join

    func lookupGroup(inviteCode: String) async -> FriendGroupRecord? {
        do {
            return try await SupabaseManager.shared.lookupGroupByInviteCode(inviteCode)
        } catch {
            self.error = "No matching unit on file."
            print("[Groups] Lookup failed: \(error)")
            return nil
        }
    }

    func joinGroup(inviteCode: String) async -> Bool {
        do {
            try await SupabaseManager.shared.joinGroup(inviteCode: inviteCode)
            await loadGroups()
            return true
        } catch {
            self.error = error.localizedDescription
            print("[Groups] Join failed: \(error)")
            return false
        }
    }

    // MARK: - Leave / Delete

    func leaveGroup(groupId: UUID) async {
        do {
            try await SupabaseManager.shared.leaveGroup(groupId: groupId)
            groups.removeAll { $0.id == groupId }
        } catch {
            print("[Groups] Leave failed: \(error)")
        }
    }

    func deleteGroup(groupId: UUID) async {
        do {
            try await SupabaseManager.shared.deleteGroup(groupId: groupId)
            groups.removeAll { $0.id == groupId }
        } catch {
            print("[Groups] Delete failed: \(error)")
        }
    }

    func removeMember(groupId: UUID, memberId: UUID) async {
        do {
            try await SupabaseManager.shared.removeGroupMember(groupId: groupId, memberId: memberId)
            await loadLeaderboard(groupId: groupId)
        } catch {
            print("[Groups] Remove member failed: \(error)")
        }
    }

    // MARK: - Helpers

    func currentUserRank() -> Int? {
        guard let userId = SupabaseManager.shared.userId else { return nil }
        guard let index = leaderboard.firstIndex(where: { $0.userId == userId }) else { return nil }
        return index + 1
    }

    func isCreator(of group: FriendGroupRecord) -> Bool {
        group.createdBy == SupabaseManager.shared.userId
    }
}
