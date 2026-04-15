import SwiftUI

struct CreateGroupSheet: View {
    @Environment(\.dismiss) private var dismiss
    var viewModel: GroupsViewModel

    @State private var name = ""
    @State private var emoji = ""
    @State private var description = ""
    @State private var isSaving = false

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !emoji.isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                form

                if let error = viewModel.error {
                    Text(error)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(Theme.bloodRed)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.top, 12)
                } else if isSaving {
                    HStack(spacing: 6) {
                        ProgressView().scaleEffect(0.7)
                        Text("Filing paperwork…")
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
                    Button("Establish") {
                        Haptics.medium()
                        Task { await createGroup() }
                    }
                    .font(.system(.body, design: .monospaced, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .disabled(!canSave || isSaving)
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text(emoji.isEmpty ? "?" : String(emoji.prefix(1)))
                .font(.system(size: 48))
            Text("RECLAMATION UNIT FORMATION")
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
            formSection("GROUP NAME") {
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

    private func createGroup() async {
        isSaving = true
        let success = await viewModel.createGroup(
            name: name.trimmingCharacters(in: .whitespaces),
            emoji: String(emoji.prefix(1)),
            description: description.isEmpty ? nil : description
        )
        if success {
            Haptics.success()
            dismiss()
        }
        isSaving = false
    }
}
