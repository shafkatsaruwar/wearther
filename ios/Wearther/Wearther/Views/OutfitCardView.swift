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
                .font(AppTheme.micro)
                .tracking(2.2)
                .foregroundStyle(AppTheme.accent)

            Text(outfit.title)
                .font(AppTheme.titleOutfit)
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
                .font(AppTheme.body)
                .foregroundStyle(AppTheme.inkSoft)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            if let bringLater = outfit.bringLater {
                Text(bringLater)
                    .font(AppTheme.subheadlineMedium)
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
                .font(AppTheme.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(AppTheme.inkMuted)
                .lineLimit(3)
                .frame(width: 72)
        }
    }
}
