import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var selectedItem: ClothingInfo?

    var body: some View {
        NavigationStack {
            ZStack {
                AtmosphereBackground()

                VStack(spacing: 0) {
                    header
                        .padding(.horizontal, 18)
                        .padding(.top, 4)
                        .padding(.bottom, 8)

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
                        // Canvas spine: one glance, answer first
                        ScrollView(showsIndicators: false) {
                            decisionSpine(weather: weather, outfit: outfit)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 16)
                        }
                        .refreshable {
                            await viewModel.refreshWeather(showFullLoading: false)
                        }
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

    // MARK: - Canvas spine

    private func decisionSpine(weather: WeatherData, outfit: OutfitRecommendation) -> some View {
        let confidence = FitCopy.confidence(outfit: outfit, weather: weather, comfort: viewModel.comfort)
        let units = viewModel.comfort.units
        let bring = FitCopy.bringSummary(outfit: outfit, weather: weather)
        let nowLine = FitCopy.nowSummary(items: outfit.items)

        return VStack(alignment: .leading, spacing: 14) {
            statusBanner

            // Answer first
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 8) {
                    Text("WEAR THIS TODAY")
                        .font(AppFont.labelCaps)
                        .tracking(1.6)
                        .foregroundStyle(AppTheme.accent)

                    Spacer(minLength: 8)

                    confidencePill(confidence)
                }

                Text(FitCopy.formatTitle(outfit))
                    .font(AppFont.display(34))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(3)
                    .minimumScaleFactor(0.78)
                    .fixedSize(horizontal: false, vertical: true)

                Text(FitCopy.decisionSubtitle(outfit: outfit, weather: weather))
                    .font(AppFont.subheadline)
                    .foregroundStyle(AppTheme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // NOW / BRING
            HStack(alignment: .top, spacing: 10) {
                summaryCard(title: "NOW", body: nowLine)

                summaryCard(
                    title: "BRING",
                    body: bring ?? "Travel light"
                )
            }

            // Plain clothing definitions
            VStack(spacing: 0) {
                ForEach(Array(outfit.items.prefix(3).enumerated()), id: \.element) { index, item in
                    let info = ClothingInfoProvider.info(for: item, weather: weather)
                    if index > 0 {
                        Divider().opacity(0.55)
                    }
                    clothingRow(info: info, raw: item)
                }
            }
            .padding(.vertical, 4)

            // Weather proof
            weatherProof(weather: weather, units: units)

            // Trip is separate — one small entry
            HStack {
                Text("Planning a trip?")
                    .font(AppFont.caption)
                    .foregroundStyle(AppTheme.inkMuted)
                Spacer(minLength: 8)
                NavigationLink {
                    TripPackScreen()
                } label: {
                    Text("Open Trip Pack")
                        .font(AppFont.subheadlineMedium)
                        .underline()
                        .foregroundStyle(AppTheme.accent)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 2)

            // Feedback
            feedbackBlock
                .padding(.top, 4)
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppTheme.fitSurface)
                .shadow(color: AppTheme.ink.opacity(0.06), radius: 14, y: 6)
        )
    }

    @ViewBuilder
    private var statusBanner: some View {
        if let message = softStatusMessage {
            HStack(spacing: 8) {
                Image(systemName: "location.slash")
                    .font(.system(size: 12, weight: .semibold))
                Text(message)
                    .font(AppFont.caption)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                Button {
                    viewModel.locateErrorMessage = nil
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dismiss")
            }
            .foregroundStyle(AppTheme.coral)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppTheme.coral.opacity(0.12))
            )
        }
    }

    private var softStatusMessage: String? {
        if let err = viewModel.locateErrorMessage, !err.isEmpty {
            return "Location is off. Showing saved \(viewModel.location.name) weather."
        }
        if let weather = viewModel.weather, weather.isMock {
            return "Demo weather for \(viewModel.location.name)."
        }
        return nil
    }

    private func confidencePill(_ confidence: FitConfidence) -> some View {
        HStack(spacing: 4) {
            Image(systemName: confidence.systemImage)
                .font(.system(size: 10, weight: .bold))
            Text(confidence.rawValue)
                .font(AppFont.captionSemibold)
        }
        .foregroundStyle(
            confidence == .rainRisk || confidence == .eveningDrop
                ? AppTheme.coral
                : AppTheme.accent
        )
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule().fill(
                confidence == .rainRisk || confidence == .eveningDrop
                    ? AppTheme.coral.opacity(0.14)
                    : AppTheme.mint
            )
        )
    }

    private func summaryCard(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(AppFont.labelCaps)
                .tracking(1.2)
                .foregroundStyle(AppTheme.accent)
            Text(body)
                .font(AppFont.subheadlineMedium)
                .foregroundStyle(AppTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.mint.opacity(0.55))
        )
    }

    private func clothingRow(info: ClothingInfo, raw: String) -> some View {
        Button {
            selectedItem = info
        } label: {
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(AppTheme.fitIconBg)
                        .frame(width: 40, height: 40)
                    ClothingGlyphView(label: raw, size: 16)
                        .foregroundStyle(AppTheme.accent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(info.name)
                        .font(AppFont.subheadlineMedium)
                        .foregroundStyle(AppTheme.ink)
                        .lineLimit(1)
                    Text(info.subtitle)
                        .font(AppFont.caption)
                        .foregroundStyle(AppTheme.inkMuted)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Text("What?")
                    .font(AppFont.captionSemibold)
                    .foregroundStyle(AppTheme.accent)
            }
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(info.name). What is this?")
    }

    private func weatherProof(weather: WeatherData, units: TempUnits) -> some View {
        let slots = weatherSlots(weather: weather, units: units)
        return HStack(alignment: .top, spacing: 0) {
            ForEach(Array(slots.enumerated()), id: \.offset) { index, slot in
                if index > 0 {
                    Divider()
                        .frame(height: 44)
                        .padding(.horizontal, 6)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(slot.label)
                        .font(AppFont.caption)
                        .foregroundStyle(AppTheme.inkMuted)
                    Text(slot.temp)
                        .font(AppFont.subheadlineMedium)
                        .foregroundStyle(AppTheme.ink)
                    Text(slot.tip)
                        .font(AppFont.caption2)
                        .foregroundStyle(AppTheme.inkSoft)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                Task { await viewModel.refreshWeather(showFullLoading: false) }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.accent.opacity(0.7))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isRefreshing)
            .accessibilityLabel("Refresh weather")
        }
        .padding(.vertical, 8)
    }

    private struct WeatherSlot {
        let label: String
        let temp: String
        let tip: String
    }

    private func weatherSlots(weather: WeatherData, units: TempUnits) -> [WeatherSlot] {
        var slots: [WeatherSlot] = [
            WeatherSlot(
                label: "Now",
                temp: "\(TemperatureDisplay.value(weather.temperature, units: units))°",
                tip: "Feels \(TemperatureDisplay.value(weather.feelsLike, units: units))°"
            )
        ]

        for hour in weather.hourly.prefix(2) {
            let tip = OutfitRecommender.recommendForHour(hour, comfort: viewModel.comfort)
            slots.append(
                WeatherSlot(
                    label: formattedHour(hour.time),
                    temp: "\(TemperatureDisplay.value(hour.temperature, units: units))°",
                    tip: tip
                )
            )
        }

        return slots
    }

    private var feedbackBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("HOW WOULD THIS FEEL?")
                .font(AppFont.labelCaps)
                .tracking(1.2)
                .foregroundStyle(AppTheme.inkMuted)

            HStack(spacing: 8) {
                feedbackChip("Too cold", id: .tooCold, primary: false)
                feedbackChip("Perfect", id: .perfect, primary: true)
                feedbackChip("Too hot", id: .tooHot, primary: false)
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
