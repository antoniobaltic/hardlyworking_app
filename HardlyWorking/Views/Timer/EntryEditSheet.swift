import SwiftData
import SwiftUI

struct EntryEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \CustomCategory.createdAt)
    private var customCategories: [CustomCategory]
    @Query(sort: \TimeEntry.startTime, order: .reverse)
    private var allEntries: [TimeEntry]
    @AppStorage("workHoursPerDay") private var workHoursPerDay: Double = 8.0
    @Bindable var entry: TimeEntry
    var onDelete: () -> Void

    @State private var startTime: Date
    @State private var endTime: Date
    @State private var selectedCategory: String
    @State private var showDeleteConfirmation = false
    @State private var validationError: String?

    private var allCategories: [SlackCategory] {
        SlackCategory.allCategories(custom: customCategories)
    }

    init(entry: TimeEntry, onDelete: @escaping () -> Void) {
        self.entry = entry
        self.onDelete = onDelete
        _startTime = State(initialValue: entry.startTime)
        _endTime = State(initialValue: entry.endTime ?? .now)
        _selectedCategory = State(initialValue: entry.category)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                form
                Spacer()
                deleteButton
            }
            .background(Color.white)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { Haptics.light(); dismiss() }
                        .font(.system(.body, design: .monospaced))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Haptics.medium()
                        save()
                    }
                    .font(.system(.body, design: .monospaced, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                }
            }
            .confirmationDialog(
                "Delete this entry?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Entry", role: .destructive) {
                    Haptics.warning()
                    onDelete()
                }
            } message: {
                Text("This action cannot be undone. The entry will be permanently removed.")
            }
            .onChange(of: startTime) { validationError = nil }
            .onChange(of: endTime) { validationError = nil }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 4) {
            Text("AMEND RECORD")
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.3))
                .tracking(2)
            Text(Theme.formatDuration(endTime.timeIntervalSince(startTime)))
                .font(.system(size: 36, weight: .light, design: .monospaced))
                .foregroundStyle(Theme.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Theme.cardBackground)
        .overlay(
            Rectangle().fill(Theme.textPrimary.opacity(0.08)).frame(height: 1),
            alignment: .bottom
        )
    }

    // MARK: - Form

    private var form: some View {
        VStack(spacing: 0) {
            formSection("ACTIVITY") {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(allCategories) { category in
                            Button {
                                Haptics.light()
                                selectedCategory = category.name
                            } label: {
                                HStack(spacing: 4) {
                                    Text(category.emoji)
                                        .font(.caption)
                                    Text(category.name)
                                        .font(.system(size: 11, weight: isSelected(category) ? .semibold : .regular, design: .monospaced))
                                        .foregroundStyle(isSelected(category) ? .white : Theme.textPrimary)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(isSelected(category) ? Theme.accent : Theme.cardBackground)
                                        .stroke(
                                            isSelected(category) ? Color.clear : Theme.textPrimary.opacity(0.1),
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

            Divider().padding(.horizontal, 24)

            formSection("TIME") {
                HStack(spacing: 10) {
                    DatePicker(
                        "",
                        selection: $startTime,
                        displayedComponents: [.hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()

                    Text("\u{2192}")
                        .font(.system(.caption, design: .monospaced, weight: .medium))
                        .foregroundStyle(Theme.textPrimary.opacity(0.4))

                    DatePicker(
                        "",
                        selection: $endTime,
                        in: startTime...,
                        displayedComponents: [.hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()

                    Spacer()
                }
                .padding(.horizontal, 24)
            }

            if let validationError {
                Text(validationError)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(Theme.timer)
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
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

    // MARK: - Delete

    private var deleteButton: some View {
        Button(role: .destructive) {
            Haptics.light()
            showDeleteConfirmation = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "trash")
                Text("Delete Entry")
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
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }

    // MARK: - Helpers

    private func isSelected(_ category: SlackCategory) -> Bool {
        selectedCategory == category.name
    }

    private func save() {
        if let error = RecordingLimits.validate(
            start: startTime,
            end: endTime,
            existingEntries: allEntries,
            excludingEntryID: entry,
            workHoursPerDay: workHoursPerDay
        ) {
            Haptics.warning()
            validationError = error.localizedDescription
            return
        }

        entry.category = selectedCategory
        entry.startTime = startTime
        entry.endTime = endTime
        try? entry.modelContext?.save()
        AchievementManager.markEntryEdited()
        dismiss()
    }
}
