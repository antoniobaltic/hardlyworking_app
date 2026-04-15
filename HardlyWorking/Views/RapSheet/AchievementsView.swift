            import SwiftData
import SwiftUI

struct AchievementsView: View {
    @Query(sort: \TimeEntry.startTime, order: .reverse) private var allEntries: [TimeEntry]
    @AppStorage("hourlyRate") private var hourlyRate: Double = 15.0
    @Environment(SubscriptionManager.self) private var subscriptionManager
    var achievementManager: AchievementManager
    @State private var showPaywall = false

    private var isProUser: Bool { subscriptionManager.isProUser }

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    /// Count of achievements fully completed (every tier unlocked).
    /// Multi-tier achievements at Level 1 of N still read as "in progress" to
    /// users, so the counter reflects completions only — this matches the
    /// intuitive reading of "N/16".
    /// Pro-locked achievements are excluded for free users regardless of silent
    /// progress, since those cards display as locked.
    private var achievementsUnlockedCount: Int {
        AchievementCatalog.all.filter { def in
            let isProLocked = def.isProOnly && !isProUser
            guard !isProLocked else { return false }
            return achievementManager.unlockedLevel(for: def.id) >= def.totalLevels
        }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("COMMENDATIONS")
                    .font(.system(.caption2, design: .monospaced, weight: .bold))
                    .foregroundStyle(Theme.textPrimary.opacity(0.5))
                    .tracking(1.5)

                Spacer()

                Text("\(achievementsUnlockedCount)/\(AchievementCatalog.totalAchievements)")
                    .font(.system(.caption2, design: .monospaced, weight: .medium))
                    .foregroundStyle(Theme.textPrimary.opacity(0.5))
            }

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(AchievementCatalog.all) { definition in
                    achievementCard(definition)
                }
            }
        }
        .fullScreenCover(isPresented: $showPaywall, onDismiss: {
            subscriptionManager.showProBannerIfPending()
        }) {
            PaywallView()
        }
    }

    private func achievementCard(_ definition: AchievementDefinition) -> some View {
        let unlockedLevel = achievementManager.unlockedLevel(for: definition.id)
        let isUnlocked = unlockedLevel > 0
        let isSecret = definition.isSecret && !isUnlocked
        let isProLocked = definition.isProOnly && !isProUser
        // For visual treatment only: Pro-locked cards appear locked to free users,
        // even if progress has been silently tracked. Real unlock state reveals after upgrade.
        let visualUnlocked = isUnlocked && !isProLocked
        let isCompleted = visualUnlocked && unlockedLevel >= definition.totalLevels
        let progressValue = definition.checker(allEntries.filter { !$0.isRunning }, hourlyRate)
        let currentRarity = visualUnlocked ? definition.rarityForLevel(unlockedLevel) : .common
        let nextThreshold = definition.nextThreshold(after: progressValue)

        return Button {
            if isProLocked {
                Haptics.light()
                showPaywall = true
            }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                // Header: emoji + level badge — fixed height slot
                HStack(alignment: .top) {
                    Text(isSecret ? "\u{1F50F}" : definition.emoji)
                        .font(.system(size: 28))
                        .opacity(isProLocked ? 0.35 : 1.0)
                        // Emojis render at full color at opacity 1.0, so completed
                        // icons get a brightness/saturation boost to look distinctly
                        // richer than the uncompleted ones.
                        .brightness(isCompleted ? -0.12 : 0)
                        .saturation(isCompleted ? 1.15 : 1.0)

                    Spacer()

                    if isProLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Theme.accent.opacity(0.6))
                    }
                }
                .frame(height: 32, alignment: .top)

                // Name — always reserves 2 lines so cards align
                Text(isSecret ? "???" : definition.name)
                    .font(.system(.caption, design: .monospaced, weight: isCompleted ? .bold : .semibold))
                    .foregroundStyle(isProLocked ? Theme.textPrimary.opacity(0.6) : Theme.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity, minHeight: 32, alignment: .topLeading)

                // Status / Progress — fixed height slot
                statusSection(
                    definition: definition,
                    unlockedLevel: unlockedLevel,
                    progressValue: progressValue,
                    nextThreshold: nextThreshold,
                    currentRarity: currentRarity,
                    isUnlocked: visualUnlocked,
                    isCompleted: isCompleted,
                    isSecret: isSecret,
                    isProLocked: isProLocked
                )
                .frame(height: 44, alignment: .top)

                // Rarity badge — always reserves space so cards align
                Group {
                    if visualUnlocked {
                        Text(currentRarity.label)
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(currentRarity.color)
                            .tracking(0.5)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    } else {
                        Color.clear
                    }
                }
                .frame(height: 12, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        isCompleted
                            ? Theme.cardBackground
                            : (isProLocked
                                ? Theme.accent.opacity(0.18)
                                : Theme.cardBackground.opacity(0.6))
                    )
                    .stroke(
                        isCompleted
                            ? Theme.accent
                            : (visualUnlocked ? currentRarity.color.opacity(0.2) : Theme.textPrimary.opacity(0.06)),
                        lineWidth: isCompleted ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        // Don't use .disabled — SwiftUI fades the content of disabled buttons,
        // which washes out completed cards. The action closure already no-ops
        // for non-Pro-locked cards.
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel(
            definition: definition,
            unlockedLevel: unlockedLevel,
            currentRarity: currentRarity,
            isSecret: isSecret,
            isProLocked: isProLocked
        ))
    }

    // MARK: - Status Section

    @ViewBuilder
    private func statusSection(
        definition: AchievementDefinition,
        unlockedLevel: Int,
        progressValue: Double,
        nextThreshold: Double?,
        currentRarity: AchievementRarity,
        isUnlocked: Bool,
        isCompleted: Bool,
        isSecret: Bool,
        isProLocked: Bool
    ) -> some View {
        // Completed cards get full-contrast status text for max emphasis.
        let primaryOpacity: Double = isCompleted ? 1.0 : 0.5
        let secondaryOpacity: Double = isCompleted ? 0.95 : 0.45

        if isSecret {
            Text("Classified. Unlock to reveal.")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(primaryOpacity))
        } else if isProLocked {
            // Hide silently-tracked progress from free users; tease the reward.
            Text("Executive only")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(primaryOpacity))
        } else if definition.totalLevels == 1 {
            // Single-level achievement (e.g., first offense, retroactive filing)
            if isUnlocked {
                if let date = achievementManager.unlockDate(for: definition.id) {
                    Text(date, format: .dateTime.month(.abbreviated).day().year())
                        .font(.system(size: 10, weight: isCompleted ? .semibold : .regular, design: .monospaced))
                        .foregroundStyle(Theme.textPrimary.opacity(primaryOpacity))
                }
            } else {
                Text(isProLocked ? "Executive only" : "Not yet earned")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(primaryOpacity))
            }
        } else {
            // Multi-level achievement
            VStack(alignment: .leading, spacing: 4) {
                Text("Level \(unlockedLevel) of \(definition.totalLevels)")
                    .font(.system(size: 10, weight: isCompleted ? .semibold : .regular, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(primaryOpacity))

                progressBar(
                    current: progressValue,
                    nextThreshold: nextThreshold,
                    previousThreshold: unlockedLevel > 0 ? definition.thresholdForLevel(unlockedLevel) : 0,
                    color: isUnlocked ? currentRarity.color : Theme.accent.opacity(0.4)
                )

                // Show unlock date for latest level, or next goal
                if let nextThreshold, let hint = nextGoalHint(definition: definition, nextThreshold: nextThreshold) {
                    Text(hint)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Theme.textPrimary.opacity(secondaryOpacity))
                        .lineLimit(1)
                } else if isUnlocked, let date = achievementManager.unlockDate(for: definition.id) {
                    Text(date, format: .dateTime.month(.abbreviated).day().year())
                        .font(.system(size: 9, weight: isCompleted ? .semibold : .regular, design: .monospaced))
                        .foregroundStyle(Theme.textPrimary.opacity(secondaryOpacity))
                }
            }
        }
    }

    private func nextGoalHint(definition: AchievementDefinition, nextThreshold: Double) -> String? {
        let formatted: String
        switch definition.unit {
        case .count: formatted = "\(Int(nextThreshold))"
        case .hours: formatted = "\(Int(nextThreshold))h"
        case .minutes: formatted = "\(Int(nextThreshold))m"
        case .money:
            let sym = Theme.currencySymbol(for: UserDefaults.standard.string(forKey: "currency") ?? "USD")
            formatted = "\(sym)\(Int(nextThreshold))"
        case .days: formatted = "\(Int(nextThreshold))d"
        case .weeks: formatted = "\(Int(nextThreshold))w"
        case .sessions: formatted = "\(Int(nextThreshold))"
        }
        return "Next: \(formatted)"
    }

    // MARK: - Progress Bar

    private func progressBar(current: Double, nextThreshold: Double?, previousThreshold: Double, color: Color) -> some View {
        GeometryReader { geo in
            let next = nextThreshold ?? current
            let range = max(1, next - previousThreshold)
            let progress = min(1.0, max(0, (current - previousThreshold) / range))

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Theme.textPrimary.opacity(0.08))
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: max(2, geo.size.width * progress))
            }
        }
        .frame(height: 4)
    }

    // MARK: - Accessibility

    private func accessibilityLabel(
        definition: AchievementDefinition,
        unlockedLevel: Int,
        currentRarity: AchievementRarity,
        isSecret: Bool,
        isProLocked: Bool
    ) -> String {
        if isSecret { return "Classified achievement, locked" }
        let isUnlocked = unlockedLevel > 0
        if isProLocked {
            // Visually locked regardless of silent progress
            return "\(definition.name), requires Executive clearance"
        }
        if isUnlocked {
            if definition.totalLevels == 1 {
                return "\(definition.name), unlocked, \(currentRarity.label)"
            }
            return "\(definition.name), level \(unlockedLevel) of \(definition.totalLevels), \(currentRarity.label)"
        }
        return "\(definition.name), locked"
    }
}

