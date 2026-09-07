import SwiftUI

struct OutfitCardView: View {
    let outfit: OutfitRecommendation
    let weather: WeatherData
    let comfort: ComfortPreference

    @State private var showWhy = false
    @State private var selectedItem: ClothingInfo?

    private var displayTitle: String {
        FitCopy.formatTitle(outfit)
    }

    private var confidence: FitConfidence {
        FitCopy.confidence(outfit: outfit, weather: weather, comfort: comfort)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                Text("TODAY'S FIT")
                    .font(AppFont.labelCaps)
                    .tracking(2.2)
                    .foregroundStyle(AppTheme.accent)

                Spacer(minLength: 8)

                HStack(spacing: 4) {
                    Image(systemName: confidence.systemImage)
                        .font(.system(size: 10, weight: .bold))
                    Text(confidence.rawValue)
                        .font(AppFont.captionSemibold)
                }
                .foregroundStyle(confidence == .rainRisk || confidence == .eveningDrop ? AppTheme.coral : AppTheme.accent)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(
                        confidence == .rainRisk || confidence == .eveningDrop
                            ? AppTheme.coral.opacity(0.14)
                            : AppTheme.mint
                    )
                )
            }

            Text(displayTitle)
                .font(AppFont.outfitTitle)
                .foregroundStyle(AppTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 16)

            HStack(alignment: .top, spacing: 10) {
                ForEach(Array(outfit.items.prefix(3)), id: \.self) { item in
                    let info = ClothingInfoProvider.info(for: item, weather: weather)
                    Button {
                        selectedItem = info
                    } label: {
                        VStack(spacing: 8) {
                            Circle()
                                .fill(AppTheme.fitIconBg)
                                .frame(width: 58, height: 58)
                                .overlay {
                                    ClothingGlyphView(label: item)
                                        .foregroundStyle(AppTheme.inkSoft)
                                }
                            Text(item)
                                .font(.system(size: 12, weight: .semibold))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(AppTheme.ink)
                                .frame(maxWidth: 100)
                            Text(info.subtitle)
                                .font(.system(size: 11, weight: .medium))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(AppTheme.inkMuted)
                                .frame(maxWidth: 100)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Learn about \(item)")
                }
            }
            .padding(.top, 28)

            Text(FitCopy.shortExplanation(outfit))
                .font(AppFont.body)
                .foregroundStyle(AppTheme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 24)

            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    showWhy.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Text("Why?")
                        .font(AppFont.subheadlineMedium)
                    Image(systemName: showWhy ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                    Spacer()
                }
                .foregroundStyle(AppTheme.accent)
                .frame(minHeight: 44)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)

            if showWhy {
                Text(FitCopy.whyDetail(weather: weather, outfit: outfit))
                    .font(AppFont.caption)
                    .foregroundStyle(AppTheme.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(AppTheme.mint)
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(radius: 30)
        .sheet(item: $selectedItem) { info in
            ClothingInfoSheet(info: info)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }
}

struct ClothingInfoSheet: View {
    let info: ClothingInfo
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                Text(info.name)
                    .font(AppFont.display(28))
                    .foregroundStyle(AppTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 12)
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.inkMuted)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(AppTheme.surface))
                        .overlay(Circle().stroke(AppTheme.line, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")
            }

            detailBlock(title: "What it is", body: info.whatItIs)
                .padding(.top, 24)
            detailBlock(title: "Why today", body: info.whyToday)
                .padding(.top, 18)

            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AppTheme.cream.ignoresSafeArea())
    }

    private func detailBlock(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(AppFont.labelCaps)
                .tracking(1.6)
                .foregroundStyle(AppTheme.inkMuted)
            Text(body)
                .font(AppFont.body)
                .foregroundStyle(AppTheme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
