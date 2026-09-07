import SwiftUI

struct OnboardingView: View {
    var onFinished: () -> Void

    @State private var step = 0
    @State private var selectedCity = MockWeatherProvider.defaultCity
    @State private var feelBaseline: FeelBaseline = .average
    @State private var style: StyleMode = .casual
    @State private var searchQuery = ""
    @State private var searchResults: [LocationResult] = []
    @State private var isSearching = false
    @State private var savedPicks: [LocationResult] = [MockWeatherProvider.defaultCity]
    @State private var searchTask: Task<Void, Never>?
    @State private var isLocating = false
    @State private var locateError: String?

    var body: some View {
        ZStack {
            AtmosphereBackground()

            VStack(spacing: 0) {
                progress
                    .padding(.top, 12)
                    .padding(.horizontal, 20)

                Group {
                    switch step {
                    case 0: feelStep
                    case 1: styleStep
                    default: cityStep
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                footer
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)
                    .padding(.top, 12)
            }
        }
        .preferredColorScheme(.light)
    }

    private var progress: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                Capsule()
                    .fill(index <= step ? AppTheme.accent : AppTheme.line)
                    .frame(height: 4)
            }
        }
    }

    private var styleStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 24)

            Text("What style should Wearther assume?")
                .font(AppFont.outfitTitle)
                .foregroundStyle(AppTheme.ink)

            Text("Same weather, different wardrobe language. Change anytime in Tune.")
                .font(AppFont.body)
                .foregroundStyle(AppTheme.inkSoft)

            VStack(spacing: 10) {
                ForEach(StyleMode.allCases, id: \.self) { option in
                    Button {
                        style = option
                    } label: {
                        HStack {
                            Text(option.label)
                                .font(AppFont.subheadlineMedium)
                                .foregroundStyle(AppTheme.ink)
                            Spacer()
                            Image(systemName: style == option ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(style == option ? AppTheme.accent : AppTheme.inkFaint)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(AppTheme.surface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(
                                            style == option ? AppTheme.accent.opacity(0.45) : AppTheme.line,
                                            lineWidth: 1
                                        )
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 20)
    }

    private var cityStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Where are you?")
                .font(AppFont.outfitTitle)
                .foregroundStyle(AppTheme.ink)
                .padding(.top, 28)

            Text("Choose a home city — or locate where you are. Bookmark extras to flip between them later.")
                .font(AppFont.body)
                .foregroundStyle(AppTheme.inkSoft)

            Button {
                locateMe()
            } label: {
                HStack(spacing: 10) {
                    if isLocating {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "location.fill")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Locate Me")
                            .font(AppFont.subheadlineMedium)
                        Text("Use your current location")
                            .font(AppFont.caption)
                            .foregroundStyle(AppTheme.inkMuted)
                    }
                    Spacer(minLength: 0)
                }
                .foregroundStyle(AppTheme.accent)
                .padding(14)
                .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(AppTheme.mint.opacity(0.85))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(AppTheme.accent.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
            .disabled(isLocating)
            .accessibilityLabel("Locate Me")

            if let locateError {
                Text(locateError)
                    .font(AppFont.caption)
                    .foregroundStyle(AppTheme.coral)
            }

            TextField("Search city…", text: $searchQuery)
                .textFieldStyle(.plain)
                .font(AppFont.body)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(AppTheme.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(AppTheme.line, lineWidth: 1)
                        )
                )
                .onChange(of: searchQuery) { _, value in
                    runSearch(value)
                }

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    if isSearching {
                        Text("Searching…")
                            .font(AppFont.subheadline)
                            .foregroundStyle(AppTheme.inkMuted)
                    }

                    if !searchResults.isEmpty {
                        sectionLabel("Search results")
                        ForEach(searchResults) { city in
                            cityRow(city)
                        }
                    } else if searchQuery.trimmingCharacters(in: .whitespaces).count < 2 {
                        sectionLabel("Suggested")
                        ForEach(MockWeatherProvider.suggestedCities) { city in
                            cityRow(city)
                        }
                    } else if !isSearching {
                        Text("No cities found")
                            .font(AppFont.subheadline)
                            .foregroundStyle(AppTheme.inkMuted)
                    }
                }
                .padding(.bottom, 12)
            }
        }
        .padding(.horizontal, 20)
    }

    private var feelStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 16)

            Image("BrandMark")
                .resizable()
                .scaledToFit()
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Text("Do you usually run cold, average, or warm?")
                .font(AppFont.outfitTitle)
                .foregroundStyle(AppTheme.ink)

            Text("One question. Wearther uses it to nudge today’s fit.")
                .font(AppFont.body)
                .foregroundStyle(AppTheme.inkSoft)

            VStack(spacing: 10) {
                ForEach(FeelBaseline.allCases, id: \.self) { option in
                    Button {
                        feelBaseline = option
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(feelLabel(option))
                                    .font(AppFont.subheadlineMedium)
                                    .foregroundStyle(AppTheme.ink)
                                Text(feelHint(option))
                                    .font(AppFont.caption)
                                    .foregroundStyle(AppTheme.inkMuted)
                            }
                            Spacer()
                            Image(systemName: feelBaseline == option ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(feelBaseline == option ? AppTheme.accent : AppTheme.inkFaint)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(AppTheme.surface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(
                                            feelBaseline == option ? AppTheme.accent.opacity(0.45) : AppTheme.line,
                                            lineWidth: 1
                                        )
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 20)
    }

    private var footer: some View {
        HStack(spacing: 12) {
            if step > 0 {
                Button("Back") {
                    withAnimation(.easeInOut(duration: 0.2)) { step -= 1 }
                }
                .font(AppFont.subheadlineMedium)
                .foregroundStyle(AppTheme.inkMuted)
                .frame(minHeight: 48)
            }

            Button {
                advance()
            } label: {
                Text(step == 2 ? "Start Wearther" : "Continue")
                    .font(AppFont.subheadlineMedium)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 48)
                    .background(Capsule().fill(AppTheme.accent))
            }
            .buttonStyle(.plain)
        }
    }

    private func feelLabel(_ value: FeelBaseline) -> String {
        switch value {
        case .colder: return "I run cold"
        case .average: return "Average"
        case .warmer: return "I run warm"
        }
    }

    private func feelHint(_ value: FeelBaseline) -> String {
        switch value {
        case .colder: return "Recommend slightly warmer outfits"
        case .average: return "Balanced for most people"
        case .warmer: return "Recommend slightly cooler outfits"
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(AppFont.labelCaps)
            .tracking(1.6)
            .foregroundStyle(AppTheme.inkMuted)
            .padding(.top, 8)
    }

    private func cityRow(_ city: LocationResult) -> some View {
        let selected = selectedCity.id == city.id
        let saved = savedPicks.contains(where: { $0.id == city.id })

        return HStack(spacing: 10) {
            Button {
                selectedCity = city
                if !savedPicks.contains(where: { $0.id == city.id }) {
                    savedPicks.insert(city, at: 0)
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(city.name)
                            .font(AppFont.subheadlineMedium)
                            .foregroundStyle(AppTheme.ink)
                        Text([city.region, city.country].compactMap { $0 }.joined(separator: ", "))
                            .font(AppFont.caption)
                            .foregroundStyle(AppTheme.inkMuted)
                            .lineLimit(1)
                    }
                    Spacer()
                    if selected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(AppTheme.accent)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(AppTheme.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(selected ? AppTheme.accent.opacity(0.45) : AppTheme.line, lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)

            Button {
                if let idx = savedPicks.firstIndex(where: { $0.id == city.id }) {
                    if city.id != selectedCity.id {
                        savedPicks.remove(at: idx)
                    }
                } else {
                    savedPicks.insert(city, at: 0)
                }
            } label: {
                Image(systemName: saved ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(saved ? AppTheme.accent : AppTheme.inkMuted)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(AppTheme.surface))
                    .overlay(Circle().stroke(AppTheme.line, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(saved ? "Remove \(city.name) from saved cities" : "Save \(city.name)")
        }
    }

    private func locateMe() {
        isLocating = true
        locateError = nil
        Task {
            do {
                let place = try await LocationService.shared.locateCurrentPlace()
                selectedCity = place
                if !savedPicks.contains(where: { $0.id == place.id }) {
                    savedPicks.insert(place, at: 0)
                }
                searchQuery = ""
                searchResults = []
            } catch {
                locateError = (error as? LocalizedError)?.errorDescription
                    ?? "Couldn’t find your location."
            }
            isLocating = false
        }
    }

    private func runSearch(_ query: String) {
        searchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            searchResults = []
            isSearching = false
            return
        }
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 220_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run { isSearching = true }
            let results = await WeatherService.searchCities(query: trimmed)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                searchResults = results
                isSearching = false
            }
        }
    }

    private func advance() {
        if step < 2 {
            withAnimation(.easeInOut(duration: 0.2)) { step += 1 }
            return
        }

        ComfortStore.saveLocation(selectedCity)
        for city in savedPicks.reversed() {
            _ = ComfortStore.addSavedCity(city)
        }
        _ = ComfortStore.addSavedCity(selectedCity)

        var comfort = ComfortStore.loadComfortPreference()
        comfort.feelBaseline = feelBaseline
        comfort.style = style
        comfort.updatedAt = ISO8601DateFormatter().string(from: Date())
        ComfortStore.saveComfortPreference(comfort)
        ComfortStore.setOnboardingComplete(true)
        onFinished()
    }
}

#Preview {
    OnboardingView(onFinished: {})
}
