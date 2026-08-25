import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        ZStack {
            AtmosphereBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                        .padding(.bottom, 8)

                    if viewModel.isLoading {
                        loadingPlaceholder
                            .padding(.top, 48)
                    } else if let weather = viewModel.weather, let outfit = viewModel.outfit {
                        content(weather: weather, outfit: outfit)
                            .padding(.top, 24)
                    } else if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.body)
                            .foregroundStyle(AppTheme.inkMuted)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 64)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 48)
            }
        }
        .task { viewModel.onAppear() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Wearther")
                .font(.system(size: 28, weight: .semibold, design: .serif))
                .foregroundStyle(AppTheme.ink)

            CitySearchView(viewModel: viewModel)
                .padding(.top, 20)
        }
    }

    private func content(weather: WeatherData, outfit: OutfitRecommendation) -> some View {
        VStack(alignment: .leading, spacing: 40) {
            WeatherSummaryView(weather: weather, dateLabel: viewModel.dateLabel)

            Divider()
                .overlay(AppTheme.line)

            OutfitCardView(outfit: outfit)

            HourlyForecastView(hours: weather.hourly, comfort: viewModel.comfort)

            if let tomorrow = weather.tomorrow, let tomorrowOutfit = viewModel.tomorrowOutfit {
                Divider()
                    .overlay(AppTheme.line)

                TomorrowPlanView(forecast: tomorrow, outfit: tomorrowOutfit)
            }

            ComfortFeedbackView(
                lastFeedback: viewModel.comfort.lastFeedback,
                onFeedback: viewModel.submitFeedback
            )
        }
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
                .frame(height: 220)
                .padding(.top, 24)
        }
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
