import SwiftUI

struct OnboardingDepartmentView: View {
    @Binding var userIndustry: String
    @Binding var userCountry: String

    @State private var showMascot = false
    @State private var showBubble = false
    @State private var dialogueStage = 0
    @State private var showReplyButton = false
    @State private var replyPulse = false
    @State private var showSubtitle = false
    @State private var showSector = false
    @State private var showRegion = false

    var isComplete: Bool {
        !userIndustry.isEmpty && !userCountry.isEmpty
    }

    private var bubbleText: String {
        switch dialogueStage {
        case 1: "I disagree. You have\na lot to learn."
        default: "How do you like\nmy filing cabinet?"
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer().frame(height: 20)

                ZStack(alignment: .top) {
                    Image("mascot_department")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 200)
                        .padding(.top, 56)
                        .offset(x: -35)

                    if showBubble {
                        speechBubble
                            .offset(x: 25)
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

                Text("Indicate your sector and\noperating region. Required for\ninterdepartmental benchmarking.")
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .opacity(showSubtitle ? 1 : 0)

                Spacer().frame(height: 28)

                VStack(alignment: .leading, spacing: 20) {
                    // Industry
                    VStack(alignment: .leading, spacing: 10) {
                        Text("SECTOR")
                            .font(.system(.caption2, design: .monospaced, weight: .bold))
                            .foregroundStyle(Theme.textPrimary.opacity(0.3))
                            .tracking(1.5)

                        industryPills
                    }
                    .opacity(showSector ? 1 : 0)
                    .offset(y: showSector ? 0 : 10)

                    // Country
                    VStack(alignment: .leading, spacing: 10) {
                        Text("OPERATING REGION")
                            .font(.system(.caption2, design: .monospaced, weight: .bold))
                            .foregroundStyle(Theme.textPrimary.opacity(0.3))
                            .tracking(1.5)

                        countryPicker
                    }
                    .opacity(showRegion ? 1 : 0)
                    .offset(y: showRegion ? 0 : 10)
                }
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
                DepartmentBubbleShape(tailOffset: -20)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
            }
            .background {
                DepartmentBubbleShape(tailOffset: -20)
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
            Text("It's very nice.")
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
            withAnimation(.easeOut(duration: 0.4)) { showSector = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeOut(duration: 0.4)) { showRegion = true }
        }
    }

    // MARK: - Industry Pills

    private var industryPills: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(Industry.allCases) { industry in
                    Button {
                        Haptics.light()
                        userIndustry = industry.rawValue
                    } label: {
                        HStack(spacing: 4) {
                            Text(industry.emoji)
                                .font(.caption)
                            Text(industry.rawValue)
                                .font(.system(
                                    size: 11,
                                    weight: userIndustry == industry.rawValue ? .semibold : .regular,
                                    design: .monospaced
                                ))
                                .foregroundStyle(userIndustry == industry.rawValue ? .white : Theme.textPrimary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(userIndustry == industry.rawValue ? Theme.accent : Theme.cardBackground)
                                .stroke(
                                    userIndustry == industry.rawValue ? Color.clear : Theme.textPrimary.opacity(0.1),
                                    lineWidth: 1
                                )
                        )
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Country Picker

    private var countryPicker: some View {
        Menu {
            ForEach(Self.countryList, id: \.self) { country in
                Button(country) {
                    Haptics.light()
                    userCountry = country
                }
            }
        } label: {
            HStack {
                Text(userCountry.isEmpty ? "Select operating region" : userCountry)
                    .font(.system(.subheadline, design: .monospaced, weight: .medium))
                    .foregroundStyle(userCountry.isEmpty ? Theme.textPrimary.opacity(0.3) : Theme.textPrimary)
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(.caption, weight: .medium))
                    .foregroundStyle(Theme.textPrimary.opacity(0.3))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.cardBackground.opacity(0.5))
                    .stroke(Theme.textPrimary.opacity(0.06), lineWidth: 1)
            )
        }
    }

    static let countryList: [String] = {
        Locale.Region.isoRegions
            .filter { $0.identifier.count == 2 && $0.isISORegion && $0.subRegions.isEmpty }
            .compactMap { region in
                Locale.current.localizedString(forRegionCode: region.identifier)
            }
            .filter { !$0.isEmpty }
            .sorted()
    }()
}

// MARK: - Bubble Shape

private struct DepartmentBubbleShape: Shape {
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
