import SwiftUI

struct OnboardingScheduleView: View {
    @Binding var workHoursPerDay: Double
    @Binding var workDaysPerWeek: Int

    @State private var showMascot = false
    @State private var showBubble = false
    @State private var dialogueStage = 0
    @State private var showReplyButton = false
    @State private var replyPulse = false
    @State private var showSubtitle = false
    @State private var showForm = false
    @State private var showTotal = false

    private var weeklyHours: Double {
        workHoursPerDay * Double(workDaysPerWeek)
    }

    private var formattedHours: String {
        if workHoursPerDay.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(workHoursPerDay))h"
        } else if workHoursPerDay.truncatingRemainder(dividingBy: 0.5) == 0 {
            return String(format: "%.1fh", workHoursPerDay)
        } else {
            return String(format: "%.2fh", workHoursPerDay)
        }
    }

    private var bubbleText: String {
        switch dialogueStage {
        case 1: "Sure thing!"
        default: "We must measure\nyour suffering."
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer().frame(height: 20)

                ZStack(alignment: .top) {
                    Image("mascot_schedule")
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

                Text("File your official work schedule.\nDiscrepancies will be noted.")
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .opacity(showSubtitle ? 1 : 0)

                Spacer().frame(height: 28)

                VStack(spacing: 0) {
                    formSection("HOURS PER DAY") {
                        HStack {
                            Text(formattedHours)
                                .font(.system(.title3, design: .monospaced, weight: .medium))
                                .foregroundStyle(Theme.textPrimary)
                                .frame(width: 80, alignment: .leading)
                            Spacer()
                            Stepper("", value: $workHoursPerDay, in: 1...24, step: 0.25)
                                .labelsHidden()
                                .onChange(of: workHoursPerDay) { Haptics.selection() }
                        }
                    }

                    Divider().padding(.horizontal, 16).opacity(0.06)

                    formSection("DAYS PER WEEK") {
                        HStack {
                            Text("\(workDaysPerWeek)")
                                .font(.system(.title3, design: .monospaced, weight: .medium))
                                .foregroundStyle(Theme.textPrimary)
                                .frame(width: 80, alignment: .leading)
                            Spacer()
                            Stepper("", value: $workDaysPerWeek, in: 1...7)
                                .labelsHidden()
                                .onChange(of: workDaysPerWeek) { Haptics.selection() }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.cardBackground.opacity(0.5))
                        .stroke(Theme.textPrimary.opacity(0.06), lineWidth: 1)
                )
                .opacity(showForm ? 1 : 0)
                .offset(y: showForm ? 0 : 15)

                Spacer().frame(height: 20)

                Text("Total exposure: \(Text("\(Int(weeklyHours))h/week").foregroundStyle(Theme.money)).")
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.5))
                    .opacity(showTotal ? 1 : 0)
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
                ScheduleBubbleShape(tailOffset: -20)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
            }
            .background {
                ScheduleBubbleShape(tailOffset: -20)
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
            Text("... thank you?")
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
            withAnimation(.easeOut(duration: 0.4)) { showSubtitle = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { showForm = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            withAnimation(.easeOut(duration: 0.3)) { showTotal = true }
        }
    }

    private func formSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.3))
                .tracking(1.5)
            content()
        }
        .padding(.vertical, 16)
    }
}

private struct ScheduleBubbleShape: Shape {
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
