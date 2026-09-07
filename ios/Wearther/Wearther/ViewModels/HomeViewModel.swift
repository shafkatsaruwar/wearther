import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var location: LocationResult
    @Published var weather: WeatherData?
    @Published var outfit: OutfitRecommendation?
    @Published var comfort: ComfortPreference
    @Published var notifications: NotificationPreference
    @Published var isLoading = true
    @Published var isRefreshing = false
    @Published var errorMessage: String?

    @Published var searchQuery = ""
    @Published var searchResults: [LocationResult] = []
    @Published var isSearching = false
    @Published var isCityPickerOpen = false
    @Published var isCustomizeOpen = false
    @Published var savedCities: [LocationResult] = []
    @Published var isLocating = false
    @Published var locateErrorMessage: String?

    private var searchTask: Task<Void, Never>?
    private var loadTask: Task<Void, Never>?
    private var locateTask: Task<Void, Never>?

    init() {
        location = ComfortStore.loadSavedLocation()
        comfort = ComfortStore.loadComfortPreference()
        notifications = ComfortStore.loadNotificationPreference()
        savedCities = ComfortStore.loadSavedCities()
    }

    func onAppear() {
        Task { await refreshWeather() }
    }

    func refreshWeather(showFullLoading: Bool? = nil) async {
        loadTask?.cancel()
        loadTask = Task {
            let fullScreen = showFullLoading ?? (weather == nil)
            if fullScreen {
                isLoading = true
            } else {
                isRefreshing = true
            }
            errorMessage = nil

            let data = await WeatherService.getWeather(for: location)
            guard !Task.isCancelled else { return }

            weather = data
            comfort = ComfortStore.loadComfortPreference()
            let recommendation = OutfitRecommender.recommend(.init(weather: data, comfort: comfort))
            outfit = recommendation
            WidgetSnapshotStore.saveFromApp(
                location: location,
                weather: data,
                outfit: recommendation,
                comfort: comfort
            )
            await MorningNotificationScheduler.reschedule(
                preference: notifications,
                locationName: location.name,
                weather: data,
                outfit: recommendation
            )
            isLoading = false
            isRefreshing = false
        }
        await loadTask?.value
    }

    func selectLocation(_ loc: LocationResult) {
        ComfortStore.saveLocation(loc)
        location = loc
        isCityPickerOpen = false
        searchQuery = ""
        searchResults = []
        locateErrorMessage = nil
        Task { await refreshWeather() }
    }

    func locateMe() {
        locateTask?.cancel()
        locateTask = Task {
            isLocating = true
            locateErrorMessage = nil
            do {
                let place = try await LocationService.shared.locateCurrentPlace()
                guard !Task.isCancelled else { return }
                // Persist + refresh; city header updates from `location.name`.
                ComfortStore.saveLocation(place)
                _ = ComfortStore.addSavedCity(place)
                savedCities = ComfortStore.loadSavedCities()
                location = place
                isCityPickerOpen = false
                searchQuery = ""
                searchResults = []
                locateErrorMessage = nil
                await refreshWeather(showFullLoading: true)
            } catch {
                guard !Task.isCancelled else { return }
                locateErrorMessage = (error as? LocalizedError)?.errorDescription
                    ?? "Couldn’t find your location."
            }
            isLocating = false
        }
    }

    func isSaved(_ loc: LocationResult) -> Bool {
        savedCities.contains(where: { $0.id == loc.id })
    }

    func toggleSavedCity(_ loc: LocationResult) {
        savedCities = ComfortStore.toggleSavedCity(loc)
    }

    func submitFeedback(_ feedback: ComfortFeedback) {
        comfort = ComfortStore.applyFeedback(comfort, feedback: feedback)
        recomputeOutfit()
    }

    func updateFeelBaseline(_ value: FeelBaseline) {
        comfort.feelBaseline = value
        comfort.updatedAt = ISO8601DateFormatter().string(from: Date())
        ComfortStore.saveComfortPreference(comfort)
        recomputeOutfit()
    }

    func updateStyle(_ value: StyleMode) {
        comfort.style = value
        comfort.updatedAt = ISO8601DateFormatter().string(from: Date())
        ComfortStore.saveComfortPreference(comfort)
        recomputeOutfit()
    }

    func updateAlwaysPack(rainJacket: Bool? = nil, lightLayer: Bool? = nil, scarf: Bool? = nil) {
        if let rainJacket { comfort.alwaysPack.rainJacket = rainJacket }
        if let lightLayer { comfort.alwaysPack.lightLayer = lightLayer }
        if let scarf { comfort.alwaysPack.scarf = scarf }
        comfort.updatedAt = ISO8601DateFormatter().string(from: Date())
        ComfortStore.saveComfortPreference(comfort)
        recomputeOutfit()
    }

    func updateUnits(_ value: TempUnits) {
        comfort.units = value
        comfort.updatedAt = ISO8601DateFormatter().string(from: Date())
        ComfortStore.saveComfortPreference(comfort)
        if let weather, let outfit {
            WidgetSnapshotStore.saveFromApp(
                location: location,
                weather: weather,
                outfit: outfit,
                comfort: comfort
            )
        }
    }

    func updateNotifications(enabled: Bool? = nil, hour: MorningNotifyHour? = nil, weekdaysOnly: Bool? = nil) {
        if let enabled { notifications.enabled = enabled }
        if let hour { notifications.hour = hour }
        if let weekdaysOnly { notifications.weekdaysOnly = weekdaysOnly }
        ComfortStore.saveNotificationPreference(notifications)
        Task {
            await MorningNotificationScheduler.reschedule(
                preference: notifications,
                locationName: location.name,
                weather: weather,
                outfit: outfit
            )
        }
    }

    func updateSearchQuery(_ query: String) {
        searchQuery = query
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
            isSearching = true
            let results = await WeatherService.searchCities(query: trimmed)
            guard !Task.isCancelled else { return }
            searchResults = results
            isSearching = false
        }
    }

    var dateLabel: String {
        Date().formatted(.dateTime.weekday(.wide).month(.wide).day())
    }

    private func recomputeOutfit() {
        if let weather {
            let recommendation = OutfitRecommender.recommend(.init(weather: weather, comfort: comfort))
            outfit = recommendation
            WidgetSnapshotStore.saveFromApp(
                location: location,
                weather: weather,
                outfit: recommendation,
                comfort: comfort
            )
            Task {
                await MorningNotificationScheduler.reschedule(
                    preference: notifications,
                    locationName: location.name,
                    weather: weather,
                    outfit: recommendation
                )
            }
        }
    }
}
