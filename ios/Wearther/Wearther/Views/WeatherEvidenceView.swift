import SwiftUI

struct WeatherEvidenceView: View {
    let weather: WeatherData
    let dateLabel: String
    let units: TempUnits

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("\(TemperatureDisplay.value(weather.temperature, units: units))°")
                    .font(AppFont.display(40))
                    .foregroundStyle(AppTheme.ink)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)

                VStack(alignment: .leading, spacing: 2) {
                    Text(weather.condition)
                        .font(AppFont.subheadlineMedium)
                        .foregroundStyle(AppTheme.ink)
                    Text("Feels \(TemperatureDisplay.value(weather.feelsLike, units: units))° · Wind \(TemperatureDisplay.wind(weather.windSpeed, units: units))")
                        .font(AppFont.caption)
                        .foregroundStyle(AppTheme.inkMuted)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)

                WeatherIconView(code: weather.conditionCode)
                    .font(.system(size: 26))
                    .foregroundStyle(AppTheme.accentSoft)
            }

            HStack(spacing: 8) {
                evidenceChip(
                    label: "High / Low",
                    value: "\(TemperatureDisplay.value(weather.high, units: units))° / \(TemperatureDisplay.value(weather.low, units: units))°"
                )
                evidenceChip(label: "Humidity", value: "\(weather.humidity)%")
                evidenceChip(label: "Rain", value: "\(weather.precipitationChance)%")
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(radius: AppTheme.cardRadius)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(dateLabel). \(weather.temperature) degrees, \(weather.condition)")
    }

    private func evidenceChip(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.1)
                .foregroundStyle(AppTheme.inkMuted)
            Text(value)
                .font(AppFont.subheadlineMedium)
                .foregroundStyle(AppTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
        .cardSurface(radius: AppTheme.statRadius)
    }
}
