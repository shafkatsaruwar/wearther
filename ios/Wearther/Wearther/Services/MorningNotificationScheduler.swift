import Foundation
import UserNotifications

enum MorningNotificationScheduler {
    static let categoryId = "wearther.morning.fit"
    static let requestPrefix = "wearther.morning."

    static func requestAuthorizationIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            do {
                return try await center.requestAuthorization(options: [.alert, .sound, .badge])
            } catch {
                return false
            }
        @unknown default:
            return false
        }
    }

    static func reschedule(
        preference: NotificationPreference,
        locationName: String,
        weather: WeatherData?,
        outfit: OutfitRecommendation?
    ) async {
        let center = UNUserNotificationCenter.current()
        await cancelPending()

        guard preference.enabled else { return }
        guard await requestAuthorizationIfNeeded() else { return }
        guard let weather, let outfit else { return }

        let content = UNMutableNotificationContent()
        content.title = RemoteConfigStore.current.copy.notificationTitle
        content.body = FitCopy.notificationBody(
            locationName: locationName,
            weather: weather,
            outfit: outfit
        )
        content.sound = .default
        content.categoryIdentifier = categoryId

        let hours = preference.weekdaysOnly ? Array(2...6) : Array(1...7) // Sun=1 … Sat=7
        for weekday in hours {
            var date = DateComponents()
            date.weekday = weekday
            date.hour = preference.hour.rawValue
            date.minute = 0

            let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
            let request = UNNotificationRequest(
                identifier: "\(requestPrefix)\(weekday)",
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
        }
    }

    static func cancelPending() async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let ids = pending
            .map(\.identifier)
            .filter { $0.hasPrefix(requestPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }
}
