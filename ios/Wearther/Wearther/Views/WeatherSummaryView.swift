import SwiftUI

struct WeatherSummaryView: View {
    let weather: WeatherData
    let dateLabel: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(dateLabel)
                .font(AppTheme.subheadline)
                .foregroundStyle(AppTheme.inkMuted)

            HStack(alignment: .center, spacing: 12) {
                Text("\(weather.temperature)°")
                    .font(AppTheme.titleTemp)
                    .foregroundStyle(AppTheme.ink)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)

                WeatherIconView(code: weather.conditionCode)
                    .font(.system(size: 32))

                Spacer(minLength: 0)
            }

            Text("Feels like \(weather.feelsLike)°")
                .font(AppTheme.body)
                .foregroundStyle(AppTheme.inkSoft)

            Text("\(weather.condition) • Wind \(weather.windSpeed) mph")
                .font(AppTheme.subheadline)
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
                .font(AppTheme.caption)
                .foregroundStyle(AppTheme.inkFaint)
            Text(value)
                .font(AppTheme.subheadline)
                .foregroundStyle(AppTheme.inkSoft)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
