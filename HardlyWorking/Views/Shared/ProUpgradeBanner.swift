import SwiftUI

struct ProUpgradeBanner: View {
    var onDismiss: () -> Void

    @State private var autoDismissTask: Task<Void, Never>?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\u{1F3C6}")
                .font(.system(size: 28))

            VStack(alignment: .leading, spacing: 4) {
                Text("EXECUTIVE")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.accent)
                    .tracking(0.5)

                Text("PROMOTION GRANTED")
                    .font(.system(.subheadline, design: .monospaced, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(2)

                Text("Executive Status confirmed. Congratulations.")
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
                .stroke(Theme.accent.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 24)
        .transition(.move(edge: .top).combined(with: .opacity))
        .onTapGesture {
            dismiss()
        }
        .onAppear {
            Haptics.success()
            autoDismissTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(5.5))
                guard !Task.isCancelled else { return }
                dismiss()
            }
        }
        .onDisappear {
            autoDismissTask?.cancel()
        }
    }

    private func dismiss() {
        autoDismissTask?.cancel()
        withAnimation(.easeOut(duration: 0.3)) {
            onDismiss()
        }
    }
}

// MARK: - Preview

#Preview("Pro Upgrade Banner") {
    VStack {
        ProUpgradeBanner(onDismiss: {})
            .padding(.top, 40)
        Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.white)
}
