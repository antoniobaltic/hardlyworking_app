import CoreImage.CIFilterBuiltins
import SwiftUI

struct GroupDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let group: FriendGroupRecord
    var viewModel: GroupsViewModel

    @State private var showLeaveConfirmation = false
    @State private var showDeleteConfirmation = false
    @State private var leaderboardPeriod: LeaderboardPeriod = .weekly

    enum LeaderboardPeriod: String, CaseIterable {
        case weekly = "This Week"
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

                    VStack(spacing: 28) {
                        leaderboardSection
                            .padding(.horizontal, 24)

                        Divider().padding(.horizontal, 24)

                        inviteSection
                            .padding(.horizontal, 24)

                        Divider().padding(.horizontal, 24)

                        dangerZone
                            .padding(.horizontal, 24)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 60)
                }
            }
            .background(Color.white)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { Haptics.light(); dismiss() }
                        .font(.system(.body, design: .monospaced))
                }
            }
            .task { await viewModel.loadLeaderboard(groupId: group.id) }
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
                    .foregroundStyle(Theme.textPrimary.opacity(0.4))
                    .multilineTextAlignment(.center)
            }
            Text("\(group.memberCount ?? 0) participants")
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(0.3))
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
            HStack {
                Text("LEADERBOARD")
                    .font(.system(.caption2, design: .monospaced, weight: .bold))
                    .foregroundStyle(Theme.textPrimary.opacity(0.3))
                    .tracking(1.5)

                Spacer()

                Picker("Period", selection: $leaderboardPeriod) {
                    ForEach(LeaderboardPeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }

            if viewModel.isLoadingLeaderboard {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
            } else if leaderboardPeriod == .weekly {
                weeklyLeaderboardContent
            } else {
                allTimeLeaderboardContent
            }
        }
    }

    private var weeklyLeaderboardContent: some View {
        Group {
            if viewModel.leaderboard.isEmpty {
                leaderboardEmptyState(message: "No reclamations filed this week.")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.leaderboard.enumerated()), id: \.element.userId) { index, entry in
                        leaderboardRow(
                            userId: entry.userId,
                            industry: entry.industry,
                            title: entry.reclaimerTitle,
                            totalSeconds: entry.totalSecondsThisWeek,
                            rank: index + 1,
                            index: index
                        )
                    }
                }
            }
        }
    }

    private var allTimeLeaderboardContent: some View {
        Group {
            if viewModel.leaderboardAllTime.isEmpty {
                leaderboardEmptyState(message: "No reclamations on record.")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.leaderboardAllTime.enumerated()), id: \.element.userId) { index, entry in
                        leaderboardRow(
                            userId: entry.userId,
                            industry: entry.industry,
                            title: entry.reclaimerTitle,
                            totalSeconds: entry.totalSecondsAllTime,
                            rank: index + 1,
                            index: index
                        )
                    }
                }
            }
        }
    }

    private func leaderboardEmptyState(message: String) -> some View {
        VStack(spacing: 4) {
            Text("#N/A")
                .font(.system(.title3, design: .monospaced, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.08))
            Text(message)
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(0.3))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    private func leaderboardRow(userId: UUID, industry: String?, title: String?, totalSeconds: Int, rank: Int, index: Int) -> some View {
        let isUser = userId == SupabaseManager.shared.userId
        let industryEmoji = industry.flatMap { Industry(rawValue: $0)?.emoji } ?? "\u{2753}"

        return HStack(spacing: 10) {
            Text("#\(rank)")
                .font(.system(.caption, design: .monospaced, weight: .bold))
                .foregroundStyle(rankColor(rank))
                .frame(width: 24, alignment: .trailing)

            Text(industryEmoji)
                .font(.subheadline)

            Text(title ?? "Reclaimer")
                .font(.system(.subheadline, design: .monospaced, weight: isUser ? .bold : .regular))
                .foregroundStyle(isUser ? Theme.accent : Theme.textPrimary)
                .lineLimit(1)

            Spacer()

            Text(Theme.formatDuration(Double(totalSeconds)))
                .font(.system(.caption, design: .monospaced, weight: .medium))
                .foregroundStyle(Theme.textPrimary.opacity(0.5))

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
        default: Theme.textPrimary.opacity(0.2)
        }
    }

    // MARK: - Invite

    private var inviteSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("INVITE")
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.3))
                .tracking(1.5)

            VStack(spacing: 16) {
                if let qrImage = generateQRCode(from: "hardlyworking://join/\(group.inviteCode)") {
                    Image(uiImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .frame(maxWidth: .infinity)
                } else {
                    Text("####")
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.textPrimary.opacity(0.08))
                        .frame(width: 200, height: 200)
                        .frame(maxWidth: .infinity)
                }

                Text(group.inviteCode)
                    .font(.system(.caption, design: .monospaced, weight: .medium))
                    .foregroundStyle(Theme.textPrimary.opacity(0.4))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity)

                ShareLink(item: inviteMessage) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share Invite")
                            .font(.system(.subheadline, design: .monospaced, weight: .medium))
                    }
                    .foregroundStyle(Theme.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Theme.accent, lineWidth: 1)
                    )
                }
            }
        }
    }

    // MARK: - Danger Zone

    private var dangerZone: some View {
        VStack(spacing: 12) {
            Button(role: .destructive) {
                Haptics.light()
                showLeaveConfirmation = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Leave Unit")
                        .font(.system(.subheadline, design: .monospaced))
                }
                .foregroundStyle(Theme.timer)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Theme.timer.opacity(0.3), lineWidth: 1)
                )
            }

            if isCreator {
                Button(role: .destructive) {
                    Haptics.light()
                    showDeleteConfirmation = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                        Text("Dissolve Unit")
                            .font(.system(.subheadline, design: .monospaced))
                    }
                    .foregroundStyle(Theme.timer.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
            }
        }
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
