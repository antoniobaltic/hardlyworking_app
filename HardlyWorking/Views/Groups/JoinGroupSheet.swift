import SwiftUI

struct JoinGroupSheet: View {
    @Environment(\.dismiss) private var dismiss
    var viewModel: GroupsViewModel
    var prefillCode: String?
    var onDismiss: (() -> Void)?

    @State private var rawInput = ""
    @State private var lookedUpGroup: FriendGroupRecord?
    @State private var isLookingUp = false
    @State private var isJoining = false
    @State private var errorMessage: String?
    @FocusState private var isInputFocused: Bool

    private var cleanCode: String {
        String(rawInput.lowercased().filter { $0.isLetter || $0.isNumber }.prefix(12))
    }

    private var isCodeComplete: Bool {
        cleanCode.count == 12
    }

    private var codeCharacters: [Character?] {
        let chars = Array(cleanCode)
        return (0..<12).map { $0 < chars.count ? chars[$0] : nil }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                form
                Spacer()
            }
            .background(Color.white)
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture { isInputFocused = false }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        Haptics.light()
                        onDismiss?()
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
            }
            .onAppear {
                if let prefillCode, !prefillCode.isEmpty {
                    rawInput = prefillCode
                    if isCodeComplete {
                        Task { await lookupGroup() }
                    }
                } else {
                    isInputFocused = true
                }
            }
            .onChange(of: rawInput) {
                // Auto-lookup when 12 hex chars entered
                if isCodeComplete && lookedUpGroup == nil && !isLookingUp {
                    Task { await lookupGroup() }
                }
                // Reset lookup if user edits after a failed attempt
                if !isCodeComplete {
                    lookedUpGroup = nil
                    errorMessage = nil
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
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Text("INVITE CODE")
                    .font(.system(.caption2, design: .monospaced, weight: .bold))
                    .foregroundStyle(Theme.textPrimary.opacity(0.5))
                    .tracking(1.5)
                    .padding(.horizontal, 24)

                codeDisplay
                    .padding(.horizontal, 24)
            }
            .padding(.top, 16)

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

    // MARK: - Code Display

    private var codeDisplay: some View {
        ZStack {
            // Hidden single TextField for keyboard input
            TextField("", text: $rawInput)
                .focused($isInputFocused)
                .keyboardType(.asciiCapable)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .foregroundStyle(.clear)
                .tint(.clear)
                .frame(width: 1, height: 1)
                .opacity(0.01)

            // Visual cells
            HStack(spacing: 0) {
                cellGroup(range: 0..<4)

                Text("·")
                    .font(.system(.caption, design: .monospaced, weight: .bold))
                    .foregroundStyle(Theme.textPrimary.opacity(0.25))
                    .padding(.horizontal, 4)

                cellGroup(range: 4..<8)

                Text("·")
                    .font(.system(.caption, design: .monospaced, weight: .bold))
                    .foregroundStyle(Theme.textPrimary.opacity(0.25))
                    .padding(.horizontal, 4)

                cellGroup(range: 8..<12)
            }
            .contentShape(Rectangle())
            .onTapGesture { isInputFocused = true }
        }
    }

    private func cellGroup(range: Range<Int>) -> some View {
        HStack(spacing: 3) {
            ForEach(range, id: \.self) { index in
                let char = codeCharacters[index]
                let isCursor = index == cleanCode.count && isInputFocused

                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(char != nil ? Theme.accent.opacity(0.06) : Theme.cardBackground.opacity(0.5))
                        .stroke(
                            isCursor ? Theme.accent : Theme.textPrimary.opacity(char != nil ? 0.15 : 0.08),
                            lineWidth: isCursor ? 2 : 1
                        )

                    if let char {
                        Text(String(char))
                            .font(.system(.body, design: .monospaced, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 40)
            }
        }
    }

    // MARK: - Group Preview

    private func groupPreview(_ group: FriendGroupRecord) -> some View {
        VStack(spacing: 8) {
            Text(group.emoji)
                .font(.system(size: 40))
            Text(group.name)
                .font(.system(.headline, design: .monospaced))
                .foregroundStyle(Theme.textPrimary)
            Text("\(group.memberCount ?? 0) participants")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(0.5))
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

    // MARK: - Join Button

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

    // MARK: - Network

    private func lookupGroup() async {
        isLookingUp = true
        errorMessage = nil

        let group = await viewModel.lookupGroup(inviteCode: cleanCode)

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

        let success = await viewModel.joinGroup(inviteCode: cleanCode)

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
