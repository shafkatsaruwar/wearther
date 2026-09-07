import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
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
                            errorState(error)
                        } else if let weather = viewModel.weather, let outfit = viewModel.outfit {
                            content(weather: weather, outfit: outfit)
                                .padding(.top, 12)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 48)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .scrollContentBackground(.hidden)
                .scrollIndicators(.hidden)
                .refreshable {
                    await viewModel.refreshWeather(showFullLoading: false)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.bgMid.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
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
        let packs = FitCopy.packLaneItems(outfit: outfit, weather: weather)

        return VStack(alignment: .leading, spacing: 22) {
            refreshStatus(weather: weather)

            OutfitCardView(outfit: outfit, weather: weather, comfort: viewModel.comfort)

            PackLaneView(items: packs)

            WeatherEvidenceView(
                weather: weather,
                dateLabel: viewModel.dateLabel,
                units: viewModel.comfort.units
            )

            HourlyForecastView(hours: weather.hourly, comfort: viewModel.comfort)

            OutlookView(daily: weather.daily, units: viewModel.comfort.units)

            ComfortFeedbackView(
                lastFeedback: viewModel.comfort.lastFeedback,
                onFeedback: viewModel.submitFeedback
            )

            TripPackEntryCard()
        }
    }

    private func refreshStatus(weather: WeatherData) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.dateLabel)
                    .font(AppFont.caption)
                    .foregroundStyle(AppTheme.inkMuted)
                HStack(spacing: 6) {
                    Text(weather.updatedLabel)
                        .font(AppFont.caption)
                        .foregroundStyle(weather.isStale ? AppTheme.coral : AppTheme.inkSoft)
                    if weather.isMock {
                        Text("· Demo weather")
                            .font(AppFont.caption)
                            .foregroundStyle(AppTheme.coral)
                    } else if weather.isStale {
                        Text("· May be stale")
                            .font(AppFont.caption)
                            .foregroundStyle(AppTheme.coral)
                    }
                }
            }

            Spacer()

            Button {
                Task { await viewModel.refreshWeather(showFullLoading: false) }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
                    .rotationEffect(.degrees(viewModel.isRefreshing ? 360 : 0))
                    .animation(
                        viewModel.isRefreshing
                            ? .linear(duration: 0.8).repeatForever(autoreverses: false)
                            : .default,
                        value: viewModel.isRefreshing
                    )
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(AppTheme.surface))
                    .overlay(Circle().stroke(AppTheme.line, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isRefreshing)
            .accessibilityLabel("Refresh weather")
        }
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image("BrandMark")
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .padding(.top, 48)

            Text(message)
                .font(AppFont.subheadline)
                .foregroundStyle(AppTheme.inkMuted)
                .multilineTextAlignment(.center)

            Button {
                Task { await viewModel.refreshWeather() }
            } label: {
                Text("Try again")
                    .font(AppFont.subheadlineMedium)
                    .foregroundStyle(.white)
                    .frame(minWidth: 140, minHeight: 44)
                    .background(Capsule().fill(AppTheme.accent))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
    }

    private var loadingPlaceholder: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Spacer()
                Image("BrandMark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .opacity(0.9)
                Spacer()
            }
            .padding(.bottom, 8)

            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(AppTheme.fitSurface)
                .frame(height: 280)
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppTheme.surface)
                .frame(height: 52)
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppTheme.surface)
                .frame(height: 120)
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
