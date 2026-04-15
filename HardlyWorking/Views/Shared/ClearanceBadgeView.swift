    import SwiftUI

enum ClearanceBadgeSize {
    case large
    case medium
    case compact
}

struct ClearanceBadgeView: View {
    let level: ClearanceLevel
    var size: ClearanceBadgeSize = .large
    var showDescription: Bool = false

    var body: some View {
        switch size {
        case .large: largeBadge
        case .medium: mediumBadge
        case .compact: compactBadge
        }
    }

    // MARK: - Large Badge (Onboarding)

    private var largeBadge: some View {
        VStack(spacing: 0) {
            // Top row: corp name + chip
            HStack {
                Text("HARDLY WORKING CORP.")
                    .font(.system(size: 7, weight: .bold, design: .monospaced))
                    .foregroundStyle(level.textColor.opacity(0.5))
                    .tracking(1.5)
                Spacer()
                chipDecoration
            }

            Spacer()

            // Center: level + title
            VStack(spacing: 8) {
                Text("CLEARANCE LEVEL \(level.rawValue)")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(level.textColor.opacity(0.7))
                    .tracking(2)

                Text(level.title)
                    .font(.system(size: 26, weight: .light, design: .monospaced))
                    .foregroundStyle(level.textColor)
                    .multilineTextAlignment(.center)

                if showDescription {
                    Text(level.description)
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .foregroundStyle(level.secondaryTextColor)
                        .multilineTextAlignment(.center)
                        .padding(.top, 2)
                }
            }

            Spacer()

            // Bottom row: card number + barcode
            HStack(alignment: .bottom) {
                Text("NO. \(String(format: "%04d", level.rawValue * 1337))")
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .foregroundStyle(level.textColor.opacity(0.3))
                Spacer()
                barcodeDecoration
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .frame(height: 220)
        .background {
            cardBackground
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(level.borderColor, lineWidth: 1)
        }
        .shadow(color: level.color.opacity(0.3), radius: 12, y: 6)
    }

    // MARK: - Medium Badge (Profile)

    private var mediumBadge: some View {
        HStack(spacing: 16) {
            // Level number
            Text("LVL\n\(level.rawValue)")
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundStyle(level.textColor.opacity(0.8))
                .multilineTextAlignment(.center)
                .frame(width: 44)

            // Divider line
            Rectangle()
                .fill(level.textColor.opacity(0.15))
                .frame(width: 1)

            // Title + corp
            VStack(alignment: .leading, spacing: 4) {
                Text(level.title)
                    .font(.system(.subheadline, design: .monospaced, weight: .medium))
                    .foregroundStyle(level.textColor)

                Text("HARDLY WORKING CORP.")
                    .font(.system(size: 7, weight: .bold, design: .monospaced))
                    .foregroundStyle(level.textColor.opacity(0.4))
                    .tracking(1.5)
            }

            Spacer()

            chipDecoration
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .background {
            cardBackground
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(level.borderColor, lineWidth: 1)
        }
        .shadow(color: level.color.opacity(0.2), radius: 8, y: 4)
    }

    // MARK: - Compact Badge (Leaderboard)

    private var compactBadge: some View {
        Text(level.title)
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .foregroundStyle(level.textColor)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(level.color, in: Capsule())
    }

    // MARK: - Shared Components

    private var cardBackground: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: level.gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Diagonal sheen
            LinearGradient(
                colors: [
                    .clear,
                    level.sheenColor,
                    level.sheenColor,
                    .clear
                ],
                startPoint: UnitPoint(x: -0.3, y: 0.5),
                endPoint: UnitPoint(x: 1.3, y: 0.5)
            )
            .rotationEffect(.degrees(-25))
        }
    }

    private var chipDecoration: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(level.textColor.opacity(0.15))
            .frame(width: 22, height: 16)
            .overlay {
                VStack(spacing: 2.5) {
                    Rectangle().fill(level.textColor.opacity(0.12)).frame(height: 0.5)
                    Rectangle().fill(level.textColor.opacity(0.12)).frame(height: 0.5)
                    Rectangle().fill(level.textColor.opacity(0.12)).frame(height: 0.5)
                }
                .padding(.horizontal, 3)
            }
    }

    private var barcodeDecoration: some View {
        HStack(spacing: 1.5) {
            ForEach(0..<12, id: \.self) { i in
                Rectangle()
                    .fill(level.textColor.opacity(0.2))
                    .frame(width: i.isMultiple(of: 3) ? 2 : 1, height: 14)
            }
        }
    }
}

// MARK: - Previews

#Preview("All Levels — Large") {
    ScrollView {
        VStack(spacing: 20) {
            ForEach(ClearanceLevel.allCases, id: \.rawValue) { level in
                ClearanceBadgeView(level: level, size: .large, showDescription: true)
            }
        }
        .padding(24)
    }
}

#Preview("All Levels — Medium") {
    VStack(spacing: 16) {
        ForEach(ClearanceLevel.allCases, id: \.rawValue) { level in
            ClearanceBadgeView(level: level, size: .medium)
        }
    }
    .padding(24)
}

#Preview("All Levels — Compact") {
    HStack(spacing: 8) {
        ForEach(ClearanceLevel.allCases, id: \.rawValue) { level in
            ClearanceBadgeView(level: level, size: .compact)
        }
    }
    .padding(24)
}
