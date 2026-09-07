import SwiftUI

struct OutfitCardView: View {
    let outfit: OutfitRecommendation
    let weather: WeatherData
    let comfort: ComfortPreference

    @State private var showWhy = false

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

            HStack(alignment: .top, spacing: 12) {
                ForEach(Array(outfit.items.prefix(3)), id: \.self) { item in
                    VStack(spacing: 8) {
                        Circle()
                            .fill(AppTheme.fitIconBg)
                            .frame(width: 58, height: 58)
                            .overlay {
                                ClothingGlyphView(label: item)
                                    .foregroundStyle(AppTheme.inkSoft)
                            }
                        Text(item)
                            .font(.system(size: 11, weight: .medium))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(AppTheme.inkMuted)
                            .frame(maxWidth: 96)
                    }
                    .frame(maxWidth: .infinity)
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
    }
}
