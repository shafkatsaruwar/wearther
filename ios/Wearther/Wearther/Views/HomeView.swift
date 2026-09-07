import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showWhy = false
    @State private var selectedItem: ClothingInfo?

    var body: some View {
        NavigationStack {
            ZStack {
                AtmosphereBackground()

                VStack(spacing: 0) {
                    header
                        .padding(.horizontal, 18)
                        .padding(.top, 6)
                        .padding(.bottom, 10)

                    if viewModel.isCustomizeOpen {
                        ScrollView {
                            CustomizeView(viewModel: viewModel)
                                .padding(.horizontal, 18)
                                .padding(.bottom, 24)
                        }
                        .scrollIndicators(.hidden)
                    } else if viewModel.isLoading {
                        loadingPlaceholder
                    } else if let error = viewModel.errorMessage, viewModel.weather == nil {
                        errorState(error)
                    } else if let weather = viewModel.weather, let outfit = viewModel.outfit {
                        todayBoard(weather: weather, outfit: outfit)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 12)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.bgMid.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .sheet(item: $selectedItem) { info in
                ClothingInfoSheet(info: info)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showWhy) {
                if let weather = viewModel.weather, let outfit = viewModel.outfit {
                    whySheet(weather: weather, outfit: outfit)
                }
            }
        }
        .preferredColorScheme(.light)
        .task { viewModel.onAppear() }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center, spacing: 8) {
            CitySearchView(viewModel: viewModel)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                viewModel.locateMe()
            } label: {
                Group {
                    if viewModel.isLocating {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "location.fill")
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
                .foregroundStyle(AppTheme.accent)
                .frame(width: 40, height: 40)
                .background(Circle().fill(AppTheme.mint.opacity(0.9)))
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isLocating)
            .accessibilityLabel("Locate Me")

            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    viewModel.isCustomizeOpen.toggle()
                    if viewModel.isCustomizeOpen {
                        viewModel.isCityPickerOpen = false
                    }
                }
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.inkSoft)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(AppTheme.surface)
                            .overlay(Circle().stroke(AppTheme.line, lineWidth: 1))
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Tune preferences")
        }
    }

    // MARK: - One board (no scroll)

    private func todayBoard(weather: WeatherData, outfit: OutfitRecommendation) -> some View {
        let packs = FitCopy.packLaneItems(outfit: outfit, weather: weather)
        let units = viewModel.comfort.units
        let confidence = FitCopy.confidence(outfit: outfit, weather: weather, comfort: viewModel.comfort)
        let title = FitCopy.formatTitle(outfit)

        return VStack(alignment: .leading, spacing: 0) {
            if let locateError = viewModel.locateErrorMessage {
                HStack(alignment: .top, spacing: 8) {
                    Text(locateError)
                        .font(AppFont.caption)
                        .foregroundStyle(AppTheme.coral)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    Button {
                        viewModel.locateErrorMessage = nil
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(AppTheme.coral.opacity(0.8))
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Dismiss")
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(AppTheme.coral.opacity(0.1))
                )
                .padding(.bottom, 10)
            }

            // Fit
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(title)
                    .font(AppFont.display(28))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 6)

                Text(confidence.rawValue)
                    .font(AppFont.captionSemibold)
                    .foregroundStyle(
                        confidence == .rainRisk || confidence == .eveningDrop
                            ? AppTheme.coral
                            : AppTheme.accent
                    )
                    .lineLimit(1)
            }

            Text(FitCopy.shortExplanation(outfit))
                .font(AppFont.subheadline)
                .foregroundStyle(AppTheme.inkSoft)
                .lineLimit(2)
                .padding(.top, 6)

            // Clothing pieces — clear icon tiles (not tiny truncated chips)
            HStack(alignment: .top, spacing: 10) {
                ForEach(Array(outfit.items.prefix(3)), id: \.self) { item in
                    let info = ClothingInfoProvider.info(for: item, weather: weather)
                    Button {
                        selectedItem = info
                    } label: {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.fitIconBg)
                                    .frame(width: 56, height: 56)
                                ClothingGlyphView(label: item, size: 22)
                                    .foregroundStyle(AppTheme.accent)
                            }
                            Text(info.name)
                                .font(AppFont.captionSemibold)
                                .foregroundStyle(AppTheme.ink)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .minimumScaleFactor(0.85)
                            Text(info.subtitle)
                                .font(AppFont.caption2)
                                .foregroundStyle(AppTheme.inkMuted)
                                .multilineTextAlignment(.center)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Learn about \(info.name)")
                }
            }
            .padding(.top, 16)

            // Weather + pack — one quiet block
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("\(TemperatureDisplay.value(weather.temperature, units: units))° \(weather.condition)")
                        .font(AppFont.subheadlineMedium)
                        .foregroundStyle(AppTheme.ink)
                    Text("·")
                        .foregroundStyle(AppTheme.inkFaint)
                    Text("Feels \(TemperatureDisplay.value(weather.feelsLike, units: units))°")
                        .font(AppFont.caption)
                        .foregroundStyle(AppTheme.inkMuted)
                    Spacer(minLength: 0)
                    Button {
                        Task { await viewModel.refreshWeather(showFullLoading: false) }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppTheme.accent.opacity(0.7))
                            .rotationEffect(.degrees(viewModel.isRefreshing ? 360 : 0))
                            .animation(
                                viewModel.isRefreshing
                                    ? .linear(duration: 0.8).repeatForever(autoreverses: false)
                                    : .default,
                                value: viewModel.isRefreshing
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Refresh weather")
                }

                Text(
                    "Wind \(TemperatureDisplay.wind(weather.windSpeed, units: units)) · H \(TemperatureDisplay.value(weather.high, units: units))° / L \(TemperatureDisplay.value(weather.low, units: units))°"
                    + (packs.first.map { " · Pack \($0.lowercased())" } ?? "")
                )
                .font(AppFont.caption)
                .foregroundStyle(AppTheme.inkMuted)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

                if weather.isMock || weather.isStale {
                    Text(weather.isMock ? "Demo weather" : "Weather may be outdated")
                        .font(AppFont.caption)
                        .foregroundStyle(AppTheme.coral)
                }
            }
            .padding(.top, 14)

            // Later + tomorrow — single text strip
            if !weather.hourly.isEmpty || weather.daily.count > 1 {
                VStack(alignment: .leading, spacing: 6) {
                    if !weather.hourly.isEmpty {
                        Text(laterSummary(hours: weather.hourly, units: units))
                            .font(AppFont.caption)
                            .foregroundStyle(AppTheme.inkSoft)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if let tomorrow = weather.daily.dropFirst().first {
                        Text(
                            "Tomorrow \(TemperatureDisplay.value(tomorrow.high, units: units))°/\(TemperatureDisplay.value(tomorrow.low, units: units))° · \(tomorrow.condition)"
                        )
                        .font(AppFont.caption)
                        .foregroundStyle(AppTheme.inkMuted)
                        .lineLimit(1)
                    }
                }
                .padding(.top, 10)
            }

            Spacer(minLength: 8)

            // Why + trip — tertiary
            HStack(spacing: 16) {
                Button {
                    showWhy = true
                } label: {
                    Text("Why?")
                        .font(AppFont.subheadlineMedium)
                        .foregroundStyle(AppTheme.accent)
                }
                .buttonStyle(.plain)

                NavigationLink {
                    TripPackScreen()
                } label: {
                    Text("Trip pack")
                        .font(AppFont.subheadlineMedium)
                        .foregroundStyle(AppTheme.inkMuted)
                }
                .buttonStyle(.plain)

                Spacer(minLength: 0)
            }
            .padding(.top, 4)

            // Feedback
            compactFeedback
                .padding(.top, 12)
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .padding(.bottom, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppTheme.fitSurface)
                .shadow(color: AppTheme.ink.opacity(0.07), radius: 16, y: 6)
        )
    }

    private func whySheet(weather: WeatherData, outfit: OutfitRecommendation) -> some View {
        NavigationStack {
            ScrollView {
                Text(FitCopy.whyDetail(weather: weather, outfit: outfit))
                    .font(AppFont.body)
                    .foregroundStyle(AppTheme.inkSoft)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(24)
            }
            .background(AppTheme.cream.ignoresSafeArea())
            .navigationTitle("Why this fit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showWhy = false }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private var compactFeedback: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("HOW DOES THIS FEEL?")
                .font(AppFont.labelCaps)
                .tracking(1.2)
                .foregroundStyle(AppTheme.inkMuted)

            HStack(spacing: 8) {
                feedbackChip("Too Cold", id: .tooCold, primary: false)
                feedbackChip("Perfect", id: .perfect, primary: true)
                feedbackChip("Too Hot", id: .tooHot, primary: false)
            }

            if let last = viewModel.comfort.lastFeedback {
                Text(FitCopy.feedbackResponse(last))
                    .font(AppFont.caption)
                    .foregroundStyle(AppTheme.accent)
            }
        }
    }

    private func feedbackChip(_ label: String, id: ComfortFeedback, primary: Bool) -> some View {
        let selected = viewModel.comfort.lastFeedback == id
        return Button {
            viewModel.submitFeedback(id)
        } label: {
            Text(label)
                .font(AppFont.captionSemibold)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 40)
                .foregroundStyle(selected ? Color.white : (primary ? AppTheme.accent : AppTheme.inkSoft))
                .background {
                    if selected {
                        Capsule().fill(primary ? AppTheme.accent : AppTheme.ink)
                    } else if primary {
                        Capsule()
                            .fill(AppTheme.accent.opacity(0.12))
                            .overlay(Capsule().stroke(AppTheme.accent.opacity(0.28), lineWidth: 1))
                    } else {
                        Capsule()
                            .fill(AppTheme.surface)
                            .overlay(Capsule().stroke(AppTheme.line, lineWidth: 1))
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private func laterSummary(hours: [HourlyWeather], units: TempUnits) -> String {
        hours.prefix(3).map { hour in
            let tip = OutfitRecommender.recommendForHour(hour, comfort: viewModel.comfort)
            return "\(formattedHour(hour.time)) \(TemperatureDisplay.value(hour.temperature, units: units))° \(tip)"
        }
        .joined(separator: "  ·  ")
    }

    private func formattedHour(_ iso: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: iso) {
            return date.formatted(.dateTime.hour())
        }
        return iso
    }

    // MARK: - States

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 14) {
            Spacer()
            Image("BrandMark")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            Text(message)
                .font(AppFont.subheadline)
                .foregroundStyle(AppTheme.inkMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
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
            Button {
                viewModel.locateMe()
            } label: {
                Text("Locate Me")
                    .font(AppFont.subheadlineMedium)
                    .foregroundStyle(AppTheme.accent)
                    .frame(minHeight: 40)
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var loadingPlaceholder: some View {
        VStack {
            Spacer()
            Image("BrandMark")
                .resizable()
                .scaledToFit()
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .opacity(0.85)
            ProgressView()
                .tint(AppTheme.accent)
                .padding(.top, 16)
            Text("Checking what to wear…")
                .font(AppFont.subheadline)
                .foregroundStyle(AppTheme.inkMuted)
                .padding(.top, 8)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    HomeView()
}
