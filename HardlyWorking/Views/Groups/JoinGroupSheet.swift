import SwiftUI

struct JoinGroupSheet: View {
    @Environment(\.dismiss) private var dismiss
    var viewModel: GroupsViewModel
    var prefillCode: String?
    var onDismiss: (() -> Void)?

    @State private var inviteCode = ""
    @State private var lookedUpGroup: FriendGroupRecord?
    @State private var isLookingUp = false
    @State private var isJoining = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                form
                Spacer()
            }
            .background(Color.white)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        Haptics.light()
                        onDismiss?()
                        dismiss()
                    }
                    .font(.system(.body, design: .monospaced))
                }
            }
            .onAppear {
                if let prefillCode, !prefillCode.isEmpty {
                    inviteCode = prefillCode
                    Task { await lookupGroup() }
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text(lookedUpGroup?.emoji ?? "?")
                .font(.system(size: 48))
            Text("RECLAMATION UNIT ENROLLMENT")
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.3))
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
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Text("INVITE CODE")
                    .font(.system(.caption2, design: .monospaced, weight: .bold))
                    .foregroundStyle(Theme.textPrimary.opacity(0.3))
                    .tracking(1.5)
                    .padding(.horizontal, 24)

                HStack {
                    TextField("Authorization code", text: $inviteCode)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(Theme.textPrimary)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    if !inviteCode.isEmpty && lookedUpGroup == nil {
                        Button {
                            Haptics.light()
                            Task { await lookupGroup() }
                        } label: {
                            Text("Look Up")
                                .font(.system(.caption, design: .monospaced, weight: .semibold))
                                .foregroundStyle(Theme.accent)
                        }
                        .disabled(isLookingUp)
                    }
                }
                .padding(.horizontal, 24)
            }
            .padding(.vertical, 16)

            if isLookingUp {
                ProgressView()
                    .padding()
            }

            if let group = lookedUpGroup {
                groupPreview(group)
                joinButton
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(Theme.timer)
                    .padding(.horizontal, 24)
            }
        }
    }

    private func groupPreview(_ group: FriendGroupRecord) -> some View {
        VStack(spacing: 8) {
            Text(group.emoji)
                .font(.system(size: 40))
            Text(group.name)
                .font(.system(.headline, design: .monospaced))
                .foregroundStyle(Theme.textPrimary)
            Text("\(group.memberCount ?? 0) participants")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.cardBackground.opacity(0.5))
                .stroke(Theme.textPrimary.opacity(0.06), lineWidth: 1)
        )
        .padding(.horizontal, 24)
    }

    private var joinButton: some View {
        Button {
            Haptics.medium()
            Task { await joinGroup() }
        } label: {
            HStack(spacing: 8) {
                if isJoining {
                    ProgressView().tint(.white)
                } else {
                    Text("Confirm Enrollment")
                        .font(.system(.headline, design: .monospaced))
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14))
        }
        .disabled(isJoining)
        .padding(.horizontal, 24)
    }

    private func lookupGroup() async {
        isLookingUp = true
        errorMessage = nil

        let group = await viewModel.lookupGroup(inviteCode: inviteCode.trimmingCharacters(in: .whitespaces))

        if let group {
            lookedUpGroup = group
        } else {
            errorMessage = "Authorization code not recognized."
        }

        isLookingUp = false
    }

    private func joinGroup() async {
        isJoining = true
        errorMessage = nil

        let success = await viewModel.joinGroup(inviteCode: inviteCode.trimmingCharacters(in: .whitespaces))

        if success {
            Haptics.success()
            onDismiss?()
            dismiss()
        } else {
            errorMessage = viewModel.error ?? "Enrollment request denied."
        }

        isJoining = false
    }
}
