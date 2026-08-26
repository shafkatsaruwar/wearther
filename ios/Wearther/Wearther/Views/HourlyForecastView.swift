import SwiftUI

struct HourlyForecastView: View {
    let hours: [HourlyWeather]
    let comfort: ComfortPreference

    var body: some View {
        if hours.isEmpty { EmptyView() } else {
            VStack(alignment: .leading, spacing: 16) {
                Text("LATER TODAY")
                    .font(AppTheme.micro)
                    .tracking(2.2)
                    .foregroundStyle(AppTheme.inkFaint)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(hours) { hour in
                            hourCard(hour)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func hourCard(_ hour: HourlyWeather) -> some View {
        let tip = OutfitRecommender.recommendForHour(hour, comfort: comfort)
        let label = formattedHour(hour.time)

        return VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(AppTheme.caption)
                .foregroundStyle(AppTheme.inkMuted)
            Text("\(hour.temperature)°")
                .font(AppTheme.sans(18, weight: .medium))
                .foregroundStyle(AppTheme.ink)
            Text(tip)
                .font(AppTheme.caption)
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
