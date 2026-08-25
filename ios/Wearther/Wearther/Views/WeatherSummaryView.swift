import SwiftUI

struct WeatherSummaryView: View {
    let weather: WeatherData
    let dateLabel: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(dateLabel)
                .font(.subheadline)
                .foregroundStyle(AppTheme.inkMuted)
                .padding(.bottom, 24)

            HStack(alignment: .top, spacing: 12) {
                Text("\(weather.temperature)°")
                    .font(.system(size: 72, weight: .regular, design: .serif))
                    .foregroundStyle(AppTheme.ink)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)

                WeatherIconView(code: weather.conditionCode)
                    .font(.system(size: 32))
                    .padding(.top, 8)
            }

            Text("Feels like \(weather.feelsLike)°")
                .font(.body)
                .foregroundStyle(AppTheme.inkSoft)
                .padding(.top, 12)

            Text("\(weather.condition) • Wind \(weather.windSpeed) mph")
                .font(.subheadline)
                .foregroundStyle(AppTheme.inkMuted)
                .padding(.top, 4)

            HStack(spacing: 24) {
                statBlock(title: "High / Low", value: "\(weather.high)° / \(weather.low)°")
                statBlock(title: "Humidity", value: "\(weather.humidity)%")
                statBlock(title: "Rain", value: "\(weather.precipitationChance)%")
            }
            .padding(.top, 24)
        }
    }

    private func statBlock(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(AppTheme.inkFaint)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(AppTheme.inkSoft)
        }
    }
}
