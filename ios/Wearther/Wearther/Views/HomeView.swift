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
                            .padding(.top, 48)
                    } else if let weather = viewModel.weather, let outfit = viewModel.outfit {
                        content(weather: weather, outfit: outfit)
                            .padding(.top, 24)
                    } else if let error = viewModel.errorMessage {
                        Text(error)
                            .font(AppFont.subheadline)
                            .foregroundStyle(AppTheme.inkMuted)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 64)
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
        HStack(alignment: .top, spacing: 12) {
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
                ScarfToolbarIcon()
                    .frame(width: 40, height: 40)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Customize preferences")
            .padding(.top, 2)
        }
    }

    private func content(weather: WeatherData, outfit: OutfitRecommendation) -> some View {
        VStack(alignment: .leading, spacing: 40) {
            WeatherSummaryView(
                weather: weather,
                dateLabel: viewModel.dateLabel,
                units: viewModel.comfort.units
            )

            Rectangle()
                .fill(AppTheme.line)
                .frame(height: 1)

            OutfitCardView(outfit: outfit)

            HourlyForecastView(hours: weather.hourly, comfort: viewModel.comfort)

            ComfortFeedbackView(
                lastFeedback: viewModel.comfort.lastFeedback,
                onFeedback: viewModel.submitFeedback
            )
        }
    }

    private var loadingPlaceholder: some View {
        VStack(alignment: .leading, spacing: 16) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.surface)
                .frame(width: 160, height: 80)
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(AppTheme.surface)
                .frame(width: 220, height: 16)
            RoundedRectangle(cornerRadius: 28, style: .continuous)
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

private struct ScarfToolbarIcon: View {
    var body: some View {
        ScarfShape()
            .stroke(AppTheme.inkMuted, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
            .frame(width: 20, height: 20)
    }
}

private struct ScarfShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()

        // Collar band
        path.move(to: CGPoint(x: w * 0.33, y: h * 0.28))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.67, y: h * 0.28),
            control: CGPoint(x: w * 0.5, y: h * 0.02)
        )
        path.addLine(to: CGPoint(x: w * 0.67, y: h * 0.38))
        path.addLine(to: CGPoint(x: w * 0.33, y: h * 0.38))
        path.closeSubpath()

        // Left tail
        path.move(to: CGPoint(x: w * 0.33, y: h * 0.38))
        path.addLine(to: CGPoint(x: w * 0.33, y: h * 0.88))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.46, y: h * 0.88),
            control: CGPoint(x: w * 0.4, y: h * 0.98)
        )
        path.addLine(to: CGPoint(x: w * 0.5, y: h * 0.62))

        // Right tail
        path.move(to: CGPoint(x: w * 0.67, y: h * 0.38))
        path.addLine(to: CGPoint(x: w * 0.67, y: h * 0.88))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.54, y: h * 0.88),
            control: CGPoint(x: w * 0.6, y: h * 0.98)
        )
        path.addLine(to: CGPoint(x: w * 0.5, y: h * 0.62))

        // Cross band
        path.move(to: CGPoint(x: w * 0.33, y: h * 0.48))
        path.addLine(to: CGPoint(x: w * 0.67, y: h * 0.48))

        return path
    }
}
