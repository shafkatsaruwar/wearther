import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var location: LocationResult
    @Published var weather: WeatherData?
    @Published var outfit: OutfitRecommendation?
    @Published var tomorrowOutfit: OutfitRecommendation?
    @Published var comfort: ComfortPreference
    @Published var isLoading = true
    @Published var errorMessage: String?

    @Published var searchQuery = ""
    @Published var searchResults: [LocationResult] = []
    @Published var isSearching = false
    @Published var isCityPickerOpen = false

    @Published var notificationsEnabled: Bool = NotificationSettingsStore.isEnabled
    @Published var notificationPreview: WeatherAlert?
    @Published var notificationPermissionDenied = false

    private var searchTask: Task<Void, Never>?
    private var loadTask: Task<Void, Never>?

    init() {
        location = ComfortStore.loadSavedLocation()
        comfort = ComfortStore.loadComfortPreference()
    }

    func onAppear() {
        Task {
            await syncNotificationPermissionState()
            await refreshWeather()
        }
    }

    func refreshWeather() async {
        loadTask?.cancel()
        loadTask = Task {
            isLoading = true
            errorMessage = nil

            let data = await WeatherService.getWeather(for: location)
            guard !Task.isCancelled else { return }

            if data.hourly.isEmpty && data.temperature == 72 {
                // Possible fallback — still show data
            }

            weather = data
            comfort = ComfortStore.loadComfortPreference()
            outfit = OutfitRecommender.recommend(.init(weather: data, comfort: comfort))
            if let tomorrow = data.tomorrow {
                tomorrowOutfit = OutfitRecommender.recommendForTomorrow(
                    tomorrow,
                    locationName: location.name,
                    comfort: comfort
                )
            } else {
                tomorrowOutfit = nil
            }
            await refreshNotificationSchedule()
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
        if let weather {
            outfit = OutfitRecommender.recommend(.init(weather: weather, comfort: comfort))
            if let tomorrow = weather.tomorrow {
                tomorrowOutfit = OutfitRecommender.recommendForTomorrow(
                    tomorrow,
                    locationName: location.name,
                    comfort: comfort
                )
            }
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

    func setNotificationsEnabled(_ enabled: Bool) async {
        if enabled {
            let status = await NotificationService.authorizationStatus()
            if status == .denied {
                notificationPermissionDenied = true
                notificationsEnabled = false
                NotificationSettingsStore.isEnabled = false
                return
            }

            if status == .notDetermined {
                let granted = await NotificationService.requestAuthorization()
                guard granted else {
                    notificationPermissionDenied = true
                    notificationsEnabled = false
                    NotificationSettingsStore.isEnabled = false
                    return
                }
            }

            notificationPermissionDenied = false
            NotificationSettingsStore.isEnabled = true
            notificationsEnabled = true
            await refreshNotificationSchedule()
        } else {
            NotificationSettingsStore.isEnabled = false
            notificationsEnabled = false
            NotificationService.cancelTomorrowAlerts()
            notificationPreview = nil
        }
    }

    private func refreshNotificationSchedule() async {
        guard let tomorrow = weather?.tomorrow else {
            notificationPreview = nil
            return
        }

        let alert = WeatherAlertPlanner.plan(for: tomorrow, cityName: location.name)
        notificationPreview = alert

        guard notificationsEnabled, let alert else {
            if !notificationsEnabled {
                NotificationService.cancelTomorrowAlerts()
            }
            return
        }

        let status = await NotificationService.authorizationStatus()
        guard status == .authorized || status == .provisional || status == .ephemeral else {
            notificationPermissionDenied = status == .denied
            return
        }

        await NotificationService.scheduleTomorrowAlert(alert: alert)
    }

    private func syncNotificationPermissionState() async {
        let status = await NotificationService.authorizationStatus()
        if status == .denied {
            notificationPermissionDenied = notificationsEnabled
            if notificationsEnabled {
                notificationsEnabled = false
                NotificationSettingsStore.isEnabled = false
                NotificationService.cancelTomorrowAlerts()
            }
        } else {
            notificationPermissionDenied = false
        }
    }
}
