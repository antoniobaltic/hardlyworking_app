import SwiftUI

struct OnboardingWelcomeView: View {
    @State private var showMascot = false
    @State private var showTitle = false
    @State private var showTagline = false
    @State private var taglineText = ""
    @State private var showSubtitle = false
    @State private var showFooter = false
    @State private var showBubble = false
    @State private var dialogueStage = 0  // 0: initial, 1: after "Me too!", 2: after "You are?"
    @State private var showReplyButton = false
    @State private var replyPulse = false

    private let fullTagline = "TIME RECLAMATION SOLUTIONS"

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Mascot + speech bubble + "Me too!" reply
            ZStack(alignment: .top) {
                Image("mascot_welcome")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 220)
                    .padding(.top, 56)

                // John D.'s speech bubble
                if showBubble {
                    speechBubble
                        .offset(x: 60)
                        .transition(.scale(scale: 0, anchor: .bottom).combined(with: .opacity))
                }

                // Reply button
                if showReplyButton {
                    replyButton
                        .scaleEffect(replyPulse ? 1.08 : 1.0)
                        .offset(x: 110, y: 72)
                        .transition(.scale(scale: 0, anchor: .topLeading).combined(with: .opacity))
                }
            }
            .offset(y: showMascot ? 0 : 40)
            .opacity(showMascot ? 1 : 0)

            Spacer().frame(height: 24)

            // Title
            Text("Welcome to\nHardly Working Corp.")
                .font(.system(size: 24, weight: .light, design: .monospaced))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
                .opacity(showTitle ? 1 : 0)
                .offset(y: showTitle ? 0 : 10)

            Spacer().frame(height: 6)

            // Tagline (typewriter)
            Text(taglineText)
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundStyle(Theme.accent.opacity(0.5))
                .tracking(2)
                .frame(height: 16)

            Spacer().frame(height: 20)

            // Subtitle
            Text("Your orientation will be conducted\nby John D., Employee Relations Officer.")
                .font(.system(.subheadline, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(0.5))
                .multilineTextAlignment(.center)
                .opacity(showSubtitle ? 1 : 0)
                .offset(y: showSubtitle ? 0 : 8)

            Spacer()

            // Footer
            Text("By order of J. Pemberton, CSO.\nAll new hires must complete orientation.")
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.bottom, 16)
                .opacity(showFooter ? 1 : 0)
        }
        .padding(.horizontal, 24)
        .onAppear { startSequence() }
    }

    private func startSequence() {
        // Step 1: Mascot slides up (0.0s)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            showMascot = true
        }

        // Step 2: Speech bubble pops in (0.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                showBubble = true
            }
        }

        // Step 3: Reply button pops in (0.9s), then pulses
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                showReplyButton = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    replyPulse = true
                }
            }
        }

        // Step 4: Title fades in (1.1s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            withAnimation(.easeOut(duration: 0.4)) {
                showTitle = true
            }
        }

        // Step 5: Tagline types out (1.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            typeTagline()
        }

        // Step 6: Subtitle fades in (2.2s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(.easeOut(duration: 0.4)) {
                showSubtitle = true
            }
        }

        // Step 7: Footer (2.6s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
            withAnimation(.easeOut(duration: 0.3)) {
                showFooter = true
            }
        }

        // Step 8: Button pulse starts at 3.4s, repeats every 3s
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.4) {
            startPulseLoop()
        }
    }

    private var bubbleText: String {
        switch dialogueStage {
        case 1: "Haha, yeah I bet.\nWe're all delighted here."
        case 2: "Yes. Definitely.\nNow please begin orientation."
        default: "I'm so delighted\nyou're here."
        }
    }

    private var replyButtonText: String {
        switch dialogueStage {
        case 0: "Me too!"
        case 1: "You are?"
        default: ""
        }
    }

    private var speechBubble: some View {
        Text(bubbleText)
            .font(.system(.caption, design: .monospaced, weight: .medium))
            .foregroundStyle(Theme.textPrimary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background {
                BubbleShape(tailOffset: -20)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
            }
            .background {
                BubbleShape(tailOffset: -20)
                    .stroke(Theme.textPrimary.opacity(0.12), lineWidth: 1)
            }
            .animation(.easeInOut(duration: 0.3), value: dialogueStage)
    }

    private var replyButton: some View {
        Button {
            Haptics.light()
            let nextStage = dialogueStage + 1

            // Hide button first
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showReplyButton = false
                replyPulse = false
            }

            // Update John D.'s response
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    dialogueStage = nextStage
                }

                // Show next reply button if there is one
                if nextStage < 2 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                            showReplyButton = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                                replyPulse = true
                            }
                        }
                    }
                }
            }
        } label: {
            Text(replyButtonText)
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

    private func startPulseLoop() {
        NotificationCenter.default.post(name: .onboardingButtonPulse, object: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            startPulseLoop()
        }
    }

    private func typeTagline() {
        for (index, char) in fullTagline.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.025) {
                taglineText.append(char)
            }
        }
    }
}

private struct BubbleShape: Shape {
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

        // Start at top-left after corner
        p.move(to: CGPoint(x: rect.minX + r, y: rect.minY))

        // Top edge
        p.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
        // Top-right corner
        p.addArc(center: CGPoint(x: rect.maxX - r, y: rect.minY + r),
                 radius: r, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        // Right edge
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
        // Bottom-right corner
        p.addArc(center: CGPoint(x: rect.maxX - r, y: rect.maxY - r),
                 radius: r, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)

        // Bottom edge — with tail cutout
        p.addLine(to: CGPoint(x: tailRight, y: rect.maxY))
        p.addLine(to: CGPoint(x: tailCenterX, y: rect.maxY + tailHeight))
        p.addLine(to: CGPoint(x: tailLeft, y: rect.maxY))

        // Continue bottom edge
        p.addLine(to: CGPoint(x: rect.minX + r, y: rect.maxY))
        // Bottom-left corner
        p.addArc(center: CGPoint(x: rect.minX + r, y: rect.maxY - r),
                 radius: r, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        // Left edge
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
        // Top-left corner
        p.addArc(center: CGPoint(x: rect.minX + r, y: rect.minY + r),
                 radius: r, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)

        p.closeSubpath()
        return p
    }
}

extension Notification.Name {
    static let onboardingButtonPulse = Notification.Name("onboardingButtonPulse")
}
