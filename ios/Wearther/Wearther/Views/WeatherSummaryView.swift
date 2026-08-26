import SwiftUI

struct WeatherSummaryView: View {
    let weather: WeatherData
    let dateLabel: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(dateLabel)
                .font(.subheadline)
                .foregroundStyle(AppTheme.inkMuted)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 20)

            HStack(alignment: .center, spacing: 12) {
                Text("\(weather.temperature)°")
                    .font(.system(size: 72, weight: .regular, design: .serif))
                    .foregroundStyle(AppTheme.ink)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)

                WeatherIconView(code: weather.conditionCode)
                    .font(.system(size: 34))

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text("Feels like \(weather.feelsLike)°")
                .font(.body)
                .foregroundStyle(AppTheme.inkSoft)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 10)

            Text("\(weather.condition) • Wind \(weather.windSpeed) mph")
                .font(.subheadline)
                .foregroundStyle(AppTheme.inkMuted)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)

            HStack(alignment: .top, spacing: 0) {
                statBlock(title: "High / Low", value: "\(weather.high)° / \(weather.low)°")
                statBlock(title: "Humidity", value: "\(weather.humidity)%")
                statBlock(title: "Rain", value: "\(weather.precipitationChance)%")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 20)
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
