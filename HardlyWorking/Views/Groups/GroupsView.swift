import SwiftUI

struct GroupsView: View {
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(DeepLinkHandler.self) private var deepLinkHandler
    @State private var viewModel = GroupsViewModel()
    @State private var showCreateGroup = false
    @State private var showJoinGroup = false
    @State private var selectedGroup: FriendGroupRecord?
    @State private var showPaywall = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                formulaBar

                if viewModel.groups.isEmpty && !viewModel.isLoading {
                    emptyState
                } else {
                    groupList
                }
            }
        }
        .background(Color.white)
        .task { await viewModel.loadGroups() }
        .onAppear {
            // Auto-open join sheet if a deep link is pending
            if let code = deepLinkHandler.pendingInviteCode, !code.isEmpty {
                showJoinGroup = true
            }
        }
        .onChange(of: deepLinkHandler.pendingInviteCode) { _, newCode in
            // Handle deep links that arrive while the tab is already visible
            if let newCode, !newCode.isEmpty {
                showJoinGroup = true
            }
        }
        .sheet(isPresented: $showCreateGroup) {
            CreateGroupSheet(viewModel: viewModel)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showJoinGroup) {
            JoinGroupSheet(
                viewModel: viewModel,
                prefillCode: deepLinkHandler.pendingInviteCode,
                onDismiss: { deepLinkHandler.pendingInviteCode = nil }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $selectedGroup) { group in
            GroupDetailSheet(group: group, viewModel: viewModel)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showPaywall, onDismiss: {
            subscriptionManager.showProBannerIfPending()
        }) {
            PaywallView()
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Formula Bar

    private var formulaBar: some View {
        HStack(spacing: 0) {
            Text("D1")
                .font(.system(.caption2, design: .monospaced, weight: .medium))
                .foregroundStyle(Theme.textPrimary.opacity(0.4))
                .frame(width: 28)
                .padding(.vertical, 8)
                .background(Theme.cardBackground)
                .overlay(alignment: .trailing) {
                    Rectangle()
                        .fill(Theme.textPrimary.opacity(0.1))
                        .frame(width: 1)
                }

            HStack {
                Text("fx")
                    .font(.system(.caption2, design: .serif, weight: .bold))
                    .italic()
                    .foregroundStyle(Theme.textPrimary.opacity(0.3))

                Text("=COUNTA(my_groups)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.5))

                Spacer()

                Text(viewModel.formulaValue)
                    .font(.system(.callout, design: .monospaced, weight: .bold))
                    .foregroundStyle(viewModel.groups.isEmpty ? Theme.textPrimary.opacity(0.3) : Theme.accent)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .background(Theme.cardBackground)
        .overlay(
            Rectangle().fill(Theme.textPrimary.opacity(0.08)).frame(height: 1),
            alignment: .top
        )
        .overlay(
            Rectangle().fill(Theme.textPrimary.opacity(0.08)).frame(height: 1),
            alignment: .bottom
        )
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 24) {
            VStack(spacing: 6) {
                Text("#NULL!")
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.1))
                Text("No group affiliations on file.")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.35))
                Text("Coordinate with like-minded professionals.")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.3))
            }

            VStack(spacing: 12) {
                createGroupButton
                joinGroupButton
            }
            .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 80)
    }

    // MARK: - Group List

    private var groupList: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 14) {
                Text("YOUR GROUPS")
                    .font(.system(.caption2, design: .monospaced, weight: .bold))
                    .foregroundStyle(Theme.textPrimary.opacity(0.3))
                    .tracking(1.5)

                VStack(spacing: 10) {
                    ForEach(viewModel.groups) { group in
                        Button {
                            Haptics.light()
                            selectedGroup = group
                        } label: {
                            groupCard(group)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 24)

            VStack(spacing: 10) {
                createGroupButton
                joinGroupButton
            }
            .padding(.horizontal, 24)
        }
        .padding(.top, 20)
        .padding(.bottom, 60)
    }

    // MARK: - Group Card

    private func groupCard(_ group: FriendGroupRecord) -> some View {
        HStack(spacing: 14) {
            Text(group.emoji)
                .font(.system(size: 28))
                .frame(width: 48, height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Theme.cardBackground)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .font(.system(.subheadline, design: .monospaced, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text("\(group.memberCount ?? 0) participants")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.4))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Theme.textPrimary.opacity(0.15))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.cardBackground.opacity(0.5))
                .stroke(Theme.textPrimary.opacity(0.06), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(group.name), \(group.memberCount ?? 0) participants")
        .accessibilityHint("Tap to view group details")
    }

    // MARK: - Action Buttons

    private var createGroupButton: some View {
        Button {
            Haptics.medium()
            if subscriptionManager.isProUser {
                showCreateGroup = true
            } else {
                showPaywall = true
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(.body, weight: .bold))
                Text("Form Group")
                    .font(.system(.headline, design: .monospaced))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private var joinGroupButton: some View {
        Button {
            Haptics.light()
            showJoinGroup = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "link")
                    .font(.system(.body, weight: .medium))
                Text("Join with Code")
                    .font(.system(.headline, design: .monospaced))
            }
            .foregroundStyle(Theme.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Theme.accent, lineWidth: 1.5)
            )
        }
    }
}
