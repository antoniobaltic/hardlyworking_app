import Foundation

@Observable @MainActor
final class GroupsViewModel {
    private(set) var groups: [FriendGroupRecord] = []
    private(set) var leaderboard: [GroupLeaderboardEntry] = []
    private(set) var leaderboardMonth: [GroupLeaderboardMonthEntry] = []
    private(set) var leaderboardAllTime: [GroupLeaderboardAllTimeEntry] = []
    private(set) var isLoading = false
    private(set) var isLoadingLeaderboard = false
    private(set) var error: String?

    /// Becomes `true` after the first `loadGroups` attempt completes
    /// (success OR failure). Used by the view to differentiate
    /// "still loading on first launch" from "actually empty".
    /// Without this, the empty-state UI flashes on first visit because
    /// `groups` starts empty before the network call resolves.
    private(set) var hasLoaded = false

    var groupCount: Int { groups.count }

    var formulaValue: String {
        groups.isEmpty ? "#N/A" : "\(groups.count)"
    }

    // MARK: - Load

    func loadGroups() async {
        #if DEBUG
        if ScreenshotSeeder.isActive {
            groups = ScreenshotSeeder.mockGroups
            hasLoaded = true
            return
        }
        #endif

        // If auth hasn't resolved yet, leave `hasLoaded` unset so the view
        // keeps showing the loading state. The view re-fires this task once
        // `SupabaseManager.shared.isAuthenticated` flips to true.
        guard SupabaseManager.shared.isAuthenticated else { return }

        isLoading = true
        defer {
            isLoading = false
            hasLoaded = true
        }

        do {
            groups = try await SupabaseManager.shared.fetchUserGroups()
        } catch {
            print("[Groups] Failed to load: \(error)")
        }
    }

    func loadLeaderboard(groupId: UUID) async {
        #if DEBUG
        if ScreenshotSeeder.isActive {
            leaderboard = ScreenshotSeeder.mockLeaderboard(
                currentUserId: SupabaseManager.shared.userId
            )
            return
        }
        #endif

        isLoadingLeaderboard = true
        defer { isLoadingLeaderboard = false }

        do {
            // Fetch all three leaderboard views in parallel so switching
            // between tabs is instant after the initial load.
            async let weekly = SupabaseManager.shared.fetchGroupLeaderboard(groupId: groupId)
            async let month = SupabaseManager.shared.fetchGroupLeaderboardMonth(groupId: groupId)
            async let allTime = SupabaseManager.shared.fetchGroupLeaderboardAllTime(groupId: groupId)
            leaderboard = try await weekly
            leaderboardMonth = try await month
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

        // Explicit auth check so we give a meaningful error instead of a
        // cryptic "missing identity token" thrown from the SupabaseManager.
        guard SupabaseManager.shared.isAuthenticated else {
            self.error = "Not signed in. Close the app and reopen to reconnect."
            print("[Groups] Create failed: not authenticated")
            return false
        }

        do {
            _ = try await SupabaseManager.shared.createGroup(name: name, emoji: emoji, description: description)
            await loadGroups()
            self.error = nil
            return true
        } catch {
            // Surface the underlying error so we can actually debug.
            let nsError = error as NSError
            self.error = "Unit formation denied: \(nsError.localizedDescription)"
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

    /// Update a unit's name / emoji / description. Creator-only on the server
    /// via RLS. Returns the updated record (with the previous `memberCount`
    /// preserved, since UPDATE doesn't touch membership) so callers can
    /// refresh their local view immediately instead of waiting for a full
    /// re-fetch.
    @discardableResult
    func updateGroup(groupId: UUID, name: String, emoji: String, description: String?) async -> FriendGroupRecord? {
        do {
            let updated = try await SupabaseManager.shared.updateGroup(
                groupId: groupId,
                name: name,
                emoji: emoji,
                description: description
            )

            // The server response has memberCount == nil because we request a
            // flat select. Re-attach the existing count from our local cache
            // so the Groups list doesn't briefly flash "0 participants".
            let preservedMemberCount = groups.first(where: { $0.id == groupId })?.memberCount
            let merged = FriendGroupRecord(
                id: updated.id,
                name: updated.name,
                emoji: updated.emoji,
                description: updated.description,
                createdBy: updated.createdBy,
                inviteCode: updated.inviteCode,
                createdAt: updated.createdAt,
                memberCount: preservedMemberCount ?? updated.memberCount
            )

            if let idx = groups.firstIndex(where: { $0.id == groupId }) {
                groups[idx] = merged
            }
            self.error = nil
            return merged
        } catch {
            self.error = "Couldn't update unit: \(error.localizedDescription)"
            print("[Groups] Update group failed: \(error)")
            return nil
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

    /// Update the current user's per-unit display name. Passing `nil` clears
    /// the override and falls back to the default Employee ID label. Reloads
    /// the leaderboard on success so the new label renders immediately.
    func updateMyDisplayName(groupId: UUID, name: String?) async {
        do {
            try await SupabaseManager.shared.updateMyDisplayName(groupId: groupId, name: name)
            await loadLeaderboard(groupId: groupId)
        } catch {
            self.error = "Couldn't update your display name."
            print("[Groups] Update display name failed: \(error)")
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
