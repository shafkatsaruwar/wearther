import SwiftUI

struct OutfitCardView: View {
    let sectionTitle: String
    let outfit: OutfitRecommendation

    init(sectionTitle: String = "TODAY'S FIT", outfit: OutfitRecommendation) {
        self.sectionTitle = sectionTitle
        self.outfit = outfit
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(sectionTitle)
                .font(.caption2.weight(.semibold))
                .tracking(2.2)
                .foregroundStyle(AppTheme.accent)

            Text(outfit.title)
                .font(.system(size: 30, weight: .regular, design: .serif))
                .foregroundStyle(AppTheme.ink)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 14) {
                    ForEach(outfit.items, id: \.self) { item in
                        clothingItem(item)
                    }
                }
            }

            Text(outfit.explanation)
                .font(.body)
                .foregroundStyle(AppTheme.inkSoft)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            if let bringLater = outfit.bringLater {
                Text(bringLater)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.accent)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.fitSurface)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func clothingItem(_ item: String) -> some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppTheme.fitIconBg)
                    .frame(width: 56, height: 56)
                ClothingGlyphView(label: item)
            }

            Text(item)
                .font(.caption2)
                .multilineTextAlignment(.center)
                .foregroundStyle(AppTheme.inkMuted)
                .lineLimit(3)
                .frame(width: 72)
        }
    }
}
