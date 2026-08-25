import SwiftUI

struct TomorrowPlanView: View {
    let forecast: TomorrowForecast
    let outfit: OutfitRecommendation
    var sweataWeatha: SweataWeathaMoment?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(forecast.dateLabel)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.inkMuted)

                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(forecast.feelsLike)°")
                            .font(.system(size: 44, weight: .regular, design: .serif))
                            .foregroundStyle(AppTheme.ink)
                        Text("feels like")
                            .font(.caption)
                            .foregroundStyle(AppTheme.inkFaint)
                    }

                    Text("\(forecast.condition) • H \(forecast.high)° / L \(forecast.low)°")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.inkSoft)

                    Text("Rain \(forecast.precipitationChance)% • Wind \(forecast.windSpeed) mph")
                        .font(.caption)
                        .foregroundStyle(AppTheme.inkMuted)
                }

                Spacer(minLength: 0)

                WeatherIconView(code: forecast.conditionCode)
                    .font(.system(size: 36))
            }

            if let sweataWeatha {
                SweataWeathaView(moment: sweataWeatha)
            }

            OutfitCardView(
                sectionTitle: "PLAN FOR TOMORROW",
                outfit: outfit
            )
        }
    }
}

#Preview {
    TomorrowPlanView(
        forecast: TomorrowForecast(
            dateLabel: "Wednesday, August 26",
            high: 58,
            low: 48,
            feelsLike: 52,
            condition: "Rain",
            conditionCode: "rain",
            humidity: 75,
            windSpeed: 16,
            precipitationChance: 65,
            hourly: []
        ),
        outfit: OutfitRecommendation(
            title: "Long Sleeve + Light Jacket",
            items: ["Long sleeve shirt", "Light jacket", "Rain jacket", "Jeans"],
            explanation: "For tomorrow: A light jacket should keep you comfortable.",
            warmthLevel: 5,
            bringLater: nil
        )
    )
    .padding()
}
