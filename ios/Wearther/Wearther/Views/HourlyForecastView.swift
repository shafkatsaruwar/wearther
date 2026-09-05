import SwiftUI

struct HourlyForecastView: View {
    let hours: [HourlyWeather]
    let comfort: ComfortPreference

    var body: some View {
        if hours.isEmpty { EmptyView() } else {
            VStack(alignment: .leading, spacing: 16) {
                Text("LATER TODAY")
                    .font(AppFont.labelCaps)
                    .tracking(2.2)
                    .foregroundStyle(AppTheme.inkFaint)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(hours) { hour in
                            hourCard(hour)
                        }
                    }
                }
            }
        }
    }

    private func hourCard(_ hour: HourlyWeather) -> some View {
        let tip = OutfitRecommender.recommendForHour(hour, comfort: comfort)
        let label = formattedHour(hour.time)

        return VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(AppFont.caption)
                .foregroundStyle(AppTheme.inkMuted)
            Text("\(TemperatureDisplay.value(hour.temperature, units: comfort.units))°")
                .font(AppFont.hourlyTemp)
                .foregroundStyle(AppTheme.ink)
            Text(tip)
                .font(AppFont.caption2)
                .foregroundStyle(AppTheme.inkFaint)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(minWidth: 92, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppTheme.surface)
        )
    }

    private func formattedHour(_ iso: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: iso) {
            return date.formatted(.dateTime.hour())
        }
        return iso
    }
}
