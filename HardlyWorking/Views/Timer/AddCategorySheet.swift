import SwiftUI

struct AddCategorySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var emoji = ""
    @State private var parentName = ""

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && !emoji.isEmpty
            && !parentName.isEmpty
    }

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
                    Button("Cancel") { Haptics.light(); dismiss() }
                        .font(.system(.body, design: .monospaced))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Haptics.medium()
                        saveCategory()
                    }
                    .font(.system(.body, design: .monospaced, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .disabled(!canSave)
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text(emoji.isEmpty ? "?" : String(emoji.prefix(1)))
                .font(.system(size: 48))
            Text("NEW ACTIVITY CODE")
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
        VStack(spacing: 0) {
            formSection("CATEGORY NAME") {
                TextField("Name your activity", text: $name)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.horizontal, 24)
                    .onChange(of: name) {
                        if name.count > 25 {
                            name = String(name.prefix(25))
                        }
                    }

                Text("\(name.count)/25")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(name.count >= 25 ? Theme.timer.opacity(0.6) : Theme.textPrimary.opacity(0.3))
                    .padding(.horizontal, 24)
            }

            Divider().padding(.horizontal, 24)

            formSection("EMOJI") {
                TextField("Pick one emoji", text: $emoji)
                    .font(.system(.title2))
                    .padding(.horizontal, 24)
                    .onChange(of: emoji) {
                        if emoji.count > 1 {
                            emoji = String(emoji.prefix(1))
                        }
                    }
            }

            Divider().padding(.horizontal, 24)

            formSection("PARENT CATEGORY") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("What type of slacking is this?")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(Theme.textPrimary.opacity(0.4))
                        .padding(.horizontal, 24)

                    ScrollView(.horizontal) {
                        HStack(spacing: 8) {
                            ForEach(SlackCategory.defaults) { category in
                                Button {
                                    Haptics.light()
                                    parentName = category.name
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(category.emoji)
                                            .font(.caption)
                                        Text(category.name)
                                            .font(.system(
                                                size: 11,
                                                weight: parentName == category.name ? .semibold : .regular,
                                                design: .monospaced
                                            ))
                                            .foregroundStyle(parentName == category.name ? .white : Theme.textPrimary)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(parentName == category.name ? Theme.accent : Theme.cardBackground)
                                            .stroke(
                                                parentName == category.name ? Color.clear : Theme.textPrimary.opacity(0.1),
                                                lineWidth: 1
                                            )
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .scrollIndicators(.hidden)
                }
            }
        }
    }

    private func formSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.3))
                .tracking(1.5)
                .padding(.horizontal, 24)
            content()
        }
        .padding(.vertical, 16)
    }

    private func saveCategory() {
        let category = CustomCategory(
            name: name.trimmingCharacters(in: .whitespaces),
            emoji: String(emoji.prefix(1)),
            parentName: parentName
        )
        modelContext.insert(category)
        try? modelContext.save()
        Haptics.success()
        dismiss()
    }
}
