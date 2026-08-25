import SwiftUI

struct OutfitCardView: View {
    let outfit: OutfitRecommendation

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("TODAY'S FIT")
                .font(.caption2.weight(.semibold))
                .tracking(2.2)
                .foregroundStyle(AppTheme.accent)

            Text(outfit.title)
                .font(.system(size: 36, weight: .regular, design: .serif))
                .foregroundStyle(AppTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 16)

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 72), spacing: 12)],
                alignment: .leading,
                spacing: 12
            ) {
                ForEach(outfit.items, id: \.self) { item in
                    VStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(AppTheme.fitIconBg)
                            .frame(width: 56, height: 56)
                            .overlay {
                                ClothingGlyphView(label: item)
                            }
                        Text(item)
                            .font(.caption2)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(AppTheme.inkMuted)
                            .frame(maxWidth: 88)
                    }
                }
            }
            .padding(.top, 28)

            Text(outfit.explanation)
                .font(.body)
                .foregroundStyle(AppTheme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 28)

            if let bringLater = outfit.bringLater {
                Text(bringLater)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.accent)
                    .padding(.top, 16)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.fitSurface)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}
