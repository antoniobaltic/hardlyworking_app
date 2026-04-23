import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

struct HardlyWorkingActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: HardlyWorkingActivityAttributes.self) { context in
            LockScreenCard(state: context.state)
                .activityBackgroundTint(Color.white)
                .activitySystemActionForegroundColor(Theme.textPrimary)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Text(context.state.categoryEmoji)
                            .font(.title3)
                        // `.callout` + 0.5 minimumScaleFactor — sized for the
                        // worst case ("ONLINE SHOPPING", 15 chars) to avoid the
                        // mid-word truncation that larger fonts caused.
                        Text(context.state.categoryName.uppercased())
                            .font(.system(.callout, design: .monospaced, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                    .padding(.leading, 8)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.startDate, style: .timer)
                        .font(.system(.title3, design: .monospaced, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(Theme.reclaimedGreen)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .multilineTextAlignment(.trailing)
                        .padding(.trailing, 8)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 10) {
                        HStack(spacing: 6) {
                            ForEach(context.state.substitutes, id: \.name) { code in
                                SubstituteChip(code: code, darkBackground: true)
                            }
                            ForEach(0..<max(0, 3 - context.state.substitutes.count), id: \.self) { _ in
                                Color.clear.frame(maxWidth: .infinity, minHeight: 34)
                            }
                        }

                        Button(intent: EndSessionIntent()) {
                            Text("END ACTIVITY")
                                .font(.system(.caption, design: .monospaced, weight: .bold))
                                .foregroundStyle(.white)
                                .tracking(1.5)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Theme.bloodRed, in: RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 4)
                    .padding(.bottom, 2)
                }
            } compactLeading: {
                // Leading padding pushes the emoji inward, toward the sensor
                // housing, so it sits near the pill's centre rather than hugging
                // its outer-left corner. Larger value since emoji is narrow.
                Text(context.state.categoryEmoji)
                    .padding(.leading, 40)
            } compactTrailing: {
                // Smaller trailing padding to leave room for the timer text
                // (up to ~8 chars for "10:51:14"-style durations) without
                // truncation. Still visibly pushed away from the outer-right
                // corner so the content feels centred.
                Text(context.state.startDate, style: .timer)
                    .font(.system(.caption, design: .monospaced, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(Theme.reclaimedGreen)
                    .lineLimit(1)
                    .padding(.trailing, 12)
            } minimal: {
                Circle()
                    .fill(Theme.reclaimedGreen)
                    .frame(width: 10, height: 10)
            }
            .keylineTint(Theme.reclaimedGreen)
        }
    }
}

// MARK: - Lock Screen Card

private struct LockScreenCard: View {
    let state: HardlyWorkingActivityAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerRow
            sessionRow
            actionsRow
        }
        // Generous vertical padding — iOS applies a ~22pt corner radius to
        // the Lock Screen activity card; content within 18pt of any edge
        // starts getting eaten by the curve.
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
    }

    private var headerRow: some View {
        HStack(spacing: 6) {
            Circle().fill(Theme.reclaimedGreen).frame(width: 6, height: 6)
            Text("SESSION IN PROGRESS")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(0.6))
                .tracking(1.4)
                .lineLimit(1)
            Spacer(minLength: 8)
            Text("HARDLY WORKING CORP.")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(0.35))
                .tracking(1.1)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    private var sessionRow: some View {
        HStack(alignment: .center, spacing: 14) {
            Image("app_icon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(state.categoryEmoji)
                        .font(.caption)
                    Text(state.categoryName.uppercased())
                        .font(.system(.caption, design: .monospaced, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                        .tracking(0.8)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                Text(state.startDate, style: .timer)
                    .font(.system(size: 28, weight: .light, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Spacer(minLength: 0)
        }
    }

    private var actionsRow: some View {
        HStack(spacing: 6) {
            ForEach(state.substitutes, id: \.name) { code in
                SubstituteChip(code: code, darkBackground: false)
            }
            ForEach(0..<max(0, 3 - state.substitutes.count), id: \.self) { _ in
                Color.clear.frame(maxWidth: .infinity, minHeight: 34)
            }
            Button(intent: EndSessionIntent()) {
                Text("END")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .tracking(1.5)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Theme.bloodRed, in: RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Substitute Chip

private struct SubstituteChip: View {
    let code: SubstituteCode
    var darkBackground: Bool = false

    var body: some View {
        Button(intent: SwitchActivityIntent(categoryName: code.name, categoryEmoji: code.emoji)) {
            HStack(spacing: 3) {
                Text(code.emoji).font(.caption)
                Text(code.shortLabel)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(darkBackground ? Color.white : Theme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(
                (darkBackground ? Color.white.opacity(0.12) : Theme.cardBackground),
                in: RoundedRectangle(cornerRadius: 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(
                        (darkBackground ? Color.white.opacity(0.18) : Theme.textPrimary.opacity(0.1)),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
