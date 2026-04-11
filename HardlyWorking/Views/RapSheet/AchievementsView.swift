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

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("COMMENDATIONS")
                    .font(.system(.caption2, design: .monospaced, weight: .bold))
                    .foregroundStyle(Theme.textPrimary.opacity(0.3))
                    .tracking(1.5)

                Spacer()

                Text("\(achievementManager.totalUnlocked())/\(AchievementCatalog.totalUnlockMoments)")
                    .font(.system(.caption2, design: .monospaced, weight: .medium))
                    .foregroundStyle(Theme.textPrimary.opacity(0.4))
            }

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(AchievementCatalog.all) { definition in
                    achievementCard(definition)
                }
            }
        }
        .sheet(isPresented: $showPaywall, onDismiss: {
            subscriptionManager.showProBannerIfPending()
        }) {
            PaywallView()
                .presentationDragIndicator(.visible)
        }
    }

    private func achievementCard(_ definition: AchievementDefinition) -> some View {
        let unlockedLevel = achievementManager.unlockedLevel(for: definition.id)
        let isUnlocked = unlockedLevel > 0
        let isSecret = definition.isSecret && !isUnlocked
        let isProLocked = definition.isProOnly && !isProUser
        let progressValue = definition.checker(allEntries.filter { !$0.isRunning }, hourlyRate)
        let currentRarity = isUnlocked ? definition.rarityForLevel(unlockedLevel) : .common

        return Button {
            if isProLocked {
                Haptics.light()
                showPaywall = true
            }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                // Emoji
                Text(isSecret ? "\u{1F50F}" : definition.emoji)
                    .font(.system(size: 28))
                    .opacity(isProLocked ? 0.15 : (isUnlocked ? 1 : 0.3))

                // Name
                if isProLocked && !isSecret {
                    Text(definition.name)
                        .font(.system(.caption, design: .monospaced, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary.opacity(0.4))
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                } else {
                    Text(isSecret ? "???" : definition.name)
                        .font(.system(.caption, design: .monospaced, weight: .semibold))
                        .foregroundStyle(isUnlocked ? Theme.textPrimary : Theme.textPrimary.opacity(0.3))
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }

                // Status / Progress
                if isProLocked {
                    Text("CLASSIFIED")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.timer.opacity(0.5))
                        .tracking(1)
                } else if isSecret {
                    Text("Classified. Unlock to reveal.")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(Theme.textPrimary.opacity(0.35))
                } else if definition.totalLevels == 1 {
                    if isUnlocked {
                        if let date = achievementManager.unlockDate(for: definition.id) {
                            Text(date, format: .dateTime.month(.abbreviated).day().year())
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(Theme.textPrimary.opacity(0.4))
                        }
                    } else {
                        Text("\u{1F512} Locked")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(Theme.textPrimary.opacity(0.35))
                    }
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Level \(unlockedLevel) of \(definition.totalLevels)")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(Theme.textPrimary.opacity(0.4))

                        progressBar(
                            current: progressValue,
                            nextThreshold: definition.nextThreshold(after: progressValue),
                            previousThreshold: unlockedLevel > 0 ? definition.thresholdForLevel(unlockedLevel) : 0,
                            color: isUnlocked ? currentRarity.color : Theme.textPrimary.opacity(0.1)
                        )
                    }
                }

                // Rarity badge
                if isUnlocked {
                    Text(currentRarity.label)
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(currentRarity.color)
                        .tracking(0.5)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isProLocked ? Theme.cardBackground.opacity(0.15) : (isUnlocked ? Theme.cardBackground.opacity(0.6) : Theme.cardBackground.opacity(0.25)))
                    .stroke(
                        isProLocked ? Theme.timer.opacity(0.06) : (isUnlocked ? currentRarity.color.opacity(0.15) : Theme.textPrimary.opacity(0.04)),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(!isProLocked) // Only tappable if Pro-locked (to show paywall)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isProLocked ? "\(definition.name), classified, requires Pro" : (isUnlocked ? "\(definition.name), level \(unlockedLevel) of \(definition.totalLevels), \(currentRarity.label)" : "\(definition.name), locked"))
    }

    private func progressBar(current: Double, nextThreshold: Double?, previousThreshold: Double, color: Color) -> some View {
        GeometryReader { geo in
            let next = nextThreshold ?? current
            let range = max(1, next - previousThreshold)
            let progress = min(1.0, max(0, (current - previousThreshold) / range))

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Theme.textPrimary.opacity(0.06))
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: max(2, geo.size.width * progress))
            }
        }
        .frame(height: 4)
    }
}

struct AchievementUnlockBanner: View {
    let event: AchievementUnlockEvent
    var onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Text(event.definition.emoji)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(event.definition.name) Level \(event.level)")
                    .font(.system(.caption, design: .monospaced, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)

                Text(event.rarity.label)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(event.rarity.color)
                    .tracking(0.5)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
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
