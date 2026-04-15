import SwiftUI

struct ShareSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(RatingManager.self) private var ratingManager
    let data: ShareCardData
    let isProUser: Bool

    /// Persist the last-selected report type so returning users don't have to
    /// re-pick their favourite. Falls back to .money if the persisted type
    /// isn't available for the current data.
    @AppStorage("shareSheet.lastTypeRaw") private var persistedTypeRaw: String = ShareCardType.money.rawValue

    @State private var selectedType: ShareCardType = .money
    @State private var renderCache: [ShareCardType: URL] = [:]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                memoHeader

                ScrollView {
                    VStack(spacing: 24) {
                        cardPreview
                        typePicker
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }

                distributeBar
            }
            .background(Theme.cardBackground.opacity(0.5))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        Haptics.light()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 30, height: 30)
                            .background(Theme.bloodRed, in: Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .onAppear {
                restorePersistedSelection()
                prerenderAllCards()
            }
            .onChange(of: selectedType) { _, newValue in
                persistedTypeRaw = newValue.rawValue
            }
        }
    }

    /// Restore the user's last-selected type, defaulting gracefully when the
    /// persisted choice isn't available for the current data set.
    private func restorePersistedSelection() {
        if let savedType = ShareCardType(rawValue: persistedTypeRaw),
           availableTypes.contains(savedType) {
            selectedType = savedType
        } else {
            selectedType = availableTypes.first ?? .money
        }
    }

    // MARK: - Memo Header

    private var memoHeader: some View {
        HStack {
            Text("FILE: \(fileDate)")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(0.5))
                .tracking(1.5)
            Spacer()
            Text("REPORT EXPORT")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(0.5))
                .tracking(1.5)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(Theme.cardBackground)
        .overlay(
            Rectangle().fill(Theme.textPrimary.opacity(0.08)).frame(height: 1),
            alignment: .bottom
        )
    }

    private var fileDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    // MARK: - Preview

    /// 4:3 cards are taller than the old square — drop the preview scale a
    /// touch so the whole card stays comfortably above the type picker on
    /// smaller phones.
    private var cardPreview: some View {
        let previewScale: CGFloat = 0.7
        let logical = ShareCardCanvas.logicalSize

        return ShareCardView(data: data, type: selectedType, isProUser: isProUser)
            .scaleEffect(previewScale)
            .frame(
                width: logical.width * previewScale,
                height: logical.height * previewScale
            )
            .shadow(color: Theme.textPrimary.opacity(0.08), radius: 20, y: 10)
    }

    // MARK: - Type Picker

    private var typePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("REPORT TYPE")
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.5))
                .tracking(1.5)
                .padding(.horizontal, 24)

            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(availableTypes) { type in
                        Button {
                            Haptics.selection()
                            selectedType = type
                        } label: {
                            HStack(spacing: 6) {
                                Text(type.previewEmoji)
                                    .font(.caption)
                                Text(type.rawValue)
                                    .font(.system(size: 11, weight: selectedType == type ? .semibold : .regular, design: .monospaced))
                            }
                            .foregroundStyle(selectedType == type ? .white : Theme.textPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selectedType == type ? Theme.accent : Theme.cardBackground)
                                    .stroke(selectedType == type ? Color.clear : Theme.textPrimary.opacity(0.1), lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
            .scrollIndicators(.hidden)
        }
    }

    private var availableTypes: [ShareCardType] {
        ShareCardType.allCases.filter { type in
            switch type {
            case .money: data.totalMoney > 0
            case .category: data.topCategory != nil
            case .record: data.longestSession != nil
            case .achievement: data.recentAchievement != nil
            case .laziestDay: data.laziestDay != nil
            case .streak: data.currentStreak >= 3
            }
        }
    }

    // MARK: - Distribute Bar (pinned to bottom)

    private var distributeBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Theme.textPrimary.opacity(0.08))
                .frame(height: 1)

            Group {
                if let url = renderedURL {
                    // Sharing the file URL preserves broad app compatibility
                    // (Instagram, Snapchat, WhatsApp, Mail, AirDrop all accept
                    // it cleanly). iOS shows "Save to Photos" for image URLs
                    // when the app declares NSPhotoLibraryAddUsageDescription,
                    // which is set in the project's INFOPLIST_KEY settings.
                    ShareLink(
                        item: url,
                        subject: Text("INTERNAL MEMO: \(selectedType.rawValue.uppercased()) — Hardly Working Corp."),
                        message: Text(shareMessage)
                    ) {
                        distributeButtonLabel
                    }
                    // ShareLink doesn't expose its own action hook, so hook a
                    // simultaneous tap gesture for the confirmation haptic
                    // AND the rating-prompt trigger. Note this fires when the
                    // user taps Distribute, not when they actually complete
                    // the share — close enough for our purposes (the iOS
                    // share sheet itself doesn't expose a completion hook).
                    .simultaneousGesture(
                        TapGesture().onEnded {
                            Haptics.success()
                            ratingManager.recordShareDistributed()
                        }
                    )
                } else {
                    // Placeholder keeps the bar layout stable while cards render.
                    HStack(spacing: 8) {
                        ProgressView().scaleEffect(0.8)
                        Text("Preparing report")
                            .font(.system(.headline, design: .monospaced))
                    }
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Theme.accent.opacity(0.6), in: RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 16)
        }
        .background(Theme.cardBackground)
    }

    /// Per-card brand-voice message body for the iOS share sheet.
    /// iOS platforms decide whether to use this (e.g. Messages prepends it;
    /// some targets ignore it) so it has to stand alone.
    private var shareMessage: String {
        let header = "Forwarded for external review. Approved for public distribution by J. Pemberton, CSO."
        switch selectedType {
        case .money:
            return "\(header) Attached: annual performance review. Figures self-reported and independently unverifiable."
        case .category:
            return "\(header) Attached: incident report, unredacted."
        case .record:
            return "\(header) Attached: personal best — longest uninterrupted episode on record."
        case .achievement:
            return "\(header) Attached: commendation certificate. Presented this fiscal quarter."
        case .laziestDay:
            return "\(header) Attached: peak inactivity filing. Notable."
        case .streak:
            return "\(header) Attached: attendance verification. Weekends excluded."
        }
    }

    private var distributeButtonLabel: some View {
        HStack(spacing: 8) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(.body, weight: .bold))
            Text("Distribute")
                .font(.system(.headline, design: .monospaced))
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Render Cache

    /// URL for the currently-selected type, if already rendered.
    private var renderedURL: URL? {
        renderCache[selectedType]
    }

    /// Pre-render every visible card type so picker changes swap instantly
    /// from the cache. ImageRenderer needs the main actor, so we render
    /// serially here but yield between renders to keep the UI responsive.
    /// The currently-selected card renders first so Distribute unlocks as
    /// quickly as possible.
    private func prerenderAllCards() {
        Task { @MainActor in
            // Priority render: the card the user is looking at right now.
            renderIfMissing(type: selectedType)

            // Then everything else.
            for type in availableTypes {
                renderIfMissing(type: type)
                await Task.yield()
            }
        }
    }

    @MainActor
    private func renderIfMissing(type: ShareCardType) {
        guard renderCache[type] == nil else { return }

        if let url = ShareCardRenderer.renderToFile(
            data: data,
            type: type,
            isProUser: isProUser
        ) {
            renderCache[type] = url
        }
    }
}
