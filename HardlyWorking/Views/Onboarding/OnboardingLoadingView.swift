import SwiftUI

struct OnboardingLoadingView: View {
    var onComplete: () -> Void

    @State private var completedSteps: Int = 0
    @State private var currentStep: Int = 0
    @State private var isProfileComplete = false

    private let steps = [
        "Verifying compensation data...",
        "Cross-referencing schedule...",
        "Analyzing industry benchmarks...",
        "Calibrating reclamation engine...",
        "Generating personalized insights...",
    ]

    private let stepTimings: [Double] = [0.0, 0.8, 1.8, 3.0, 4.2]
    private let stepDurations: [Double] = [0.8, 1.0, 1.2, 1.2, 1.0]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image("mascot_loading")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 200)

            Spacer().frame(height: 24)

            Text("Compiling your dossier...")
                .font(.system(size: 24, weight: .light, design: .monospaced))
                .foregroundStyle(Theme.textPrimary)

            Spacer().frame(height: 32)

            VStack(alignment: .leading, spacing: 16) {
                ForEach(0..<steps.count, id: \.self) { index in
                    if index <= currentStep {
                        stepRow(index: index)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }

                if isProfileComplete {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(.body, weight: .bold))
                            .foregroundStyle(Theme.money)
                        Text("Dossier complete.")
                            .font(.system(.subheadline, design: .monospaced, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 40)

            Spacer()
        }
        .onAppear { startSequence() }
    }

    private func stepRow(index: Int) -> some View {
        HStack(spacing: 10) {
            if index < completedSteps {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(.body, weight: .medium))
                    .foregroundStyle(Theme.money)
            } else {
                ProgressView()
                    .scaleEffect(0.8)
            }

            Text(steps[index])
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(
                    index < completedSteps
                        ? Theme.textPrimary.opacity(0.4)
                        : Theme.textPrimary.opacity(0.7)
                )
        }
    }

    private func startSequence() {
        for i in 0..<steps.count {
            // Show step
            DispatchQueue.main.asyncAfter(deadline: .now() + stepTimings[i]) {
                withAnimation(.easeOut(duration: 0.3)) {
                    currentStep = i
                }
            }

            // Complete step
            DispatchQueue.main.asyncAfter(deadline: .now() + stepTimings[i] + stepDurations[i]) {
                withAnimation(.easeOut(duration: 0.2)) {
                    completedSteps = i + 1
                }
            }
        }

        // Profile complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.2) {
            withAnimation(.easeOut(duration: 0.3)) {
                isProfileComplete = true
            }
            Haptics.success()
        }

        // Auto-advance to paywall
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
            onComplete()
        }
    }
}
