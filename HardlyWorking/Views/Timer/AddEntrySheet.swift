import SwiftData
import SwiftUI

struct AddEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \CustomCategory.createdAt)
    private var customCategories: [CustomCategory]
    @Query(sort: \TimeEntry.startTime, order: .reverse)
    private var allEntries: [TimeEntry]
    @AppStorage("workHoursPerDay") private var workHoursPerDay: Double = 8.0
    var onSave: (String, Date, Date) -> Void

    @State private var selectedCategory: String = SlackCategory.defaults[0].name
    @State private var validationError: String?

    private var allCategories: [SlackCategory] {
        SlackCategory.allCategories(custom: customCategories)
    }
    @State private var startTime: Date = Calendar.current.date(
        byAdding: .minute, value: -30, to: .now
    ) ?? .now
    @State private var endTime: Date = .now

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
                    Button("Add") {
                        if let error = RecordingLimits.validate(
                            start: startTime,
                            end: endTime,
                            existingEntries: allEntries,
                            workHoursPerDay: workHoursPerDay
                        ) {
                            Haptics.warning()
                            validationError = error.localizedDescription
                        } else {
                            Haptics.medium()
                            onSave(selectedCategory, startTime, endTime)
                            dismiss()
                        }
                    }
                    .font(.system(.body, design: .monospaced, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .disabled(endTime <= startTime)
                }
            }
            .onChange(of: startTime) { validationError = nil }
            .onChange(of: endTime) { validationError = nil }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 4) {
            Text("RETROACTIVE ENTRY")
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.5))
                .tracking(2)
            Text(Theme.formatDuration(max(0, endTime.timeIntervalSince(startTime))))
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
                .foregroundStyle(Theme.textPrimary.opacity(0.5))
                .tracking(1.5)
                .padding(.horizontal, 24)
            content()
        }
        .padding(.vertical, 16)
    }

    private func isSelected(_ category: SlackCategory) -> Bool {
        selectedCategory == category.name
    }
}
