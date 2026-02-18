import Foundation
import UserNotifications
import SharedContracts

public actor NotificationService {
    private var lastSentAtByKey: [String: Date] = [:]
    private let debounceSeconds: TimeInterval

    public init(debounceSeconds: TimeInterval = 900) {
        self.debounceSeconds = debounceSeconds
    }

    public func requestAuthorization() async {
        guard notificationsSupportedInCurrentRuntime() else { return }
        let center = await MainActor.run { UNUserNotificationCenter.current() }
        _ = try? await center.requestAuthorization(options: [.alert, .sound])
    }

    public func sendLowBatteryNotification(account: Account, batteryPercent: Double) async {
        guard notificationsSupportedInCurrentRuntime() else { return }
        let key = "low-battery-\(account.id.uuidString)"
        guard shouldSend(key: key) else { return }

        let content = UNMutableNotificationContent()
        content.title = "SparkAI: Low battery"
        content.body = "\(account.displayName) is at \(Int(batteryPercent))%."
        content.sound = .default

        let request = UNNotificationRequest(identifier: key, content: content, trigger: nil)
        let center = await MainActor.run { UNUserNotificationCenter.current() }
        _ = try? await center.add(request)
    }

    public func sendPersistentSyncFailure(account: Account, message: String) async {
        guard notificationsSupportedInCurrentRuntime() else { return }
        let key = "sync-failure-\(account.id.uuidString)"
        guard shouldSend(key: key) else { return }

        let content = UNMutableNotificationContent()
        content.title = "SparkAI: Sync issue"
        content.body = "\(account.displayName): \(message)"
        content.sound = .default

        let request = UNNotificationRequest(identifier: key, content: content, trigger: nil)
        let center = await MainActor.run { UNUserNotificationCenter.current() }
        _ = try? await center.add(request)
    }

    private func shouldSend(key: String) -> Bool {
        let now = Date()
        if let last = lastSentAtByKey[key], now.timeIntervalSince(last) < debounceSeconds {
            return false
        }
        lastSentAtByKey[key] = now
        return true
    }

    private func notificationsSupportedInCurrentRuntime() -> Bool {
        let bundlePath = Bundle.main.bundleURL.path
        // `swift run` executes from .build without an app bundle proxy for UserNotifications.
        if bundlePath.contains("/.build/") {
            return false
        }
        return true
    }
}
