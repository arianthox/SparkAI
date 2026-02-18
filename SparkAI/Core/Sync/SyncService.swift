import CoreDatabase
import CoreLogging
import CoreProviders
import Foundation
import SharedContracts

public struct SyncSettings: Codable, Equatable, Sendable {
    public var defaultIntervalSeconds: Int
    public var lowBatteryThreshold: Double
    public var debugLoggingEnabled: Bool

    public init(defaultIntervalSeconds: Int = 120, lowBatteryThreshold: Double = 20, debugLoggingEnabled: Bool = false) {
        self.defaultIntervalSeconds = max(30, defaultIntervalSeconds)
        self.lowBatteryThreshold = min(max(0, lowBatteryThreshold), 100)
        self.debugLoggingEnabled = debugLoggingEnabled
    }
}

public struct AdapterRegistry: Sendable {
    private let adapters: [Provider: any ProviderAdapter]

    public init(adapters: [any ProviderAdapter]) {
        var map: [Provider: any ProviderAdapter] = [:]
        for adapter in adapters {
            map[adapter.provider] = adapter
        }
        self.adapters = map
    }

    public func adapter(for provider: Provider) -> (any ProviderAdapter)? {
        adapters[provider]
    }
}

public actor SyncService {
    private let database: DatabaseService
    private let registry: AdapterRegistry
    private let logger = RedactingLogger(category: "sync")
    private let notificationService: NotificationService
    private var settings: SyncSettings
    private var retryCounts: [UUID: Int] = [:]

    public init(
        database: DatabaseService,
        registry: AdapterRegistry,
        notificationService: NotificationService,
        settings: SyncSettings = .init()
    ) {
        self.database = database
        self.registry = registry
        self.notificationService = notificationService
        self.settings = settings
    }

    public func updateSettings(_ settings: SyncSettings) {
        self.settings = settings
    }

    public func runOnce() async {
        let accounts: [Account]
        do {
            accounts = try await database.fetchAccounts().filter(\.syncEnabled)
        } catch {
            logger.error("Failed to load accounts", metadata: ["error": "\(error)"])
            return
        }

        await withTaskGroup(of: Void.self) { group in
            for account in accounts {
                group.addTask { [weak self] in
                    await self?.syncAccount(account)
                }
            }
        }
    }

    public func scheduleLoop() async {
        while true {
            await runOnce()
            let jitter = Int.random(in: 0...15)
            let interval = settings.defaultIntervalSeconds + jitter
            try? await Task.sleep(nanoseconds: UInt64(interval) * 1_000_000_000)
        }
    }

    private func syncAccount(_ account: Account) async {
        let startedAt = Date()
        let retryCount = retryCounts[account.id, default: 0]

        guard let adapter = registry.adapter(for: account.provider) else {
            await recordFailure(account: account, startedAt: startedAt, retryCount: retryCount, error: ProviderError.unsupported("No adapter"))
            return
        }

        do {
            let window = try defaultWindow()
            try await adapter.validateCredentials(account: account, credential: nil)
            let raw = try await adapter.fetchUsage(account: account, window: window, credential: nil)
            let snapshot = try adapter.normalize(raw: raw)
            try await database.insert(snapshot: snapshot)

            let health: HealthBadge = snapshot.batteryPercent <= settings.lowBatteryThreshold ? .degraded : .healthy
            let status = try BatteryStatus(
                accountId: account.id,
                batteryPercent: snapshot.batteryPercent,
                threshold: settings.lowBatteryThreshold,
                health: health
            )
            try await database.insert(status: status)
            let run = try SyncRun(
                accountId: account.id,
                startedAt: startedAt,
                endedAt: Date(),
                result: .success,
                retryCount: retryCount
            )
            try await database.insert(syncRun: run)

            retryCounts[account.id] = 0
            if status.isLow {
                await notificationService.sendLowBatteryNotification(account: account, batteryPercent: status.batteryPercent)
            }
            logger.debug(
                "Sync success",
                metadata: [
                    "accountId": account.id.uuidString,
                    "provider": account.provider.rawValue
                ],
                enabled: settings.debugLoggingEnabled
            )
        } catch {
            await recordFailure(account: account, startedAt: startedAt, retryCount: retryCount, error: error)
        }
    }

    private func recordFailure(account: Account, startedAt: Date, retryCount: Int, error: Error) async {
        let nextRetry = min(6, retryCount + 1)
        retryCounts[account.id] = nextRetry

        let run = try? SyncRun(
            accountId: account.id,
            startedAt: startedAt,
            endedAt: Date(),
            result: .failure,
            errorType: "\(type(of: error))",
            errorMessage: "\(error)",
            retryCount: nextRetry
        )

        if let run {
            try? await database.insert(syncRun: run)
        }

        logger.error(
            "Sync failed",
            metadata: [
                "accountId": account.id.uuidString,
                "retryCount": "\(nextRetry)",
                "error": "\(error)"
            ]
        )

        if nextRetry >= 3 {
            await notificationService.sendPersistentSyncFailure(account: account, message: "Repeated sync failures detected.")
        }

        let backoffSeconds = Self.backoffSeconds(retryCount: nextRetry)
        try? await Task.sleep(nanoseconds: UInt64(backoffSeconds) * 1_000_000_000)
    }

    private func defaultWindow() throws -> UsageWindow {
        let calendar = Calendar.current
        let now = Date()
        let start = calendar.date(byAdding: .day, value: -30, to: now) ?? now
        return try UsageWindow(type: .rolling30Day, start: start, end: now)
    }

    public static func backoffSeconds(retryCount: Int) -> Int {
        Int(pow(2.0, Double(min(6, max(0, retryCount)))))
    }
}
