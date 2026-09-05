import SwiftUI

struct OutlookView: View {
    let daily: [DailyForecast]
    let units: TempUnits

    var body: some View {
        let upcoming = Array(daily.dropFirst().prefix(6))
        if upcoming.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 16) {
                Text("COMING UP")
                    .font(AppFont.labelCaps)
                    .tracking(2.2)
                    .foregroundStyle(AppTheme.inkMuted)

                if let tomorrow = upcoming.first {
                    tomorrowCard(tomorrow)
                }

                if upcoming.count > 1 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(Array(upcoming.dropFirst())) { day in
                                dayChip(day)
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                }
            }
        }
    }

    private func tomorrowCard(_ day: DailyForecast) -> some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Tomorrow")
                    .font(AppFont.subheadlineMedium)
                    .foregroundStyle(AppTheme.ink)
                Text(day.condition)
                    .font(AppFont.caption)
                    .foregroundStyle(AppTheme.inkMuted)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(TemperatureDisplay.value(day.high, units: units))° / \(TemperatureDisplay.value(day.low, units: units))°")
                    .font(AppFont.subheadlineMedium)
                    .foregroundStyle(AppTheme.ink)
                if day.precipitationChance >= 30 {
                    Text("\(day.precipitationChance)% rain")
                        .font(AppFont.caption)
                        .foregroundStyle(AppTheme.accent)
                } else {
                    Text(shortTip(day))
                        .font(AppFont.caption)
                        .foregroundStyle(AppTheme.inkSoft)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(radius: 22)
    }

    private func dayChip(_ day: DailyForecast) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(weekdayLabel(day.date))
                .font(AppFont.caption)
                .foregroundStyle(AppTheme.inkMuted)
            Text("\(TemperatureDisplay.value(day.high, units: units))°")
                .font(AppFont.hourlyTemp)
                .foregroundStyle(AppTheme.ink)
            Text(day.condition)
                .font(AppFont.caption2)
                .foregroundStyle(AppTheme.inkSoft)
                .lineLimit(1)
        }
        .frame(minWidth: 88, alignment: .leading)
        .padding(14)
        .cardSurface(radius: 18)
    }

    private func shortTip(_ day: DailyForecast) -> String {
        if day.high - day.low >= 15 { return "Layer up" }
        if day.high >= 82 { return "Dress light" }
        if day.low <= 45 { return "Warm nights" }
        return "Steady day"
    }

    private func weekdayLabel(_ iso: String) -> String {
        if let date = parseDay(iso) {
            return date.formatted(.dateTime.weekday(.abbreviated))
        }
        return iso
    }

    private func parseDay(_ iso: String) -> Date? {
        let isoFormatter = ISO8601DateFormatter()
        if let date = isoFormatter.date(from: iso) { return date }
        let dayOnly = DateFormatter()
        dayOnly.locale = Locale(identifier: "en_US_POSIX")
        dayOnly.dateFormat = "yyyy-MM-dd"
        return dayOnly.date(from: String(iso.prefix(10)))
    }
}
