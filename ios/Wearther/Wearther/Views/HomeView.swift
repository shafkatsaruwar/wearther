import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()

    private let sidePadding: CGFloat = 24

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {
                header

                if viewModel.isLoading {
                    loadingPlaceholder
                } else if let weather = viewModel.weather, let outfit = viewModel.outfit {
                    content(weather: weather, outfit: outfit)
                } else if let error = viewModel.errorMessage {
                    Text(error)
                        .font(AppTheme.body)
                        .foregroundStyle(AppTheme.inkMuted)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 48)
                }
            }
            .padding(.horizontal, sidePadding)
            .padding(.top, 12)
            .padding(.bottom, 48)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background {
            AtmosphereBackground()
        }
        .task { viewModel.onAppear() }
    }

    private var header: some View {
        CitySearchView(viewModel: viewModel)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func content(weather: WeatherData, outfit: OutfitRecommendation) -> some View {
        WeatherSummaryView(weather: weather, dateLabel: viewModel.dateLabel)

        Rectangle()
            .fill(AppTheme.line)
            .frame(height: 1)

        if let moment = viewModel.sweataWeathaToday {
            SweataWeathaView(moment: moment)
        }

        OutfitCardView(outfit: outfit)

        HourlyForecastView(hours: weather.hourly, comfort: viewModel.comfort)

        if let tomorrow = weather.tomorrow, let tomorrowOutfit = viewModel.tomorrowOutfit {
            TomorrowPlanButton(
                forecast: tomorrow,
                outfit: tomorrowOutfit,
                sweataWeatha: viewModel.sweataWeathaTomorrow
            )
        }

        ComfortFeedbackView(
            lastFeedback: viewModel.comfort.lastFeedback,
            onFeedback: viewModel.submitFeedback
        )

        NotificationSettingsView(viewModel: viewModel)
    }

    private var loadingPlaceholder: some View {
        VStack(alignment: .leading, spacing: 16) {
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.surface)
                .frame(width: 160, height: 80)
            RoundedRectangle(cornerRadius: 8)
                .fill(AppTheme.surface)
                .frame(width: 220, height: 16)
            RoundedRectangle(cornerRadius: 24)
                .fill(AppTheme.fitSurface)
                .frame(maxWidth: .infinity)
                .frame(height: 220)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .redacted(reason: .placeholder)
        .shimmering()
    }
}

private extension View {
    func shimmering() -> some View {
        modifier(ShimmerModifier())
    }
}

private struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .opacity(0.6 + 0.4 * Double(sin(phase)))
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    phase = .pi
                }
            }
    }
}

#Preview {
    HomeView()
}
