import AppTrackingTransparency
import SwiftUI

struct ATTPromptView: View {
    @AppStorage("hasSeenATTPrompt") private var hasSeenATTPrompt = false

    @State private var showMascot = false
    @State private var showBubble = false
    @State private var showContent = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack(alignment: .top) {
                Image("mascot_welcome")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 200)
                    .padding(.top, 44)

                if showBubble {
                    Text("We keep everything\nsecret here.")
                        .font(.system(.caption, design: .monospaced, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background {
                            ATTBubbleShape(tailOffset: -20)
                                .fill(.white)
                                .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
                        }
                        .background {
                            ATTBubbleShape(tailOffset: -20)
                                .stroke(Theme.textPrimary.opacity(0.12), lineWidth: 1)
                        }
                        .offset(x: 60)
                        .transition(.scale(scale: 0, anchor: .bottom).combined(with: .opacity))
                }
            }
            .offset(y: showMascot ? 0 : 30)
            .opacity(showMascot ? 1 : 0)

            Spacer().frame(height: 24)

            Group {
                Text("COMPLIANCE NOTICE")
                    .font(.system(.caption2, design: .monospaced, weight: .bold))
                    .foregroundStyle(Theme.textPrimary.opacity(0.45))
                    .tracking(1.5)

                Spacer().frame(height: 16)

                Text("A mandatory disclosure from the\nDepartment of Data Transparency,\nper directive of J. Pemberton, CSO.")
                    .font(.system(.subheadline, design: .monospaced, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary.opacity(0.6))
                    .multilineTextAlignment(.center)

                Spacer().frame(height: 20)

                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Theme.textPrimary.opacity(0.08))
                        .frame(height: 1)

                    Text("Hardly Working Corp. uses an anonymous identifier to determine which recruitment campaign led to your application.\n\nThis data is used for attribution purposes only and is never shared with your other employer.")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(Theme.textPrimary.opacity(0.55))
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 20)
                        .padding(.horizontal, 24)

                    Rectangle()
                        .fill(Theme.textPrimary.opacity(0.08))
                        .frame(height: 1)
                }
                .padding(.horizontal, 24)

                Spacer().frame(height: 12)

                Text("Participation is voluntary.\nNon-participation will not affect your standing.")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.4))
                    .multilineTextAlignment(.center)
            }
            .opacity(showContent ? 1 : 0)

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
                        .foregroundStyle(Theme.textPrimary.opacity(0.4))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(Color.white)
        .onAppear { startSequence() }
    }

    private func startSequence() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            showMascot = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { showBubble = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeOut(duration: 0.4)) { showContent = true }
        }
    }

    private func requestATT() {
        ATTrackingManager.requestTrackingAuthorization { _ in
            DispatchQueue.main.async {
                hasSeenATTPrompt = true
            }
        }
    }
}

// MARK: - Bubble Shape

private struct ATTBubbleShape: Shape {
    var tailOffset: CGFloat = 0
    var cornerRadius: CGFloat = 10
    var tailWidth: CGFloat = 12
    var tailHeight: CGFloat = 8

    func path(in rect: CGRect) -> Path {
        let r = cornerRadius
        let tailCenterX = rect.midX + tailOffset
        let tailLeft = tailCenterX - tailWidth / 2
        let tailRight = tailCenterX + tailWidth / 2

        var p = Path()
        p.move(to: CGPoint(x: rect.minX + r, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
        p.addArc(center: CGPoint(x: rect.maxX - r, y: rect.minY + r),
                 radius: r, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
        p.addArc(center: CGPoint(x: rect.maxX - r, y: rect.maxY - r),
                 radius: r, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        p.addLine(to: CGPoint(x: tailRight, y: rect.maxY))
        p.addLine(to: CGPoint(x: tailCenterX, y: rect.maxY + tailHeight))
        p.addLine(to: CGPoint(x: tailLeft, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX + r, y: rect.maxY))
        p.addArc(center: CGPoint(x: rect.minX + r, y: rect.maxY - r),
                 radius: r, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
        p.addArc(center: CGPoint(x: rect.minX + r, y: rect.minY + r),
                 radius: r, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        p.closeSubpath()
        return p
    }
}
