import SwiftUI

struct OnboardingHonestyView: View {
    @Binding var estimatedProductivity: Int

    @State private var showMascot = false
    @State private var showBubble = false
    @State private var dialogueStage = 0
    @State private var showReplyButton = false
    @State private var replyPulse = false
    @State private var showTitle = false
    @State private var showSubtitle = false
    @State private var showPercentage = false
    @State private var showSlider = false
    @State private var showCommentary = false

    private var commentary: String {
        switch estimatedProductivity {
        case 0...20: "No one believes you."
        case 21...40: "Suspiciously low. Are you including 'looking busy'?"
        case 41...60: "Statistically unremarkable. The best kind."
        case 61...80: "Consistent with our findings."
        default: "Management material."
        }
    }

    private var bubbleText: String {
        switch dialogueStage {
        case 1: "Agreed."
        default: "Do not worry. We will not\nshare this with anyone."
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer().frame(height: 20)

                ZStack(alignment: .top) {
                    Image("mascot_honest")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 200)
                        .padding(.top, 56)

                    if showBubble {
                        speechBubble
                            .offset(x: 60)
                            .transition(.scale(scale: 0, anchor: .bottom).combined(with: .opacity))
                    }

                    if showReplyButton {
                        replyButton
                            .scaleEffect(replyPulse ? 1.08 : 1.0)
                            .offset(x: 110, y: 72)
                            .transition(.scale(scale: 0, anchor: .topLeading).combined(with: .opacity))
                    }
                }
                .offset(y: showMascot ? 0 : 30)
                .opacity(showMascot ? 1 : 0)

                Spacer().frame(height: 24)

                Text("Confidential\nself-assessment!")
                    .font(.system(size: 24, weight: .light, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .opacity(showTitle ? 1 : 0)
                    .offset(y: showTitle ? 0 : 10)

                Spacer().frame(height: 12)

                Text("Estimate the percentage of your\nworkday spent NOT working.")
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .opacity(showSubtitle ? 1 : 0)

                Spacer().frame(height: 20)

                Text("\(estimatedProductivity)%")
                    .font(.system(size: 38, weight: .ultraLight, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.15), value: estimatedProductivity)
                    .scaleEffect(showPercentage ? 1 : 0.5)
                    .opacity(showPercentage ? 1 : 0)

                Spacer().frame(height: 20)

                Slider(
                    value: Binding(
                        get: { Double(estimatedProductivity) },
                        set: { estimatedProductivity = Int($0) }
                    ),
                    in: 0...100,
                    step: 5
                )
                .tint(Theme.accent)
                .padding(.horizontal, 32)
                .onChange(of: estimatedProductivity) {
                    Haptics.selection()
                }
                .opacity(showSlider ? 1 : 0)

                HStack {
                    Text("0%")
                    Spacer()
                    Text("100%")
                }
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(0.35))
                .padding(.horizontal, 32)
                .opacity(showSlider ? 1 : 0)

                Spacer().frame(height: 20)

                Text(commentary)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .animation(.easeInOut(duration: 0.2), value: commentary)
                    .opacity(showCommentary ? 1 : 0)
            }
            .padding(.horizontal, 24)
        }
        .scrollIndicators(.hidden)
        .onAppear { startSequence() }
    }

    // MARK: - Speech Bubble

    private var speechBubble: some View {
        Text(bubbleText)
            .font(.system(.caption, design: .monospaced, weight: .medium))
            .foregroundStyle(Theme.textPrimary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background {
                HonestyBubbleShape(tailOffset: -20)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
            }
            .background {
                HonestyBubbleShape(tailOffset: -20)
                    .stroke(Theme.textPrimary.opacity(0.12), lineWidth: 1)
            }
            .animation(.easeInOut(duration: 0.3), value: dialogueStage)
    }

    // MARK: - Reply Button

    private var replyButton: some View {
        Button {
            Haptics.light()

            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showReplyButton = false
                replyPulse = false
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    dialogueStage = 1
                }
            }
        } label: {
            Text("Good.")
                .font(.system(.caption, design: .monospaced, weight: .medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Theme.accent)
                        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
                }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Animation

    private func startSequence() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            showMascot = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { showBubble = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { showReplyButton = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    replyPulse = true
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeOut(duration: 0.4)) { showTitle = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 0.3)) { showSubtitle = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { showPercentage = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeOut(duration: 0.4)) { showSlider = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation(.easeOut(duration: 0.3)) { showCommentary = true }
        }
    }
}

// MARK: - Bubble Shape

private struct HonestyBubbleShape: Shape {
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
