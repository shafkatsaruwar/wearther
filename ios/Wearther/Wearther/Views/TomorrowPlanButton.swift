import SwiftUI

struct TomorrowPlanButton: View {
    let forecast: TomorrowForecast
    let outfit: OutfitRecommendation
    var sweataWeatha: SweataWeathaMoment? = nil

    @State private var isPresented = false

    var body: some View {
        Button {
            isPresented = true
        } label: {
            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("PLAN FOR TOMORROW")
                        .font(AppTheme.micro)
                        .tracking(2.0)
                        .foregroundStyle(AppTheme.accent)

                    Text(outfit.title)
                        .font(AppTheme.titleSection)
                        .foregroundStyle(AppTheme.ink)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("\(forecast.feelsLike)° · \(forecast.condition) · H \(forecast.high)° / L \(forecast.low)°")
                        .font(AppTheme.subheadline)
                        .foregroundStyle(AppTheme.inkMuted)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                WeatherIconView(code: forecast.conditionCode)
                    .font(.system(size: 28))

                Image(systemName: "chevron.right")
                    .font(AppTheme.subheadlineSemibold)
                    .foregroundStyle(AppTheme.inkFaint)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.fitSurface)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(AppTheme.accent.opacity(0.18), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Plan for tomorrow")
        .accessibilityHint("Shows tomorrow's weather and outfit recommendation")
        .sheet(isPresented: $isPresented) {
            TomorrowPlanSheet(
                forecast: forecast,
                outfit: outfit,
                sweataWeatha: sweataWeatha
            )
        }
    }
}

struct TomorrowPlanSheet: View {
    let forecast: TomorrowForecast
    let outfit: OutfitRecommendation
    var sweataWeatha: SweataWeathaMoment? = nil

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                TomorrowPlanView(
                    forecast: forecast,
                    outfit: outfit,
                    sweataWeatha: sweataWeatha
                )
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .background(AppTheme.linen.ignoresSafeArea())
            .navigationTitle("Tomorrow")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(AppTheme.subheadlineSemibold)
                        .foregroundStyle(AppTheme.accent)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    TomorrowPlanButton(
        forecast: TomorrowForecast(
            dateLabel: "Wednesday, August 26",
            high: 97,
            low: 70,
            feelsLike: 101,
            condition: "Clear",
            conditionCode: "clear",
            humidity: 40,
            windSpeed: 6,
            precipitationChance: 1,
            hourly: []
        ),
        outfit: OutfitRecommendation(
            title: "Linen or Short Sleeve + Shorts",
            items: ["Linen or lightweight short sleeve", "Shorts", "Sneakers"],
            explanation: "For tomorrow: It's hot out — keep it light and breathable.",
            warmthLevel: 1,
            bringLater: nil
        )
    )
    .padding()
}
