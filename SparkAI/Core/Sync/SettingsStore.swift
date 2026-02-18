import Foundation

public final class SettingsStore: @unchecked Sendable {
    private enum Keys {
        static let interval = "sync.defaultIntervalSeconds"
        static let threshold = "notifications.lowBatteryThreshold"
        static let debug = "logging.debugEnabled"
    }

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() -> SyncSettings {
        let interval = defaults.integer(forKey: Keys.interval)
        let threshold = defaults.double(forKey: Keys.threshold)
        let debug = defaults.bool(forKey: Keys.debug)

        return SyncSettings(
            defaultIntervalSeconds: interval == 0 ? 120 : interval,
            lowBatteryThreshold: threshold == 0 ? 20 : threshold,
            debugLoggingEnabled: debug
        )
    }

    public func save(_ settings: SyncSettings) {
        defaults.set(settings.defaultIntervalSeconds, forKey: Keys.interval)
        defaults.set(settings.lowBatteryThreshold, forKey: Keys.threshold)
        defaults.set(settings.debugLoggingEnabled, forKey: Keys.debug)
    }
}
