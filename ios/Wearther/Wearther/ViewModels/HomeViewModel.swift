import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var location: LocationResult
    @Published var weather: WeatherData?
    @Published var outfit: OutfitRecommendation?
    @Published var comfort: ComfortPreference
    @Published var isLoading = true
    @Published var errorMessage: String?

    @Published var searchQuery = ""
    @Published var searchResults: [LocationResult] = []
    @Published var isSearching = false
    @Published var isCityPickerOpen = false
    @Published var isCustomizeOpen = false

    private var searchTask: Task<Void, Never>?
    private var loadTask: Task<Void, Never>?

    init() {
        location = ComfortStore.loadSavedLocation()
        comfort = ComfortStore.loadComfortPreference()
    }

    func onAppear() {
        Task { await refreshWeather() }
    }

    func refreshWeather() async {
        loadTask?.cancel()
        loadTask = Task {
            isLoading = true
            errorMessage = nil

            let data = await WeatherService.getWeather(for: location)
            guard !Task.isCancelled else { return }

            weather = data
            comfort = ComfortStore.loadComfortPreference()
            outfit = OutfitRecommender.recommend(.init(weather: data, comfort: comfort))
            isLoading = false
        }
        await loadTask?.value
    }

    func selectLocation(_ loc: LocationResult) {
        ComfortStore.saveLocation(loc)
        location = loc
        isCityPickerOpen = false
        searchQuery = ""
        searchResults = []
        Task { await refreshWeather() }
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
            outfit = OutfitRecommender.recommend(.init(weather: weather, comfort: comfort))
        }
    }
}
