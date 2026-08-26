import SwiftUI

struct WeatherSummaryView: View {
    let weather: WeatherData
    let dateLabel: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(dateLabel)
                .font(.subheadline)
                .foregroundStyle(AppTheme.inkMuted)

            HStack(alignment: .center, spacing: 12) {
                Text("\(weather.temperature)°")
                    .font(.system(size: 68, weight: .regular, design: .serif))
                    .foregroundStyle(AppTheme.ink)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)

                WeatherIconView(code: weather.conditionCode)
                    .font(.system(size: 32))

                Spacer(minLength: 0)
            }

            Text("Feels like \(weather.feelsLike)°")
                .font(.body)
                .foregroundStyle(AppTheme.inkSoft)

            Text("\(weather.condition) • Wind \(weather.windSpeed) mph")
                .font(.subheadline)
                .foregroundStyle(AppTheme.inkMuted)

            HStack(alignment: .top, spacing: 12) {
                statBlock(title: "High / Low", value: "\(weather.high)° / \(weather.low)°")
                statBlock(title: "Humidity", value: "\(weather.humidity)%")
                statBlock(title: "Rain", value: "\(weather.precipitationChance)%")
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
