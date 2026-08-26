import SwiftUI

struct OutfitCardView: View {
    let sectionTitle: String
    let outfit: OutfitRecommendation

    init(sectionTitle: String = "TODAY'S FIT", outfit: OutfitRecommendation) {
        self.sectionTitle = sectionTitle
        self.outfit = outfit
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(sectionTitle)
                .font(.caption2.weight(.semibold))
                .tracking(2.2)
                .foregroundStyle(AppTheme.accent)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(outfit.title)
                .font(.system(size: 32, weight: .regular, design: .serif))
                .foregroundStyle(AppTheme.ink)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 14)

            HStack(alignment: .top, spacing: 12) {
                ForEach(outfit.items, id: \.self) { item in
                    clothingItem(item)
                }
                if outfit.items.count < 4 {
                    Spacer(minLength: 0)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 24)

            Text(outfit.explanation)
                .font(.body)
                .foregroundStyle(AppTheme.inkSoft)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 24)

            if let bringLater = outfit.bringLater {
                Text(bringLater)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.accent)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 12)
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.fitSurface)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func clothingItem(_ item: String) -> some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppTheme.fitIconBg)
                .frame(width: 52, height: 52)
                .overlay {
                    ClothingGlyphView(label: item)
                }

            Text(item)
                .font(.caption2)
                .multilineTextAlignment(.center)
                .foregroundStyle(AppTheme.inkMuted)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(width: 72, alignment: .top)
    }
}
