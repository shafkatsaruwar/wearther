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

                    if viewModel.isCustomizeOpen {
                        CustomizeView(viewModel: viewModel)
                            .padding(.top, 16)
                    } else if viewModel.isLoading {
                        loadingPlaceholder
                            .padding(.top, 32)
                    } else if let error = viewModel.errorMessage, viewModel.weather == nil {
                        Text(error)
                            .font(AppFont.subheadline)
                            .foregroundStyle(AppTheme.inkMuted)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 64)
                    } else if let weather = viewModel.weather, let outfit = viewModel.outfit {
                        content(weather: weather, outfit: outfit)
                            .padding(.top, 20)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 48)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.bgMid.ignoresSafeArea())
        .preferredColorScheme(.light)
        .task { viewModel.onAppear() }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            CitySearchView(viewModel: viewModel)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    viewModel.isCustomizeOpen.toggle()
                    if viewModel.isCustomizeOpen {
                        viewModel.isCityPickerOpen = false
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Tune")
                        .font(AppFont.subheadlineMedium)
                }
                .foregroundStyle(AppTheme.inkSoft)
                .padding(.horizontal, 14)
                .frame(minWidth: 44, minHeight: 44)
                .background(
                    Capsule()
                        .fill(AppTheme.surface)
                        .overlay(Capsule().stroke(AppTheme.line, lineWidth: 1))
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Tune preferences")
        }
    }

    private func content(weather: WeatherData, outfit: OutfitRecommendation) -> some View {
        let tip = FitCopy.packTip(outfit: outfit, weather: weather)

        return VStack(alignment: .leading, spacing: 28) {
            WeatherSummaryView(
                weather: weather,
                dateLabel: viewModel.dateLabel,
                units: viewModel.comfort.units,
                packLabel: tip.label,
                packValue: tip.value
            )

            OutfitCardView(outfit: outfit, comfort: viewModel.comfort)

            HourlyForecastView(hours: weather.hourly, comfort: viewModel.comfort)

            ComfortFeedbackView(
                lastFeedback: viewModel.comfort.lastFeedback,
                onFeedback: viewModel.submitFeedback
            )
        }
    }

    private var loadingPlaceholder: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(AppTheme.surface)
                    .frame(height: 160)
                VStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(AppTheme.surface)
                            .frame(height: 64)
                    }
                }
                .frame(width: 118)
            }
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(AppTheme.fitSurface)
                .frame(height: 260)
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
