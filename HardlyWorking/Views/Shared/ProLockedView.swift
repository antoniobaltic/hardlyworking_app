import SwiftUI

/// Reusable locked section placeholder for Pro-gated features.
/// Shows a lock icon, section description, and contextual upgrade CTA.
struct ProLockedView: View {
    let title: String
    let description: String
    let icon: String
    var onUpgrade: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundStyle(Theme.accent.opacity(0.3))

                Text(title)
                    .font(.system(.subheadline, design: .monospaced, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary.opacity(0.5))

                Text(description)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.3))
                    .multilineTextAlignment(.center)
            }

            Button {
                Haptics.light()
                onUpgrade()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "lock.fill")
                        .font(.system(.caption, weight: .bold))
                    Text("Request Clearance")
                        .font(.system(.caption, design: .monospaced, weight: .semibold))
                }
                .foregroundStyle(Theme.accent)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .stroke(Theme.accent, lineWidth: 1)
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.cardBackground.opacity(0.3))
                .stroke(Theme.textPrimary.opacity(0.04), lineWidth: 1)
        )
    }
}
