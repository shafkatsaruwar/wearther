import SwiftUI

struct PackLaneView: View {
    let items: [String]

    var body: some View {
        if items.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 10) {
                Text("PACK LATER")
                    .font(AppFont.labelCaps)
                    .tracking(1.8)
                    .foregroundStyle(AppTheme.inkMuted)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(items, id: \.self) { item in
                            HStack(spacing: 8) {
                                Image(systemName: symbol(for: item))
                                    .font(.system(size: 13, weight: .semibold))
                                Text(item)
                                    .font(AppFont.subheadlineMedium)
                                    .lineLimit(1)
                            }
                            .foregroundStyle(Color.white)
                            .padding(.horizontal, 14)
                            .frame(minHeight: 44)
                            .background(
                                Capsule()
                                    .fill(AppTheme.accent)
                                    .shadow(color: AppTheme.ink.opacity(0.12), radius: 10, y: 5)
                            )
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private func symbol(for item: String) -> String {
        let lower = item.lowercased()
        if lower.contains("rain") { return "cloud.rain.fill" }
        if lower.contains("scarf") { return "wind" }
                if lower.contains("layer") || lower.contains("jacket") { return "cloud.fill" }
        return "bag.fill"
    }
}