// MARK: - Unlock Banner

struct AchievementUnlockBanner: View {
    let event: AchievementUnlockEvent
    var onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(event.definition.emoji)
                .font(.system(size: 28))

            VStack(alignment: .leading, spacing: 4) {
                Text(event.rarity.label)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(event.rarity.color)
                    .tracking(0.5)

                Text(event.definition.totalLevels > 1 ? "\(event.definition.name) — Level \(event.level)" : event.definition.name)
                    .font(.system(.subheadline, design: .monospaced, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(2)

                Text(event.definition.flavor)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.65))
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
                .stroke(event.rarity.color.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 24)
        .transition(.move(edge: .top).combined(with: .opacity))
        .onTapGesture {
            onDismiss()
        }
    }
}

// MARK: - Previews

#Preview("Unlock Banners — All Rarities") {
    let sampleEvents: [AchievementUnlockEvent] = [
        AchievementUnlockEvent(
            definition: AchievementCatalog.all.first { $0.id == "orientation_complete" }!,
            level: 1,
            rarity: .common
        ),
        AchievementUnlockEvent(
            definition: AchievementCatalog.all.first { $0.id == "perfect_attendance" }!,
            level: 2,
            rarity: .common
        ),
        AchievementUnlockEvent(
            definition: AchievementCatalog.all.first { $0.id == "early_bird_deviation" }!,
            level: 2,
            rarity: .uncommon
        ),
        AchievementUnlockEvent(
            definition: AchievementCatalog.all.first { $0.id == "deep_focus" }!,
            level: 3,
            rarity: .rare
        ),
        AchievementUnlockEvent(
            definition: AchievementCatalog.all.first { $0.id == "budget_variance" }!,
            level: 4,
            rarity: .elite
        ),
        AchievementUnlockEvent(
            definition: AchievementCatalog.all.first { $0.id == "perfect_attendance" }!,
            level: 6,
            rarity: .legendary
        ),
        AchievementUnlockEvent(
            definition: AchievementCatalog.all.first { $0.id == "after_hours" }!,
            level: 1,
            rarity: .rare
        ),
    ]

    return ScrollView {
        VStack(spacing: 16) {
            ForEach(sampleEvents) { event in
                AchievementUnlockBanner(event: event, onDismiss: {})
            }
        }
        .padding(.vertical, 40)
    }
    .background(Color.white)
}

#Preview("Unlock Banner — Single") {
    AchievementUnlockBanner(
        event: AchievementUnlockEvent(
            definition: AchievementCatalog.all.first { $0.id == "budget_variance" }!,
            level: 4,
            rarity: .elite
        ),
        onDismiss: {}
    )
    .padding(.vertical, 60)
}
