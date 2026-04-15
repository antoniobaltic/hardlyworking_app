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
        VStack(spacing: 0) {
            formulaBar
            // Three-way state. Without the loading branch the empty-state
            // mascot would flash for the entire duration of the initial
            // network fetch, even for users who actually have units —
            // because `viewModel.groups` starts empty before the request
            // resolves.
            if !viewModel.hasLoaded {
                loadingState
            } else if viewModel.groups.isEmpty {
                GroupsEmptyStateView(
                    onEstablish: {
                        Haptics.medium()
                        if subscriptionManager.isProUser {
                            showCreateGroup = true
                        } else {
                            showPaywall = true
                        }
                    },
                    onJoin: {
                        Haptics.light()
                        showJoinGroup = true
                    }
                )
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        groupList
                    }
                }
            }
        }
        .background(Color.white)
        // `.task(id:)` re-fires whenever `isAuthenticated` changes. On a
        // cold launch the Supabase auth listener resolves a few hundred ms
        // after the view appears, flipping isAuthenticated false → true.
        // That flip retriggers this task and the load actually runs. Without
        // the id key, the first task call would silently bail on the auth
        // guard and the view would sit on the loading state forever.
        .task(id: SupabaseManager.shared.isAuthenticated) {
            await viewModel.loadGroups()
        }
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
        .fullScreenCover(isPresented: $showPaywall, onDismiss: {
            subscriptionManager.showProBannerIfPending()
        }) {
            PaywallView()
        }
    }

    // MARK: - Loading State

    /// Shown on first visit while the initial `loadGroups()` is in flight.
    /// Corporate-ironic copy keeps the on-brand voice while the user waits.
    private var loadingState: some View {
        VStack(spacing: 14) {
            ProgressView()
                .tint(Theme.accent)

            Text("Retrieving unit assignments…")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(0.5))
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Formula Bar

    private var formulaBar: some View {
        HStack(spacing: 0) {
            Text("D1")
                .font(.system(.caption2, design: .monospaced, weight: .medium))
                .foregroundStyle(Theme.textPrimary.opacity(0.5))
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
                    .foregroundStyle(Theme.textPrimary.opacity(0.5))

                Text("=COUNTA(my_groups)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.65))

                Spacer()

                Text(viewModel.formulaValue)
                    .font(.system(.callout, design: .monospaced, weight: .bold))
                    .foregroundStyle(viewModel.groups.isEmpty ? Theme.textPrimary.opacity(0.3) : Theme.accent)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .background(Theme.cardBackground.ignoresSafeArea(.all, edges: .top))
        .overlay(
            Rectangle().fill(Theme.textPrimary.opacity(0.08)).frame(height: 1),
            alignment: .bottom
        )
    }


    // MARK: - Group List

    private var groupList: some View {
        VStack(spacing: 20) {
            // Small circle-button action row pinned above the section header.
            // Keeps the section focused on the user's units while the primary
            // actions remain one tap away.
            HStack(spacing: 10) {
                Spacer()
                establishCircleButton
                joinCircleButton
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)

            VStack(alignment: .leading, spacing: 14) {
                Text("YOUR RECLAMATION UNITS")
                    .font(.system(.caption2, design: .monospaced, weight: .bold))
                    .foregroundStyle(Theme.textPrimary.opacity(0.5))
                    .tracking(1.5)

                VStack(spacing: 12) {
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
        }
        .padding(.top, 20)
        .padding(.bottom, 60)
    }

    // MARK: - Group Card

    private func groupCard(_ group: FriendGroupRecord) -> some View {
        let count = group.memberCount ?? 0
        return HStack(spacing: 14) {
            Text(group.emoji)
                .font(.system(size: 30))
                .frame(width: 52, height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.cardBackground)
                        .stroke(Theme.textPrimary.opacity(0.05), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .font(.system(.subheadline, design: .monospaced, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 9))
                    Text("\(count) \(count == 1 ? "participant" : "participants")")
                        .font(.system(.caption, design: .monospaced))
                }
                .foregroundStyle(Theme.textPrimary.opacity(0.5))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.textPrimary.opacity(0.3))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .shadow(color: Theme.textPrimary.opacity(0.05), radius: 6, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Theme.textPrimary.opacity(0.06), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(group.name), \(count) \(count == 1 ? "participant" : "participants")")
        .accessibilityHint("Tap to view unit details")
    }

    // MARK: - Circle Action Buttons

    private var establishCircleButton: some View {
        Button {
            Haptics.medium()
            if subscriptionManager.isProUser {
                showCreateGroup = true
            } else {
                showPaywall = true
            }
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(Theme.accent, in: Circle())
                .shadow(color: Theme.accent.opacity(0.25), radius: 5, y: 2)
        }
        .accessibilityLabel("Establish Unit")
    }

    private var joinCircleButton: some View {
        Button {
            Haptics.light()
            showJoinGroup = true
        } label: {
            Image(systemName: "link")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 38, height: 38)
                .background(Color.white, in: Circle())
                .overlay(
                    Circle().stroke(Theme.accent, lineWidth: 1.5)
                )
        }
        .accessibilityLabel("Join with Code")
    }
}

// MARK: - Empty State View

private struct GroupsEmptyStateView: View {
    let onEstablish: () -> Void
    let onJoin: () -> Void

    @State private var dialogueStage = 0
    @State private var showReplyButton = false
    @State private var replyPulse = false
    /// Manual pulse driver. Using a Task we can cancel instead of
    /// `withAnimation(.repeatForever)` which layers on every reappear and
    /// makes the pulse compound each time the user returns to this screen.
    @State private var pulseTask: Task<Void, Never>?

    private var bubbleText: String {
        switch dialogueStage {
        case 1: "It's true.\nI read it on WiredIn."
        case 2: "Certainly, yes."
        default: "A corporation depends on\nteam work, you know?"
        }
    }

    private var replyText: String {
        switch dialogueStage {
        case 0: "I didn't\nknow that."
        case 1: "Then it's\ncertainly true."
        default: ""
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            ZStack(alignment: .top) {
                Image("mascot_aha")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 180)
                    .padding(.top, 56)
                    .offset(x: -30)

                speechBubble
                    .offset(x: 30)

                if showReplyButton {
                    replyButton
                        .scaleEffect(replyPulse ? 1.08 : 1.0)
                        .offset(x: 110, y: 72)
                }
            }

            Text("Not-working is\na team effort")
                .font(.system(size: 22, weight: .light, design: .monospaced))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)

            Text("Create a unit or join one with a code.\nHold each other unaccountable.")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(0.5))
                .multilineTextAlignment(.center)

            VStack(spacing: 10) {
                Button(action: onEstablish) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(.body, weight: .medium))
                        Text("Establish Unit")
                            .font(.system(.subheadline, design: .monospaced, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14))
                    .shadow(color: Theme.accent.opacity(0.2), radius: 8, y: 4)
                }

                Button(action: onJoin) {
                    HStack(spacing: 8) {
                        Image(systemName: "link.circle")
                            .font(.system(.body, weight: .medium))
                        Text("Join with Code")
                            .font(.system(.subheadline, design: .monospaced, weight: .semibold))
                    }
                    .foregroundStyle(Theme.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Theme.accent.opacity(0.06))
                            .stroke(Theme.accent.opacity(0.3), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            dialogueStage = 0
            replyPulse = false
            showReplyButton = true
            startPulseLoop(afterDelay: 0.3)
        }
        .onDisappear {
            pulseTask?.cancel()
            pulseTask = nil
            replyPulse = false
        }
    }

    /// Drive the reply-button pulse via a cancellable Task. Avoids SwiftUI's
    /// `withAnimation(.repeatForever)` layering bug — each re-visit of this
    /// screen was stacking another infinite animation on top of the previous.
    private func startPulseLoop(afterDelay delay: Double) {
        pulseTask?.cancel()
        pulseTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(delay))
            while !Task.isCancelled {
                withAnimation(.easeInOut(duration: 0.8)) { replyPulse = true }
                try? await Task.sleep(for: .milliseconds(800))
                guard !Task.isCancelled else { break }
                withAnimation(.easeInOut(duration: 0.8)) { replyPulse = false }
                try? await Task.sleep(for: .milliseconds(800))
            }
        }
    }

    // MARK: - Speech Bubble

    private var speechBubble: some View {
        Text(bubbleText)
            .font(.system(.caption, design: .monospaced, weight: .medium))
            .foregroundStyle(Theme.textPrimary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background {
                GroupsBubbleShape(tailOffset: -20)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
            }
            .background {
                GroupsBubbleShape(tailOffset: -20)
                    .stroke(Theme.textPrimary.opacity(0.12), lineWidth: 1)
            }
            .animation(.easeInOut(duration: 0.3), value: dialogueStage)
    }

    private var replyButton: some View {
        Button {
            Haptics.light()
            let nextStage = dialogueStage + 1

            // Cancel current pulse while the button is hidden mid-dialogue.
            pulseTask?.cancel()
            pulseTask = nil
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showReplyButton = false
                replyPulse = false
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    dialogueStage = nextStage
                }

                if nextStage < 2 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                            showReplyButton = true
                        }
                        // Restart the pulse via the same cancellable loop.
                        startPulseLoop(afterDelay: 0.6)
                    }
                }
            }
        } label: {
            Text(replyText)
                .font(.system(.caption, design: .monospaced, weight: .medium))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Theme.accent)
                        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
                }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Bubble Shape

