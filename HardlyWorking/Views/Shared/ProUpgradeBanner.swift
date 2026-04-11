import SwiftUI

struct ProUpgradeBanner: View {
    var onDismiss: () -> Void

    @State private var autoDismissTask: Task<Void, Never>?

    var body: some View {
        HStack(spacing: 10) {
            Text("\u{1F4CB}")
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text("AUTHORIZATION GRANTED")
                    .font(.system(.caption, design: .monospaced, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)

                Text("All departments now accessible.")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(Theme.money)
                    .tracking(0.5)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
                .stroke(Theme.money.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 24)
        .transition(.move(edge: .top).combined(with: .opacity))
        .onTapGesture {
            dismiss()
        }
        .onAppear {
            Haptics.success()
            autoDismissTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(4.0))
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
