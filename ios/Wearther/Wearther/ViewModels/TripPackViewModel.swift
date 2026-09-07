import Foundation

@MainActor
final class TripPackViewModel: ObservableObject {
    @Published var destination: LocationResult?
    @Published var days = 3
    @Published var style: StyleMode
    @Published var alwaysPack: AlwaysPackPrefs
    @Published var units: TempUnits

    @Published var searchQuery = ""
    @Published var searchResults: [LocationResult] = []
    @Published var isSearching = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var plan: TripPackPlan?

    private var searchTask: Task<Void, Never>?
    private let warmthBias: Double
    private let feedbackCount: Int
    private let lastFeedback: ComfortFeedback?
    private let feelBaseline: FeelBaseline

    init(seedComfort: ComfortPreference = ComfortStore.loadComfortPreference()) {
        style = seedComfort.style
        alwaysPack = seedComfort.alwaysPack
        units = seedComfort.units
        warmthBias = seedComfort.warmthBias
        feedbackCount = seedComfort.feedbackCount
        lastFeedback = seedComfort.lastFeedback
        feelBaseline = seedComfort.feelBaseline
    }

    func updateSearchQuery(_ query: String) {
        searchQuery = query
        searchTask?.cancel()
        plan = nil
        errorMessage = nil

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

    func selectDestination(_ loc: LocationResult) {
        destination = loc
        searchQuery = ""
        searchResults = []
        plan = nil
        errorMessage = nil
    }

    func clearDestination() {
        destination = nil
        searchQuery = ""
        searchResults = []
        plan = nil
        errorMessage = nil
    }

    func buildPlan() async {
        guard let destination else {
            errorMessage = "Pick a destination first."
            return
        }

        isLoading = true
        errorMessage = nil
        let weather = await WeatherService.getWeather(for: destination)
        let comfort = ComfortPreference(
            warmthBias: warmthBias,
            feedbackCount: feedbackCount,
            lastFeedback: lastFeedback,
            updatedAt: ISO8601DateFormatter().string(from: Date()),
            feelBaseline: feelBaseline,
            style: style,
            alwaysPack: alwaysPack,
            units: units
        )
        plan = TripPackPlanner.plan(
            destinationName: destination.name,
            days: days,
            daily: weather.daily,
            comfort: comfort
        )
        if weather.daily.isEmpty {
            errorMessage = nil
        }
        isLoading = false
    }
}
