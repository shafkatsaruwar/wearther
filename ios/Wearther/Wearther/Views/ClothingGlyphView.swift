import SwiftUI

struct ClothingGlyphView: View {
    let label: String

    var body: some View {
        Image(systemName: symbolName)
            .font(.system(size: 22, weight: .medium))
            .foregroundStyle(AppTheme.inkSoft)
    }

    private var symbolName: String {
        let lower = label.lowercased()
        if lower.contains("linen") || lower.contains("short sleeve") || lower.contains("t-shirt") {
            return "tshirt.fill"
        }
        if lower.contains("long sleeve") {
            return "tshirt"
        }
        if lower.contains("sweater") || lower.contains("base layer") {
            return "figure.stand.dress.line.vertical.figure"
        }
        if lower.contains("jacket") || lower.contains("coat") {
            return "cloud.fill"
        }
        if lower.contains("rain") || lower.contains("waterproof") {
            return "cloud.rain.fill"
        }
        if lower.contains("shorts") {
            return "figure.walk"
        }
        if lower.contains("pants") || lower.contains("jeans") || lower.contains("chinos") {
            return "figure.stand"
        }
        if lower.contains("scarf") {
            return "wind"
        }
        if lower.contains("gloves") {
            return "hand.raised.fill"
        }
        if lower.contains("sneaker") || lower.contains("shoe") {
            return "shoeprints.fill"
        }
        return "hanger"
    }
}
