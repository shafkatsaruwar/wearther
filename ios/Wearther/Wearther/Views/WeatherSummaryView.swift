import SwiftUI

struct WeatherSummaryView: View {
    let weather: WeatherData
    let dateLabel: String
    let units: TempUnits

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(dateLabel)
                .font(AppFont.subheadline)
                .foregroundStyle(AppTheme.inkMuted)
                .padding(.bottom, 24)

            HStack(alignment: .top, spacing: 12) {
                Text("\(TemperatureDisplay.value(weather.temperature, units: units))°")
                    .font(AppFont.temperature)
                    .foregroundStyle(AppTheme.ink)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)

                WeatherIconView(code: weather.conditionCode)
                    .font(.system(size: 32))
                    .padding(.top, 8)
            }

            Text("Feels like \(TemperatureDisplay.value(weather.feelsLike, units: units))°")
                .font(AppFont.body)
                .foregroundStyle(AppTheme.inkSoft)
                .padding(.top, 12)

            Text("\(weather.condition) • Wind \(TemperatureDisplay.wind(weather.windSpeed, units: units))")
                .font(AppFont.subheadline)
                .foregroundStyle(AppTheme.inkMuted)
                .padding(.top, 4)

            HStack(spacing: 24) {
                statBlock(
                    title: "High / Low",
                    value: "\(TemperatureDisplay.value(weather.high, units: units))° / \(TemperatureDisplay.value(weather.low, units: units))°"
                )
                statBlock(title: "Humidity", value: "\(weather.humidity)%")
                statBlock(title: "Rain", value: "\(weather.precipitationChance)%")
            }
            .padding(.top, 24)
        }
    }

    private func statBlock(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppFont.caption)
                .foregroundStyle(AppTheme.inkFaint)
            Text(value)
                .font(AppFont.subheadline)
                .foregroundStyle(AppTheme.inkSoft)
        }
    }
}