private struct GroupsBubbleShape: Shape {
    var tailOffset: CGFloat = 0
    var cornerRadius: CGFloat = 10
    var tailWidth: CGFloat = 12
    var tailHeight: CGFloat = 8

    func path(in rect: CGRect) -> Path {
        let r = cornerRadius
        let tailCenterX = rect.midX + tailOffset
        let tailLeft = tailCenterX - tailWidth / 2
        let tailRight = tailCenterX + tailWidth / 2

        var p = Path()
        p.move(to: CGPoint(x: rect.minX + r, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
        p.addArc(center: CGPoint(x: rect.maxX - r, y: rect.minY + r),
                 radius: r, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
        p.addArc(center: CGPoint(x: rect.maxX - r, y: rect.maxY - r),
                 radius: r, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        p.addLine(to: CGPoint(x: tailRight, y: rect.maxY))
        p.addLine(to: CGPoint(x: tailCenterX, y: rect.maxY + tailHeight))
        p.addLine(to: CGPoint(x: tailLeft, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX + r, y: rect.maxY))
        p.addArc(center: CGPoint(x: rect.minX + r, y: rect.maxY - r),
                 radius: r, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
        p.addArc(center: CGPoint(x: rect.minX + r, y: rect.minY + r),
                 radius: r, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        p.closeSubpath()
        return p
    }
}
