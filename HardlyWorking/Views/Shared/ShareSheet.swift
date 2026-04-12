import SwiftUI

struct ShareSheet: View {
    @Environment(\.dismiss) private var dismiss
    let data: ShareCardData
    let isProUser: Bool

    @State private var selectedType: ShareCardType = .money
    @State private var selectedFormat: ShareCardFormat = .stories
    @State private var renderedURL: URL?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    cardPreview
                    typePicker
                    formatPicker

                    if let renderedURL {
                        ShareLink(
                            item: renderedURL,
                            subject: Text("My \(selectedType.rawValue) — Hardly Working Corp."),
                            message: Text("Filed via Hardly Working Corp. Your other employer does not need to see this.")
                        ) {
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
                        .padding(.horizontal, 24)
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
            .background(Theme.cardBackground.opacity(0.3))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { Haptics.light(); dismiss() }
                        .font(.system(.body, design: .monospaced))
                }
            }
            .onChange(of: selectedType) { renderCard() }
            .onChange(of: selectedFormat) { renderCard() }
            .onAppear { renderCard() }
        }
    }

    private var cardPreview: some View {
        let previewScale: CGFloat = selectedFormat == .stories ? 0.55 : 0.75

        return ShareCardView(data: data, type: selectedType, format: selectedFormat, isProUser: isProUser)
            .scaleEffect(previewScale)
            .frame(
                width: selectedFormat.logicalSize.width * previewScale,
                height: selectedFormat.logicalSize.height * previewScale
            )
            .shadow(color: Theme.textPrimary.opacity(0.08), radius: 20, y: 10)
    }

    private var typePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("REPORT TYPE")
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.3))
                .tracking(1.5)
                .padding(.horizontal, 24)

            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(availableTypes) { type in
                        Button {
                            Haptics.selection()
                            selectedType = type
                        } label: {
                            Text(type.rawValue)
                                .font(.system(size: 11, weight: selectedType == type ? .semibold : .regular, design: .monospaced))
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
            case .percentile: data.percentile != nil
            case .category: data.topCategory != nil
            case .record: data.longestSession != nil
            case .achievement: data.recentAchievement != nil
            }
        }
    }

    private var formatPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("FORMAT")
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.3))
                .tracking(1.5)
                .padding(.horizontal, 24)

            HStack(spacing: 10) {
                ForEach(ShareCardFormat.allCases) { format in
                    Button {
                        Haptics.selection()
                        selectedFormat = format
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: format == .stories ? "rectangle.portrait" : "square")
                                .font(.system(.caption, weight: .medium))
                            Text(format.rawValue)
                                .font(.system(size: 12, weight: selectedFormat == format ? .semibold : .regular, design: .monospaced))
                        }
                        .foregroundStyle(selectedFormat == format ? .white : Theme.textPrimary.opacity(0.5))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedFormat == format ? Theme.accent : Theme.cardBackground)
                                .stroke(selectedFormat == format ? Color.clear : Theme.textPrimary.opacity(0.06), lineWidth: 1)
                        )
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }

    private func renderCard() {
        renderedURL = ShareCardRenderer.renderToFile(data: data, type: selectedType, format: selectedFormat, isProUser: isProUser)
        if renderedURL != nil { Haptics.light() }
    }
}
