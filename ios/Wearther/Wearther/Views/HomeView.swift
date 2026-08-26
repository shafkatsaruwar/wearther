import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()

    private let horizontalInset: CGFloat = 24

    var body: some View {
        ZStack {
            AtmosphereBackground()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    header
                        .padding(.bottom, 12)

                    if viewModel.isLoading {
                        loadingPlaceholder
                            .padding(.top, 40)
                    } else if let weather = viewModel.weather, let outfit = viewModel.outfit {
                        content(weather: weather, outfit: outfit)
                            .padding(.top, 20)
                    } else if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.body)
                            .foregroundStyle(AppTheme.inkMuted)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 64)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, horizontalInset)
                .padding(.top, 8)
                .padding(.bottom, 56)
            }
        }
        .task { viewModel.onAppear() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Wearther")
                .font(.system(size: 28, weight: .semibold, design: .serif))
                .foregroundStyle(AppTheme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)

            CitySearchView(viewModel: viewModel)
                .padding(.top, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func content(weather: WeatherData, outfit: OutfitRecommendation) -> some View {
        VStack(alignment: .leading, spacing: 32) {
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
                Rectangle()
                    .fill(AppTheme.line)
                    .frame(height: 1)

                TomorrowPlanView(
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
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var loadingPlaceholder: some View {
        VStack(alignment: .leading, spacing: 16) {
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.surface)
                .frame(width: 160, height: 80)
            RoundedRectangle(cornerRadius: 8)
                .fill(AppTheme.surface)
                .frame(width: 220, height: 16)
            RoundedRectangle(cornerRadius: 28)
                .fill(AppTheme.fitSurface)
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .padding(.top, 24)
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
