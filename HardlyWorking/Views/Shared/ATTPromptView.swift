import AppTrackingTransparency
import SwiftUI

struct ATTPromptView: View {
    @AppStorage("hasSeenATTPrompt") private var hasSeenATTPrompt = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image("mascot_welcome")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 200)

            Spacer().frame(height: 24)

            Text("COMPLIANCE NOTICE")
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.3))
                .tracking(1.5)

            Spacer().frame(height: 20)

            Text("A mandatory disclosure from the\nDepartment of Data Transparency,\nper directive of J. Pemberton, CSO.")
                .font(.system(.subheadline, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(0.5))
                .multilineTextAlignment(.center)

            Spacer().frame(height: 24)

            VStack(spacing: 0) {
                Rectangle()
                    .fill(Theme.textPrimary.opacity(0.06))
                    .frame(height: 1)

                Text("Hardly Working Corp. uses an anonymous\nidentifier to determine which recruitment\ncampaign led to your application. This data\nis used for attribution purposes only and\nis never shared with your other employer.")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 20)
                    .padding(.horizontal, 24)

                Rectangle()
                    .fill(Theme.textPrimary.opacity(0.06))
                    .frame(height: 1)
            }
            .padding(.horizontal, 24)

            Spacer().frame(height: 12)

            Text("Participation is voluntary.\nNon-participation will not affect your standing.")
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(0.25))

            Spacer()

            VStack(spacing: 12) {
                Button {
                    Haptics.medium()
                    requestATT()
                } label: {
                    Text("Authorize")
                        .font(.system(.headline, design: .monospaced))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14))
                }

                Button {
                    Haptics.light()
                    hasSeenATTPrompt = true
                } label: {
                    Text("Decline")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(Theme.textPrimary.opacity(0.3))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(Color.white)
    }

    private func requestATT() {
        ATTrackingManager.requestTrackingAuthorization { _ in
            DispatchQueue.main.async {
                hasSeenATTPrompt = true
            }
        }
    }
}
