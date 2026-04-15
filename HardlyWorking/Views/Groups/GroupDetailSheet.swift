import CoreImage.CIFilterBuiltins
import SwiftUI

struct GroupDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    /// Mutable local copy so edits via the Edit Unit sheet reflect immediately
    /// without waiting for the parent to re-push a refreshed record.
    @State private var group: FriendGroupRecord
    var viewModel: GroupsViewModel

    @State private var showLeaveConfirmation = false
    @State private var showDeleteConfirmation = false
    @State private var showInviteSheet = false
    @State private var showEditSheet = false
    @State private var leaderboardPeriod: LeaderboardPeriod = .weekly
    @State private var showDisplayNameEditor = false
    @State private var displayNameDraft = ""
    @State private var currentDisplayName: String? = nil
    /// Flips to `true` after the first leaderboard fetch completes. Drives a
    /// one-time staggered fade-in for leaderboard rows so the list feels
    /// alive on first render without re-animating every tab switch.
    @State private var leaderboardAppeared = false

    init(group: FriendGroupRecord, viewModel: GroupsViewModel) {
        self._group = State(initialValue: group)
        self.viewModel = viewModel
    }

    enum LeaderboardPeriod: String, CaseIterable {
        case weekly = "Week"
        case month = "Month"
        case allTime = "All Time"
    }

    private var isCreator: Bool {
        viewModel.isCreator(of: group)
    }

    private var inviteMessage: String {
        """
        Join "\(group.name)" on Hardly Working Corp.!

        Download the app, then use invite code \(group.inviteCode) to join!

        https://apps.apple.com/app/id6761917321
        """
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    groupHeader

                    VStack(spacing: 24) {
                        unitStatsDashboard
                            .padding(.horizontal, 24)

                        Divider().padding(.horizontal, 24)

                        leaderboardSection
                            .padding(.horizontal, 24)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 60)
                }
            }
            .background(Color.white)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        Haptics.light()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 30, height: 30)
                            .background(Theme.bloodRed, in: Circle())
                    }
                    .buttonStyle(.plain)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    inviteToolbarButton
                }
                ToolbarItem(placement: .topBarTrailing) {
                    adminMenu
                }
            }
            // Extend the green header surface up into the toolbar so the
            // whole "personnel file" chrome reads as one continuous strip.
            .toolbarBackground(Theme.cardBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .task {
                await viewModel.loadLeaderboard(groupId: group.id)
                // One-shot trigger for row fade-in. Uses an animation wrapper
                // so SwiftUI actually interpolates the bound opacity changes.
                withAnimation(.easeOut(duration: 0.25)) {
                    leaderboardAppeared = true
                }
            }
            .sheet(isPresented: $showInviteSheet) {
                inviteBottomSheet
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showEditSheet) {
                EditUnitSheet(group: group) { name, emoji, description in
                    // Returns true on success so the sheet can dismiss itself
                    // and false on failure so it can reset its spinner and
                    // surface the error.
                    guard let updated = await viewModel.updateGroup(
                        groupId: group.id,
                        name: name,
                        emoji: emoji,
                        description: description
                    ) else { return false }

                    // Reflect the edit locally so the header re-renders the
                    // moment the sheet dismisses.
                    group = updated
                    return true
                }
            }
            .confirmationDialog(
                "Leave this reclamation unit?",
                isPresented: $showLeaveConfirmation,
                titleVisibility: .visible
            ) {
                Button("Leave Unit", role: .destructive) {
                    Task {
                        await viewModel.leaveGroup(groupId: group.id)
                        Haptics.warning()
                        dismiss()
                    }
                }
            } message: {
                Text("You may re-enroll later with an authorization code.")
            }
            .confirmationDialog(
                "Dissolve this reclamation unit?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Dissolve Unit", role: .destructive) {
                    Task {
                        await viewModel.deleteGroup(groupId: group.id)
                        Haptics.warning()
                        dismiss()
                    }
                }
            } message: {
                Text("This will permanently dissolve the reclamation unit and remove all members. This action cannot be undone.")
            }
            .alert("Set Display Name", isPresented: $showDisplayNameEditor) {
                TextField("Display Name", text: $displayNameDraft)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()

                Button("Save") {
                    let trimmed = displayNameDraft.trimmingCharacters(in: .whitespaces)
                    let clamped = String(trimmed.prefix(24))
                    let newValue: String? = clamped.isEmpty ? nil : clamped
                    Task {
                        await viewModel.updateMyDisplayName(groupId: group.id, name: newValue)
                        Haptics.success()
                    }
                }

                if currentDisplayName != nil {
                    Button("Use Employee ID", role: .destructive) {
                        Task {
                            await viewModel.updateMyDisplayName(groupId: group.id, name: nil)
                            Haptics.warning()
                        }
                    }
                }

                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Shown to other members in this unit. 24 characters max. Clear it to use your Employee ID instead.")
            }
        }
    }

    // MARK: - Header

    private var groupHeader: some View {
        VStack(spacing: 8) {
            Text(group.emoji)
                .font(.system(size: 48))
            Text(group.name)
                .font(.system(size: 24, weight: .light, design: .monospaced))
                .foregroundStyle(Theme.textPrimary)
            if let desc = group.description, !desc.isEmpty {
                Text(desc)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.5))
                    .multilineTextAlignment(.center)
            }
            Text("\(group.memberCount ?? 0) \((group.memberCount ?? 0) == 1 ? "participant" : "participants")")
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Theme.cardBackground)
        .overlay(
            Rectangle().fill(Theme.textPrimary.opacity(0.08)).frame(height: 1),
            alignment: .bottom
        )
    }

    // MARK: - Leaderboard

    private var leaderboardSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("LEADERBOARD")
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.5))
                .tracking(1.5)

            leaderboardPeriodPicker

            if viewModel.isLoadingLeaderboard {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
            } else {
                switch leaderboardPeriod {
                case .weekly:   weeklyLeaderboardContent
                case .month:    monthLeaderboardContent
                case .allTime:  allTimeLeaderboardContent
                }
            }
        }
    }

    /// Custom three-tab period selector in the app's brand style (monospaced
    /// labels, accent underline on selection, Theme.cardBackground base).
    /// Matches the period selector on the Reports / Career tab for consistency.
    private var leaderboardPeriodPicker: some View {
        HStack(spacing: 0) {
            ForEach(LeaderboardPeriod.allCases, id: \.self) { period in
                let isSelected = leaderboardPeriod == period
                Button {
                    Haptics.selection()
                    withAnimation(.easeInOut(duration: 0.15)) {
                        leaderboardPeriod = period
                    }
                } label: {
                    Text(period.rawValue)
                        .font(.system(size: 12, weight: isSelected ? .semibold : .regular, design: .monospaced))
                        .foregroundStyle(isSelected ? Theme.textPrimary : Theme.textPrimary.opacity(0.5))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(isSelected ? Color.white : Theme.cardBackground)
                        .overlay(
                            Rectangle()
                                .fill(isSelected ? Theme.accent : Color.clear)
                                .frame(height: 2),
                            alignment: .bottom
                        )
                }
            }
        }
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Theme.textPrimary.opacity(0.08))
        )
    }

    /// Normalized entry used by the shared leaderboard renderer. Flattens
    /// the three period-specific response types into a single shape so the
    /// podium + row code doesn't have to branch per period.
    private struct NormalizedEntry {
        let userId: UUID
        let employeeId: Int?
        let displayName: String?
        let title: String?
        let totalSeconds: Int
    }

    private var weeklyLeaderboardContent: some View {
        leaderboardContent(
            entries: viewModel.leaderboard.map {
                NormalizedEntry(
                    userId: $0.userId,
                    employeeId: $0.employeeId,
                    displayName: $0.displayName,
                    title: $0.reclaimerTitle,
                    totalSeconds: $0.totalSecondsThisWeek
                )
            },
            emptyMessage: "No reclamations filed this week."
        )
    }

    private var monthLeaderboardContent: some View {
        leaderboardContent(
            entries: viewModel.leaderboardMonth.map {
                NormalizedEntry(
                    userId: $0.userId,
                    employeeId: $0.employeeId,
                    displayName: $0.displayName,
                    title: $0.reclaimerTitle,
                    totalSeconds: $0.totalSecondsThisMonth
                )
            },
            emptyMessage: "No reclamations filed this month."
        )
    }

    private var allTimeLeaderboardContent: some View {
        leaderboardContent(
            entries: viewModel.leaderboardAllTime.map {
                NormalizedEntry(
                    userId: $0.userId,
                    employeeId: $0.employeeId,
                    displayName: $0.displayName,
                    title: $0.reclaimerTitle,
                    totalSeconds: $0.totalSecondsAllTime
                )
            },
            emptyMessage: "No reclamations on record."
        )
    }

    /// Shared renderer: empty state → podium (when ≥3) → row list (rows 4+
    /// when podium is present, else all rows). Rows animate in with a
    /// one-time staggered fade driven by `leaderboardAppeared`.
    @ViewBuilder
    private func leaderboardContent(entries: [NormalizedEntry], emptyMessage: String) -> some View {
        if entries.isEmpty {
            leaderboardEmptyState(message: emptyMessage)
        } else if entries.count >= 3 {
            VStack(spacing: 16) {
                podiumView(entries: entries)

                VStack(spacing: 0) {
                    ForEach(Array(entries.dropFirst(3).enumerated()), id: \.element.userId) { offset, entry in
                        leaderboardRow(
                            userId: entry.userId,
                            employeeId: entry.employeeId,
                            displayName: entry.displayName,
                            title: entry.title,
                            totalSeconds: entry.totalSeconds,
                            rank: offset + 4,
                            index: offset
                        )
                        .opacity(leaderboardAppeared ? 1 : 0)
                        .offset(y: leaderboardAppeared ? 0 : 6)
                        .animation(
                            .easeOut(duration: 0.3).delay(0.12 + Double(offset) * 0.04),
                            value: leaderboardAppeared
                        )
                    }
                }
            }
        } else {
            VStack(spacing: 0) {
                ForEach(Array(entries.enumerated()), id: \.element.userId) { index, entry in
                    leaderboardRow(
                        userId: entry.userId,
                        employeeId: entry.employeeId,
                        displayName: entry.displayName,
                        title: entry.title,
                        totalSeconds: entry.totalSeconds,
                        rank: index + 1,
                        index: index
                    )
                    .opacity(leaderboardAppeared ? 1 : 0)
                    .offset(y: leaderboardAppeared ? 0 : 6)
                    .animation(
                        .easeOut(duration: 0.3).delay(Double(index) * 0.05),
                        value: leaderboardAppeared
                    )
                }
            }
        }
    }

    // MARK: - Podium

    /// Three-tile podium for the top 3 entries. Center tile is #1 and sits
    /// slightly taller — a visual scoreboard beat before the numeric list.
    /// Tints: caution-yellow (gold) for #1, muted grey for #2, bronzed
    /// caution-yellow for #3.
    private func podiumView(entries: [NormalizedEntry]) -> some View {
        // Visual order: #2, #1, #3 (silver left, gold center-tall, bronze right)
        let ordered: [(NormalizedEntry, Int)] = [
            (entries[1], 2),
            (entries[0], 1),
            (entries[2], 3),
        ]

        return HStack(alignment: .bottom, spacing: 10) {
            ForEach(Array(ordered.enumerated()), id: \.offset) { idx, pair in
                let (entry, rank) = pair
                podiumTile(entry: entry, rank: rank)
                    .opacity(leaderboardAppeared ? 1 : 0)
                    .offset(y: leaderboardAppeared ? 0 : 10)
                    .animation(
                        .easeOut(duration: 0.35).delay(Double(idx) * 0.06),
                        value: leaderboardAppeared
                    )
            }
        }
    }

    private func podiumTile(entry: NormalizedEntry, rank: Int) -> some View {
        let isUser = entry.userId == SupabaseManager.shared.userId
        let employeeIdLabel = entry.employeeId.map { String(format: "#HW-%05d", $0) } ?? "#HW-—————"
        let nameLabel: String = {
            if let trimmed = entry.displayName?.trimmingCharacters(in: .whitespaces), !trimmed.isEmpty {
                return trimmed.uppercased()
            }
            return employeeIdLabel
        }()
        let medal: String = ["🥇", "🥈", "🥉"][rank - 1]
        let tintColor: Color = {
            switch rank {
            case 1: Theme.cautionYellow.opacity(0.18)
            case 2: Theme.textPrimary.opacity(0.08)
            default: Theme.cautionYellow.opacity(0.09)
            }
        }()
        let borderColor: Color = {
            switch rank {
            case 1: Theme.cautionYellow.opacity(0.45)
            case 2: Theme.textPrimary.opacity(0.18)
            default: Theme.cautionYellow.opacity(0.22)
            }
        }()
        // #1 tile sits slightly taller to create the podium silhouette.
        let verticalPadding: CGFloat = rank == 1 ? 16 : 12

        return VStack(spacing: 6) {
            Text(medal)
                .font(.system(size: rank == 1 ? 28 : 22))

            Text(nameLabel)
                .font(.system(size: rank == 1 ? 11 : 10, weight: isUser ? .semibold : .medium, design: .monospaced))
                .foregroundStyle(isUser ? Theme.accent : Theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(Theme.formatDuration(Double(entry.totalSeconds)))
                .font(.system(size: rank == 1 ? 12 : 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(0.75))

            if isUser {
                Text("YOU")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1.5)
                    .background(Theme.accent, in: Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, verticalPadding)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(tintColor)
                .stroke(borderColor, lineWidth: 1)
        )
    }

    private func leaderboardEmptyState(message: String) -> some View {
        VStack(spacing: 4) {
            Text("#N/A")
                .font(.system(.title3, design: .monospaced, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.25))
            Text(message)
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    private func leaderboardRow(userId: UUID, employeeId: Int?, displayName: String?, title: String?, totalSeconds: Int, rank: Int, index: Int) -> some View {
        let isUser = userId == SupabaseManager.shared.userId
        let employeeIdLabel = employeeId.map { String(format: "#HW-%05d", $0) } ?? "#HW-—————"
        // Custom per-unit display name takes precedence when set; uppercased
        // per the brand (labels/metadata always shout). Falls back to the
        // permanent Employee ID when the member hasn't chosen a name.
        let nameLabel: String = {
            if let trimmed = displayName?.trimmingCharacters(in: .whitespaces), !trimmed.isEmpty {
                return trimmed.uppercased()
            }
            return employeeIdLabel
        }()

        return HStack(spacing: 10) {
            Text("#\(rank)")
                .font(.system(.caption, design: .monospaced, weight: .bold))
                .foregroundStyle(rankColor(rank))
                .frame(width: 24, alignment: .trailing)

            // Member label: custom display name if set, else Employee ID.
            // Accent blue + semibold for the current user, neutral navy for
            // everyone else. The current user also gets a pencil tap-target
            // to set/clear their per-unit override.
            HStack(spacing: 6) {
                Text(nameLabel)
                    .font(.system(.subheadline, design: .monospaced, weight: isUser ? .semibold : .medium))
                    .foregroundStyle(isUser ? Theme.accent : Theme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                if isUser {
                    Button {
                        Haptics.light()
                        // Seed the editor with the current override (empty
                        // string if unset) so the textfield starts where the
                        // user left off.
                        currentDisplayName = displayName
                        displayNameDraft = displayName ?? ""
                        showDisplayNameEditor = true
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Theme.accent.opacity(0.7))
                            .frame(width: 20, height: 20)
                            .background(Theme.accent.opacity(0.12), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Edit display name")
                }
            }

            Spacer()

            Text(Theme.formatDuration(Double(totalSeconds)))
                .font(.system(.caption, design: .monospaced, weight: .medium))
                .foregroundStyle(Theme.textPrimary.opacity(0.65))

            if isUser {
                Text("YOU")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Theme.accent, in: Capsule())
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 10)
        .background(
            isUser
                ? Theme.accent.opacity(0.06)
                : (index.isMultiple(of: 2) ? Theme.cardBackground.opacity(0.4) : Color.clear)
        )
    }

    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 1: Theme.cautionYellow
        case 2: Theme.textPrimary.opacity(0.4)
        case 3: Theme.cautionYellow.opacity(0.6)
        default: Theme.textPrimary.opacity(0.4)
        }
    }

    // MARK: - Unit Stats Dashboard

    /// Two small stat cards surfacing the most interesting aggregate for the
    /// unit right now: how much the whole unit reclaimed in the selected
    /// period, and where the current user sits in that ranking. Uses
    /// already-loaded leaderboard data — no extra network calls. Cards
    /// respect the currently-selected leaderboard period so switching tabs
    /// refreshes the stats instantly.
    private var unitStatsDashboard: some View {
        HStack(spacing: 12) {
            statCard(
                icon: "\u{23F1}\u{FE0F}", // ⏱️
                value: Theme.formatDuration(unitPeriodTotal),
                label: unitTotalLabel,
                valueColor: Theme.textPrimary
            )

            statCard(
                icon: "\u{1F3C5}", // 🏅
                value: yourRankDisplay,
                label: "Your Rank",
                valueColor: yourRankDisplay == "—" ? Theme.textPrimary.opacity(0.4) : Theme.accent
            )
        }
    }

    private var unitPeriodTotal: TimeInterval {
        switch leaderboardPeriod {
        case .weekly:
            return Double(viewModel.leaderboard.reduce(0) { $0 + $1.totalSecondsThisWeek })
        case .month:
            return Double(viewModel.leaderboardMonth.reduce(0) { $0 + $1.totalSecondsThisMonth })
        case .allTime:
            return Double(viewModel.leaderboardAllTime.reduce(0) { $0 + $1.totalSecondsAllTime })
        }
    }

    private var unitTotalLabel: String {
        switch leaderboardPeriod {
        case .weekly:  "Unit This Week"
        case .month:   "Unit This Month"
        case .allTime: "Unit All Time"
        }
    }

    /// "#N of M" when the current user is on the leaderboard for the selected
    /// period; "—" otherwise. Falls back gracefully during the brief window
    /// before the leaderboard has finished loading so the card doesn't flash
    /// a misleading rank.
    private var yourRankDisplay: String {
        guard let userId = SupabaseManager.shared.userId else { return "—" }

        let (rank, total): (Int?, Int) = {
            switch leaderboardPeriod {
            case .weekly:
                let idx = viewModel.leaderboard.firstIndex(where: { $0.userId == userId })
                return (idx.map { $0 + 1 }, viewModel.leaderboard.count)
            case .month:
                let idx = viewModel.leaderboardMonth.firstIndex(where: { $0.userId == userId })
                return (idx.map { $0 + 1 }, viewModel.leaderboardMonth.count)
            case .allTime:
                let idx = viewModel.leaderboardAllTime.firstIndex(where: { $0.userId == userId })
                return (idx.map { $0 + 1 }, viewModel.leaderboardAllTime.count)
            }
        }()

        guard total > 0, let rank else { return "—" }
        return "#\(rank) of \(total)"
    }

    private func statCard(icon: String, value: String, label: String, valueColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(.system(.title3, design: .monospaced, weight: .semibold))
                .foregroundStyle(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            HStack(spacing: 5) {
                Text(icon).font(.system(size: 10))
                Text(label)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Theme.cardBackground.opacity(0.6))
                .stroke(Theme.textPrimary.opacity(0.06), lineWidth: 1)
        )
    }

    // MARK: - Toolbar

    /// Small circle button in the top-right that opens the invite bottom sheet.
    /// Shares the same subtle container chrome as the adjacent `•••` menu
    /// so the two toolbar affordances read as a unified pair. The "+" glyph
    /// reads as "add members" which is more direct than a share icon.
    private var inviteToolbarButton: some View {
        Button {
            Haptics.light()
            showInviteSheet = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.7))
                .frame(width: 30, height: 30)
                // White pill on the green toolbar so the button stays legible.
                .background(Color.white, in: Circle())
                .overlay(Circle().stroke(Theme.textPrimary.opacity(0.12), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Invite Members")
    }

    /// Overflow menu holding the destructive actions (Leave / Dissolve) so
    /// they don't live on the primary surface as loud always-visible buttons.
    private var adminMenu: some View {
        Menu {
            if isCreator {
                Button {
                    Haptics.light()
                    showEditSheet = true
                } label: {
                    Label("Edit Unit", systemImage: "pencil")
                }
            }

            Button(role: .destructive) {
                Haptics.light()
                showLeaveConfirmation = true
            } label: {
                Label("Leave Unit", systemImage: "rectangle.portrait.and.arrow.right")
            }

            if isCreator {
                Button(role: .destructive) {
                    Haptics.light()
                    showDeleteConfirmation = true
                } label: {
                    Label("Dissolve Unit", systemImage: "trash")
                }
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.7))
                .frame(width: 30, height: 30)
                // White pill on the green toolbar so the button stays legible.
                .background(Color.white, in: Circle())
                .overlay(Circle().stroke(Theme.textPrimary.opacity(0.12), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Unit Options")
    }

    // MARK: - Invite Bottom Sheet

    /// Medium-detent sheet presenting the QR + code + share. Keeps the
    /// primary surface focused on the leaderboard while leaving invite one tap away.
    private var inviteBottomSheet: some View {
        VStack(spacing: 18) {
            VStack(spacing: 6) {
                Text("INVITE")
                    .font(.system(.caption2, design: .monospaced, weight: .bold))
                    .foregroundStyle(Theme.textPrimary.opacity(0.5))
                    .tracking(1.5)

                Text("Grow the unit. Hold each other unaccountable.")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.5))
                    .multilineTextAlignment(.center)
            }

            if let qrImage = generateQRCode(from: "hardlyworking://join/\(group.inviteCode)") {
                Image(uiImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180, height: 180)
            } else {
                Text("####")
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.25))
                    .frame(width: 180, height: 180)
            }

            Text(group.inviteCode)
                .font(.system(.caption, design: .monospaced, weight: .medium))
                .foregroundStyle(Theme.textPrimary.opacity(0.6))
                .textSelection(.enabled)

            ShareLink(item: inviteMessage) {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(.body, weight: .semibold))
                    Text("Share Invite")
                        .font(.system(.headline, design: .monospaced))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Theme.accent, in: RoundedRectangle(cornerRadius: 12))
                .shadow(color: Theme.accent.opacity(0.2), radius: 5, y: 2)
            }
            .simultaneousGesture(TapGesture().onEnded { Haptics.success() })
            .padding(.horizontal, 24)
        }
        .padding(.top, 32)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }

    // MARK: - QR Code Generation

    private func generateQRCode(from string: String) -> UIImage? {
        guard let data = string.data(using: .ascii) else { return nil }

        let filter = CIFilter.qrCodeGenerator()
        filter.message = data
        filter.correctionLevel = "M"

        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 10, y: 10))

        let tinted = scaled.applyingFilter("CIFalseColor", parameters: [
            "inputColor0": CIColor(color: UIColor(Theme.accent)),
            "inputColor1": CIColor.white,
        ])

        let context = CIContext()
        guard let cgImage = context.createCGImage(tinted, from: tinted.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - Edit Unit Sheet

/// Creator-only form for mutating a unit's name / emoji / description.
/// Presented from the overflow menu in `GroupDetailSheet`. Matches the
/// visual language of `CreateGroupSheet` so the two form surfaces feel
/// like the same flow in different modes.
private struct EditUnitSheet: View {
    @Environment(\.dismiss) private var dismiss
    let group: FriendGroupRecord
    /// Returns `true` on success (sheet dismisses) or `false` on failure
    /// (sheet stays open with the spinner cleared so the user can retry).
    let onSave: (_ name: String, _ emoji: String, _ description: String?) async -> Bool

    @State private var name: String
    @State private var emoji: String
    @State private var description: String
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(group: FriendGroupRecord, onSave: @escaping (_ name: String, _ emoji: String, _ description: String?) async -> Bool) {
        self.group = group
        self.onSave = onSave
        self._name = State(initialValue: group.name)
        self._emoji = State(initialValue: group.emoji)
        self._description = State(initialValue: group.description ?? "")
    }

    private var canSave: Bool {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !emoji.isEmpty else { return false }
        // Don't allow saving when nothing actually changed.
        let descChanged = description != (group.description ?? "")
        return trimmed != group.name || emoji != group.emoji || descChanged
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                form

                if let errorMessage {
                    Text(errorMessage)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(Theme.bloodRed)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.top, 12)
                } else if isSaving {
                    HStack(spacing: 6) {
                        ProgressView().scaleEffect(0.7)
                        Text("Filing amendment…")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(Theme.textPrimary.opacity(0.6))
                    }
                    .padding(.top, 12)
                }

                Spacer()
            }
            .background(Color.white)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        Haptics.light()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 30, height: 30)
                            .background(Theme.bloodRed, in: Circle())
                    }
                    .buttonStyle(.plain)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Haptics.medium()
                        Task { await performSave() }
                    }
                    .font(.system(.body, design: .monospaced, weight: .semibold))
                    .foregroundStyle(canSave ? Theme.accent : Theme.textPrimary.opacity(0.3))
                    .disabled(!canSave || isSaving)
                }
            }
        }
    }

    private func performSave() async {
        isSaving = true
        errorMessage = nil
        let trimmedDesc = description.trimmingCharacters(in: .whitespaces)
        let success = await onSave(
            name.trimmingCharacters(in: .whitespaces),
            String(emoji.prefix(1)),
            trimmedDesc.isEmpty ? nil : trimmedDesc
        )
        isSaving = false
        if success {
            Haptics.success()
            dismiss()
        } else {
            Haptics.warning()
            errorMessage = "Amendment denied. Try again."
        }
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text(emoji.isEmpty ? "?" : String(emoji.prefix(1)))
                .font(.system(size: 48))
            Text("AMEND UNIT RECORD")
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.5))
                .tracking(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Theme.cardBackground)
        .overlay(
            Rectangle().fill(Theme.textPrimary.opacity(0.08)).frame(height: 1),
            alignment: .bottom
        )
    }

    private var form: some View {
        VStack(spacing: 0) {
            formSection("UNIT NAME") {
                TextField("Unit designation", text: $name)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.horizontal, 24)
            }

            Divider().padding(.horizontal, 24)

            formSection("EMOJI") {
                TextField("Enter one emoji", text: $emoji)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.horizontal, 24)
                    .onChange(of: emoji) {
                        if emoji.count > 1 {
                            emoji = String(emoji.prefix(1))
                        }
                    }
            }

            Divider().padding(.horizontal, 24)

            formSection("DESCRIPTION") {
                TextField("Mission statement (optional)", text: $description)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.horizontal, 24)
            }
        }
    }

    private func formSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.5))
                .tracking(1.5)
                .padding(.horizontal, 24)
            content()
        }
        .padding(.vertical, 16)
    }
}

