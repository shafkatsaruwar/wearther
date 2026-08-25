import Foundation
import UserNotifications

enum NotificationService {
    static let tomorrowAlertID = "wearther.tomorrow.alert"

    static func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    static func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    static func scheduleTomorrowAlert(
        alert: WeatherAlert,
        deliveryHour: Int = NotificationSettingsStore.deliveryHour,
        deliveryMinute: Int = NotificationSettingsStore.deliveryMinute
    ) async {
        guard NotificationSettingsStore.isEnabled else { return }

        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [tomorrowAlertID])

        let content = UNMutableNotificationContent()
        content.title = alert.title
        content.body = alert.body
        content.sound = .default

        let triggerDate = nextDeliveryDate(hour: deliveryHour, minute: deliveryMinute)
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: triggerDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: tomorrowAlertID,
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
        } catch {
            // Scheduling can fail if permissions were revoked.
        }
    }

    static func cancelTomorrowAlerts() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [tomorrowAlertID])
    }

    static func nextDeliveryDate(
        hour: Int = NotificationSettingsStore.deliveryHour,
        minute: Int = NotificationSettingsStore.deliveryMinute
    ) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute
        components.second = 0

        var date = Calendar.current.date(from: components) ?? Date()
        if date <= Date() {
            date = Calendar.current.date(byAdding: .day, value: 1, to: date) ?? date
        }
        return date
    }

    static func formattedNextDeliveryTime() -> String {
        nextDeliveryDate().formatted(date: .omitted, time: .shortened)
    }
}
