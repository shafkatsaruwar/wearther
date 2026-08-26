import Foundation

enum NotificationSettingsStore {
    private static let enabledKey = "wearther:notifications-enabled"
    private static let hourKey = "wearther:notifications-hour"
    private static let minuteKey = "wearther:notifications-minute"

    static var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: enabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: enabledKey) }
    }

    static var deliveryHour: Int {
        get {
            guard UserDefaults.standard.object(forKey: hourKey) != nil else { return 19 }
            return UserDefaults.standard.integer(forKey: hourKey)
        }
        set { UserDefaults.standard.set(newValue, forKey: hourKey) }
    }

    static var deliveryMinute: Int {
        get { UserDefaults.standard.integer(forKey: minuteKey) }
        set { UserDefaults.standard.set(newValue, forKey: minuteKey) }
    }
}
