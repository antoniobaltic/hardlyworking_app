import SwiftData
import SwiftUI

struct TimerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AchievementManager.self) private var achievementManager
    @Environment(RatingManager.self) private var ratingManager
    @Query(sort: \TimeEntry.startTime, order: .reverse)
    private var allEntries: [TimeEntry]
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(NotificationManager.self) private var notificationManager
    @Query(sort: \CustomCategory.createdAt)
    private var customCategories: [CustomCategory]
    @AppStorage("hourlyRate") private var hourlyRate: Double = 15.0
    @AppStorage("workHoursPerDay") private var workHoursPerDay: Double = 8.0
    @State private var viewModel = TimerViewModel()
    @State private var editingEntry: TimeEntry?
    @State private var showAddEntry = false
    @State private var showAddCategory = false
    @State private var showPaywall = false
    @State private var showSoftCapAlert = false
    @State private var hasDismissedSoftCap = false
    @State private var showOvernightSheet = false
    @State private var hasCheckedOvernightThisSession = false

    private var allCategories: [SlackCategory] {
        SlackCategory.allCategories(custom: customCategories)
    }

    private var todayEntries: [TimeEntry] {
        let start = Calendar.current.startOfDay(for: .now)
        return allEntries.filter { $0.startTime >= start }
    }

    private var runningEntry: TimeEntry? {
        todayEntries.first(where: \.isRunning)
    }

    private var isRunning: Bool { runningEntry != nil }

    private var isDailyCapReached: Bool {
        RecordingLimits.isDailyCapReached(todayEntries: todayEntries, workHoursPerDay: workHoursPerDay)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                formulaBar
                if let syncError = viewModel.syncError {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.icloud")
                            .font(.system(.caption2))
                        Text(syncError)
                            .font(.system(.caption2, design: .monospaced))
                    }
                    .foregroundStyle(Theme.cautionYellow)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(Theme.cautionYellow.opacity(0.08))
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                timerSection
                if isRunning {
                    stopButton
                }
                Divider().padding(.horizontal, 24)
                categorySection
                Divider().padding(.horizontal, 24)
                todayLog
            }
        }
        .background(Color.white)
        .onAppear {
            viewModel.modelContext = modelContext
            viewModel.achievementManager = achievementManager
            viewModel.ratingManager = ratingManager
            viewModel.notificationManager = notificationManager
            viewModel.isProUser = subscriptionManager.isProUser
            viewModel.customCategories = customCategories
            viewModel.updateHourlyRate(hourlyRate)
            // Reset soft cap flag if no timer is running (new session)
            if !isRunning { hasDismissedSoftCap = false }
            // Check for overnight timer (only once per app session)
            if !hasCheckedOvernightThisSession {
                hasCheckedOvernightThisSession = true
                checkOvernightTimer()
            }
        }
        .onChange(of: customCategories) {
            viewModel.customCategories = customCategories
        }
        .onChange(of: hourlyRate) { _, newRate in
            viewModel.updateHourlyRate(newRate)
        }
        .onChange(of: subscriptionManager.isProUser) { _, newValue in
            viewModel.isProUser = newValue
        }
        .alert("ACTIVITY AUDIT", isPresented: $showSoftCapAlert) {
            Button("Still reclaiming") {
                Haptics.light()
                hasDismissedSoftCap = true
            }
            Button("Stop session", role: .destructive) {
                Haptics.heavy()
                viewModel.stopSlacking(entries: todayEntries)
            }
        } message: {
            Text("This session has been running for over 2 hours. Confirm you are still actively reclaiming.")
        }
        .sheet(isPresented: $showOvernightSheet) {
            overnightSheet
        }
        .sheet(item: $editingEntry) { entry in
            EntryEditSheet(entry: entry) {
                modelContext.delete(entry)
                editingEntry = nil
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showAddEntry) {
            AddEntrySheet { category, start, end in
                let entry = TimeEntry(
                    category: category,
                    startTime: start,
                    endTime: end,
                    isManual: true
                )
                modelContext.insert(entry)
                Haptics.success()
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Formula Bar

    private var formulaBar: some View {
        HStack(spacing: 0) {
            Text("A1")
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

                Text("=SUM(today_reclaimed)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.5))

                Spacer()

                TimelineView(.periodic(from: .now, by: 1)) { _ in
                    Text(Theme.formatMoney(viewModel.todayMoney(entries: todayEntries, hourlyRate: hourlyRate)))
                        .font(.system(.callout, design: .monospaced, weight: .bold))
                        .foregroundStyle(Theme.money)
                        .accessibilityLabel("Today's reclaimed amount: \(Theme.formatMoney(viewModel.todayMoney(entries: todayEntries, hourlyRate: hourlyRate)))")
                }
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

    // MARK: - Timer Display

    private var timerSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 6) {
                Circle()
                    .fill(isRunning ? Theme.timer : Theme.textPrimary.opacity(0.2))
                    .frame(width: 8, height: 8)
                Text(isRunning ? "RECORDING" : "IDLE")
                    .font(.system(.caption2, design: .monospaced, weight: .bold))
                    .foregroundStyle(isRunning ? Theme.timer : Theme.textPrimary.opacity(0.3))
                    .tracking(2)
            }

            TimelineView(.periodic(from: .now, by: 1)) { context in
                let elapsed = if let entry = runningEntry {
                    context.date.timeIntervalSince(entry.startTime)
                } else {
                    viewModel.todayTotal(entries: todayEntries)
                }

                Text(Theme.formatTimer(elapsed))
                    .font(.system(size: 72, weight: .ultraLight, design: .monospaced))
                    .foregroundStyle(isRunning ? Theme.timer : Theme.textPrimary)
                    .contentTransition(.numericText())
                    .monospacedDigit()
                    .accessibilityLabel(isRunning ? "Timer running, \(Theme.formatDuration(elapsed))" : "Today's total, \(Theme.formatDuration(elapsed))")
                    .onChange(of: Int(elapsed)) {
                        guard let entry = runningEntry else { return }
                        // Hard cap: auto-stop at 4 hours
                        if RecordingLimits.hasExceededHardCap(entry) {
                            Haptics.warning()
                            viewModel.stopSlacking(entries: todayEntries)
                        }
                        // Soft cap: prompt at 2 hours (once per session)
                        else if RecordingLimits.hasExceededSoftCap(entry) && !hasDismissedSoftCap && !showSoftCapAlert {
                            Haptics.light()
                            showSoftCapAlert = true
                        }
                    }
            }

            if let entry = runningEntry {
                activeCategoryPill(entry.category)

                TimelineView(.periodic(from: .now, by: 1)) { _ in
                    Text(Theme.formatDuration(viewModel.todayTotal(entries: todayEntries)) + " today")
                        .font(.system(.caption, design: .monospaced, weight: .medium))
                        .foregroundStyle(Theme.textPrimary.opacity(0.4))
                }
            } else {
                Text("today's total")
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.35))
            }
        }
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity)
    }

    private func activeCategoryPill(_ name: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Theme.timer)
                .frame(width: 6, height: 6)
            Text(SlackCategory.emoji(for: name, custom: customCategories))
            Text(name)
                .font(.system(.subheadline, design: .monospaced, weight: .medium))
                .foregroundStyle(Theme.textPrimary.opacity(0.7))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(Theme.timer.opacity(0.08), in: Capsule())
        .overlay(Capsule().stroke(Theme.timer.opacity(0.2)))
    }

    // MARK: - Stop Button

    private var stopButton: some View {
        Button {
            Haptics.heavy()
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.stopSlacking(entries: todayEntries)
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "stop.fill")
                    .font(.system(.body, weight: .bold))
                Text("Stop Slacking")
                    .font(.system(.headline, design: .monospaced))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Theme.timer, in: RoundedRectangle(cornerRadius: 14))
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .accessibilityLabel("Stop slacking")
        .accessibilityHint("Stops the current timer and records the session")
    }

    // MARK: - Category Grid

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Group {
                    if isDailyCapReached && !isRunning {
                        Text("DAILY ALLOCATION EXHAUSTED")
                    } else if isRunning {
                        Text("SWITCH ACTIVITY")
                    } else {
                        Text("WHAT ARE YOU DEFINITELY \(Text("NOT").bold().foregroundColor(Theme.textPrimary.opacity(0.5))) DOING?")
                    }
                }
                    .font(.system(.caption2, design: .monospaced, weight: .bold))
                    .foregroundStyle(Theme.textPrimary.opacity(0.3))
                    .tracking(1.5)
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
                spacing: 10
            ) {
                ForEach(allCategories) { category in
                    let isActive = isActiveCategory(category)

                    Button {
                        if isActive {
                            Haptics.heavy()
                        } else {
                            Haptics.medium()
                        }
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if isActive {
                                viewModel.stopSlacking(entries: todayEntries)
                            } else {
                                hasDismissedSoftCap = false // Reset soft cap flag for new session
                                viewModel.startSlacking(category: category, entries: todayEntries)
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(category.emoji)
                                .font(.subheadline)
                            Text(category.name)
                                .font(.system(size: 12, weight: isActive ? .semibold : .regular, design: .monospaced))
                                .foregroundStyle(isActive ? .white : Theme.textPrimary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            Spacer(minLength: 0)
                            if isActive {
                                Image(systemName: "stop.fill")
                                    .font(.system(size: 8))
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 10)
                        .padding(.vertical, isRunning ? 11 : 13)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(isActive ? Theme.timer : Color.white)
                                .stroke(
                                    isActive ? Color.clear : Theme.textPrimary.opacity(0.1),
                                    lineWidth: 1
                                )
                        )
                    }
                    .disabled(isDailyCapReached && !isActive)
                    .opacity(isDailyCapReached && !isActive ? 0.4 : 1)
                    .accessibilityLabel(isActive ? "Stop \(category.name)" : "Start \(category.name)")
                    .accessibilityHint(isActive ? "Stops the running timer" : "Starts tracking \(category.name)")
                }

                // "+" button to add custom category (Pro-only)
                Button {
                    Haptics.light()
                    if subscriptionManager.isProUser {
                        showAddCategory = true
                    } else {
                        showPaywall = true
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Theme.accent.opacity(0.5))
                        Text("Add")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(Theme.accent.opacity(0.5))
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 10)
                    .padding(.vertical, isRunning ? 11 : 13)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Theme.accent.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [5, 3]))
                    )
                }
            }
            .padding(.horizontal, 24)
        }
        .padding(.bottom, 24)
        .sheet(isPresented: $showAddCategory) {
            AddCategorySheet()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showPaywall, onDismiss: {
            subscriptionManager.showProBannerIfPending()
        }) {
            PaywallView()
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Today's Log

    private var todayLog: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("TODAY'S LOG")
                    .font(.system(.caption2, design: .monospaced, weight: .bold))
                    .foregroundStyle(Theme.textPrimary.opacity(0.3))
                    .tracking(1.5)
                Spacer()
                Button("Add Entry", systemImage: "plus") {
                    Haptics.light()
                    showAddEntry = true
                }
                .labelStyle(.iconOnly)
                .font(.system(.caption, weight: .bold))
                .foregroundStyle(Theme.accent)
                .frame(width: 28, height: 28)
                .background(Theme.accent.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 14)

            let completed = todayEntries.filter { !$0.isRunning }

            if completed.isEmpty {
                emptyLogState
            } else {
                HStack {
                    Text(Theme.formatDuration(viewModel.todayTotal(entries: todayEntries)))
                        .font(.system(.caption, design: .monospaced, weight: .medium))
                        .foregroundStyle(Theme.textPrimary.opacity(0.4))
                    Text("\u{00B7}")
                        .foregroundStyle(Theme.textPrimary.opacity(0.2))
                    Text("\(completed.count) \(completed.count == 1 ? "entry" : "entries")")
                        .font(.system(.caption, design: .monospaced, weight: .medium))
                        .foregroundStyle(Theme.textPrimary.opacity(0.4))
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 12)

                // Column headers
                HStack {
                    Text("TIME")
                        .frame(width: 50, alignment: .leading)
                    Text("ACTIVITY")
                    Spacer()
                    Text("DURATION")
                }
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.35))
                .tracking(0.5)
                .padding(.horizontal, 24)
                .padding(.bottom, 8)

                ForEach(Array(completed.enumerated()), id: \.element.persistentModelID) { index, entry in
                    Button {
                        Haptics.selection()
                        editingEntry = entry
                    } label: {
                        logRow(entry: entry, isEven: index.isMultiple(of: 2))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.bottom, 60)
    }

    private var emptyLogState: some View {
        VStack(spacing: 6) {
            Text("#N/A")
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(0.1))
            Text("No entries yet. Tap an activity code above.")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(0.35))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    private func logRow(entry: TimeEntry, isEven: Bool) -> some View {
        HStack {
            Text(entry.startTime, format: .dateTime.hour().minute())
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(0.45))
                .frame(width: 50, alignment: .leading)

            Text(SlackCategory.emoji(for: entry.category, custom: customCategories))
                .font(.caption)

            Text(entry.category)
                .font(.system(.subheadline, design: .monospaced))
                .foregroundStyle(Theme.textPrimary)

            Spacer()

            Text(Theme.formatDuration(entry.duration))
                .font(.system(.subheadline, design: .monospaced, weight: .medium))
                .foregroundStyle(Theme.accent)

            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Theme.textPrimary.opacity(0.15))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 11)
        .background(isEven ? Theme.cardBackground.opacity(0.4) : Color.clear)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.category), \(Theme.formatDuration(entry.duration))")
        .accessibilityHint("Tap to edit this entry")
    }

    // MARK: - Helpers

    private func isActiveCategory(_ category: SlackCategory) -> Bool {
        guard let entry = runningEntry else { return false }
        return entry.category == category.name
    }

    // MARK: - Overnight Detection

    private func checkOvernightTimer() {
        guard let entry = runningEntry, RecordingLimits.isLikelyOvernight(entry) else { return }
        showOvernightSheet = true
    }

    private var overnightSheet: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 4) {
                    Text("DISCREPANCY DETECTED")
                        .font(.system(.caption2, design: .monospaced, weight: .bold))
                        .foregroundStyle(Theme.cautionYellow)
                        .tracking(2)
                    if let entry = allEntries.first(where: \.isRunning) {
                        Text(Theme.formatDuration(entry.duration))
                            .font(.system(size: 36, weight: .light, design: .monospaced))
                            .foregroundStyle(Theme.textPrimary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Theme.cardBackground)
                .overlay(
                    Rectangle().fill(Theme.cautionYellow.opacity(0.3)).frame(height: 2),
                    alignment: .bottom
                )

                VStack(spacing: 16) {
                    Text("Your timer was running during\nnon-business hours. How would\nyou like to proceed?")
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundStyle(Theme.textPrimary.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.top, 24)

                    VStack(spacing: 10) {
                        Button {
                            Haptics.medium()
                            // Keep full duration — just stop the timer
                            viewModel.stopSlacking(entries: todayEntries)
                            showOvernightSheet = false
                        } label: {
                            Text("Keep full duration")
                                .font(.system(.subheadline, design: .monospaced, weight: .medium))
                                .foregroundStyle(Theme.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Theme.cardBackground.opacity(0.5))
                                        .stroke(Theme.textPrimary.opacity(0.06), lineWidth: 1)
                                )
                        }

                        Button {
                            Haptics.medium()
                            // Trim to 4 hours max
                            if let entry = allEntries.first(where: \.isRunning) {
                                entry.endTime = entry.startTime.addingTimeInterval(RecordingLimits.hardCapSeconds)
                                try? modelContext.save()
                            }
                            showOvernightSheet = false
                        } label: {
                            Text("Cap at 4 hours")
                                .font(.system(.subheadline, design: .monospaced, weight: .medium))
                                .foregroundStyle(Theme.accent)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Theme.accent, lineWidth: 1)
                                )
                        }

                        Button(role: .destructive) {
                            Haptics.warning()
                            // Discard the entry entirely
                            if let entry = allEntries.first(where: \.isRunning) {
                                modelContext.delete(entry)
                                try? modelContext.save()
                            }
                            showOvernightSheet = false
                        } label: {
                            Text("Discard session")
                                .font(.system(.subheadline, design: .monospaced))
                                .foregroundStyle(Theme.timer)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                    }
                    .padding(.horizontal, 24)
                }

                Spacer()
            }
            .background(Color.white)
            .interactiveDismissDisabled()
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    TimerView()
        .modelContainer(for: TimeEntry.self, inMemory: true)
}
