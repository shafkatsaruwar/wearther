import SwiftUI

struct WeatherSummaryView: View {
    let weather: WeatherData
    let dateLabel: String
    let units: TempUnits
    let packLabel: String
    let packValue: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            mainCard
            VStack(spacing: 12) {
                statCard(
                    label: "High / Low",
                    value: "\(TemperatureDisplay.value(weather.high, units: units))° / \(TemperatureDisplay.value(weather.low, units: units))°"
                )
                statCard(label: "Humidity", value: "\(weather.humidity)%")
                packCard
            }
            .frame(maxWidth: 118)
        }
    }

    private var mainCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                Text(dateLabel)
                    .font(AppFont.subheadline)
                    .foregroundStyle(AppTheme.inkMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)

                WeatherIconView(code: weather.conditionCode)
                    .font(.system(size: 28))
                    .foregroundStyle(AppTheme.accentSoft)
            }

            Text("\(TemperatureDisplay.value(weather.temperature, units: units))°")
                .font(AppFont.temperature)
                .foregroundStyle(AppTheme.ink)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .padding(.top, 12)

            Text(weather.condition)
                .font(AppFont.subheadlineMedium)
                .foregroundStyle(AppTheme.ink)
                .padding(.top, 16)

            Text("Feels like \(TemperatureDisplay.value(weather.feelsLike, units: units))° • Wind \(TemperatureDisplay.wind(weather.windSpeed, units: units))")
                .font(AppFont.caption)
                .foregroundStyle(AppTheme.inkMuted)
                .padding(.top, 4)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(radius: AppTheme.cardRadius)
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(red: 0.96, green: 0.78, blue: 0.35).opacity(0.45), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 50
                    )
                )
                .frame(width: 90, height: 90)
                .offset(x: 18, y: -22)
                .allowsHitTesting(false)
        }
        .clipped()
    }

    private func statCard(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(AppTheme.inkMuted)
            Text(value)
                .font(AppFont.subheadlineMedium)
                .foregroundStyle(AppTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
        .cardSurface(radius: AppTheme.statRadius)
    }

    private var packCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(packLabel.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(Color.white.opacity(0.75))
            Text(packValue)
                .font(AppFont.subheadlineMedium)
                .foregroundStyle(Color.white)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.statRadius, style: .continuous)
                .fill(AppTheme.accent)
                .shadow(color: AppTheme.ink.opacity(0.12), radius: 12, y: 6)
        )
    }
}
