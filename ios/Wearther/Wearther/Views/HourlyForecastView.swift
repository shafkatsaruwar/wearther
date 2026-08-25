import SwiftUI

struct HourlyForecastView: View {
    let hours: [HourlyWeather]
    let comfort: ComfortPreference

    var body: some View {
        if hours.isEmpty { EmptyView() } else {
            VStack(alignment: .leading, spacing: 16) {
                Text("LATER TODAY")
                    .font(.caption2.weight(.semibold))
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
                .font(.caption)
                .foregroundStyle(AppTheme.inkMuted)
            Text("\(hour.temperature)°")
                .font(.title3.weight(.medium))
                .foregroundStyle(AppTheme.ink)
            Text(tip)
                .font(.caption2)
                .foregroundStyle(AppTheme.inkFaint)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(minWidth: 92, alignment: .leading)
        .padding(12)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.line, lineWidth: 1)
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
