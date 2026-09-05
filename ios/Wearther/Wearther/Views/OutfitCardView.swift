import SwiftUI

struct OutfitCardView: View {
    let outfit: OutfitRecommendation
    let comfort: ComfortPreference

    private var displayTitle: String {
        FitCopy.formatTitle(outfit)
    }

    private var confidence: String {
        FitCopy.confidenceLabel(comfort)
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
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                    Text(confidence)
                        .font(AppFont.captionSemibold)
                }
                .foregroundStyle(AppTheme.accent)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(AppTheme.mint))
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

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "sun.max")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
                    .padding(.top, 2)

                Text(outfit.explanation)
                    .font(AppFont.body)
                    .foregroundStyle(AppTheme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AppTheme.mint)
            )
            .padding(.top, 28)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(radius: 30)
    }
}

enum FitCopy {
    static func formatTitle(_ outfit: OutfitRecommendation) -> String {
        let hasJacket = outfit.items.contains {
            $0.range(of: "jacket|coat|bring", options: .regularExpression) != nil
        }
        if hasJacket || outfit.title.range(of: "jacket|coat|bring", options: .regularExpression) != nil {
            return outfit.title
        }
        if outfit.title.range(of: "no jacket", options: [.regularExpression, .caseInsensitive]) != nil {
            return outfit.title
        }
        return "\(outfit.title), No Jacket"
    }

    static func confidenceLabel(_ comfort: ComfortPreference) -> String {
        if comfort.feedbackCount > 0 || comfort.lastFeedback != nil {
            return "Tuned"
        }
        return "Confident"
    }

    static func packTip(outfit: OutfitRecommendation, weather: WeatherData) -> (label: String, value: String) {
        if let later = outfit.bringLater {
            let short = later
                .replacingOccurrences(
                    of: #"^bring\s+"#,
                    with: "",
                    options: [.regularExpression, .caseInsensitive]
                )
                .trimmingCharacters(in: CharacterSet(charactersIn: "."))
            return ("Pack", short.prefix(1).uppercased() + short.dropFirst())
        }
        if weather.precipitationChance >= 40 {
            return ("Pack", "Rain layer")
        }
        if weather.high - weather.low >= 12 {
            return ("Pack", "Light layer")
        }
        return ("Pack", "Travel light")
    }
}
