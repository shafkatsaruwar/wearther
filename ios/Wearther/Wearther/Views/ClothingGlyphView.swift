import SwiftUI

struct ClothingGlyphView: View {
    let label: String
    var size: CGFloat = 22

    var body: some View {
        Image(systemName: symbolName)
            .font(.system(size: size, weight: .medium))
    }

    private var symbolName: String {
        let lower = label.lowercased()
        if lower.contains("blazer") || lower.contains("overshirt") || lower.contains("oxford") || lower.contains("button-up") || lower.contains("dress shirt") {
            return "tshirt"
        }
        if lower.contains("hoodie") || lower.contains("athletic tee") || lower.contains("performance") || lower.contains("training") {
            return "figure.run"
        }
        if lower.contains("jogger") {
            return "figure.walk"
        }
        if lower.contains("loafer") || lower.contains("leather") || lower.contains("running shoe") {
            return "shoeprints.fill"
        }
        if lower.contains("linen") || lower.contains("short sleeve") || lower.contains("t-shirt") || lower.contains("tee") {
            return "tshirt.fill"
        }
        if lower.contains("long sleeve") {
            return "tshirt"
        }
        if lower.contains("sweater") || lower.contains("base layer") || lower.contains("fine-knit") || lower.contains("fine knit") {
            return "figure.stand.dress.line.vertical.figure"
        }
        if lower.contains("rain") || lower.contains("waterproof") || lower.contains("shell") {
            return "cloud.rain.fill"
        }
        if lower.contains("jacket") || lower.contains("coat") || lower.contains("overcoat") {
            return "cloud.fill"
        }
        if lower.contains("shorts") {
            return "figure.walk"
        }
        if lower.contains("pants") || lower.contains("jeans") || lower.contains("chinos") || lower.contains("trousers") {
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