// MARK: - Previews

/// Preview-only reproduction of the leaderboard podium. Mirrors the styling
/// inside `GroupDetailSheet.podiumTile` pixel-for-pixel. Kept as a
/// standalone view so we can render the podium in Xcode without needing a
/// live `GroupsViewModel` + Supabase connection.
private struct LeaderboardPodiumPreview: View {
    struct SampleEntry {
        let name: String
        let duration: String
        let isUser: Bool
    }

    let entries: [SampleEntry]

    /// Preview seed: current user is silver (#2) by default, so you can see
    /// both the accent-blue name treatment and the YOU capsule on a
    /// non-gold tile.
    init(entries: [SampleEntry] = [
        SampleEntry(name: "#HW-00091", duration: "6h 48m", isUser: false),   // gold (#1)
        SampleEntry(name: "ANTONIO",   duration: "4h 12m", isUser: true),    // silver (#2)
        SampleEntry(name: "#HW-00042", duration: "2h 55m", isUser: false),   // bronze (#3)
    ]) {
        self.entries = entries
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("LEADERBOARD")
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.5))
                .tracking(1.5)

            HStack(alignment: .bottom, spacing: 10) {
                tile(entry: entries[1], rank: 2)  // silver left
                tile(entry: entries[0], rank: 1)  // gold center (tallest)
                tile(entry: entries[2], rank: 3)  // bronze right
            }
        }
    }

    private func tile(entry: SampleEntry, rank: Int) -> some View {
        let medal: String = ["🥇", "🥈", "🥉"][rank - 1]
        let tintColor: Color = {
            switch rank {
            case 1: Theme.cautionYellow.opacity(0.18)
            case 2: Theme.textPrimary.opacity(0.08)
            default: Theme.cautionYellow.opacity(0.09)
            }
        }()
        let borderColor: Color = {
            switch rank {
            case 1: Theme.cautionYellow.opacity(0.45)
            case 2: Theme.textPrimary.opacity(0.18)
            default: Theme.cautionYellow.opacity(0.22)
            }
        }()
        let verticalPadding: CGFloat = rank == 1 ? 16 : 12

        return VStack(spacing: 6) {
            Text(medal)
                .font(.system(size: rank == 1 ? 28 : 22))

            Text(entry.name)
                .font(.system(size: rank == 1 ? 11 : 10, weight: entry.isUser ? .semibold : .medium, design: .monospaced))
                .foregroundStyle(entry.isUser ? Theme.accent : Theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(entry.duration)
                .font(.system(size: rank == 1 ? 12 : 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(0.75))

            if entry.isUser {
                Text("YOU")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1.5)
                    .background(Theme.accent, in: Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, verticalPadding)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(tintColor)
                .stroke(borderColor, lineWidth: 1)
        )
    }
}

#Preview("Podium — Top 3") {
    LeaderboardPodiumPreview()
        .padding(.horizontal, 24)
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
}

#Preview("Podium — #1 is You") {
    LeaderboardPodiumPreview(entries: [
        LeaderboardPodiumPreview.SampleEntry(name: "ANTONIO",    duration: "8h 02m", isUser: true),   // gold
        LeaderboardPodiumPreview.SampleEntry(name: "#HW-00042",  duration: "5h 14m", isUser: false),  // silver
        LeaderboardPodiumPreview.SampleEntry(name: "#HW-00108",  duration: "3h 21m", isUser: false),  // bronze
    ])
    .padding(.horizontal, 24)
    .padding(.vertical, 40)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.white)
}
