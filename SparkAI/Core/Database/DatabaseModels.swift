import Foundation
import GRDB
import SharedContracts

public struct AccountRecord: Codable, FetchableRecord, PersistableRecord {
    public static let databaseTableName = "accounts"

    public var id: String
    public var provider: String
    public var displayName: String
    public var workspaceIdentifier: String?
    public var authType: String
    public var syncEnabled: Bool
    public var syncIntervalSeconds: Int?
    public var credentialRef: String?
    public var lastValidatedAt: Date?
    public var expiresAt: Date?
    public var status: String
    public var lastError: String?
}

public struct UsageSnapshotRecord: Codable, FetchableRecord, PersistableRecord {
    public static let databaseTableName = "usage_snapshots"

    public var id: String
    public var accountId: String
    public var provider: String
    public var windowType: String
    public var windowStart: Date
    public var windowEnd: Date
    public var usedValue: Double
    public var usedUnit: String
    public var limitValue: Double
    public var limitUnit: String
    public var remainingValue: Double
    public var batteryPercent: Double
    public var confidence: String
    public var source: String
    public var fetchedAt: Date
}

public struct BatteryStatusRecord: Codable, FetchableRecord, PersistableRecord {
    public static let databaseTableName = "battery_status"

    public var id: String
    public var accountId: String
    public var batteryPercent: Double
    public var isLow: Bool
    public var threshold: Double
    public var health: String
    public var updatedAt: Date
}

public struct SyncRunRecord: Codable, FetchableRecord, PersistableRecord {
    public static let databaseTableName = "sync_runs"

    public var id: String
    public var accountId: String
    public var startedAt: Date
    public var endedAt: Date
    public var result: String
    public var errorType: String?
    public var errorMessage: String?
    public var retryCount: Int
}

public extension AccountRecord {
    init(_ account: Account) {
        self.id = account.id.uuidString
        self.provider = account.provider.rawValue
        self.displayName = account.displayName
        self.workspaceIdentifier = account.workspaceIdentifier
        self.authType = account.authType.rawValue
        self.syncEnabled = account.syncEnabled
        self.syncIntervalSeconds = account.syncIntervalSeconds
        self.credentialRef = account.credentialRef
        self.lastValidatedAt = account.lastValidatedAt
        self.expiresAt = account.expiresAt
        self.status = account.status.rawValue
        self.lastError = account.lastError
    }

    func toDomain() throws -> Account {
        try Account(
            id: UUID(uuidString: id) ?? UUID(),
            provider: Provider(rawValue: provider) ?? .openai,
            displayName: displayName,
            workspaceIdentifier: workspaceIdentifier,
            authType: AuthType(rawValue: authType) ?? .manual,
            syncEnabled: syncEnabled,
            syncIntervalSeconds: syncIntervalSeconds,
            credentialRef: credentialRef,
            lastValidatedAt: lastValidatedAt,
            expiresAt: expiresAt,
            status: AccountStatus(rawValue: status) ?? .unknown,
            lastError: lastError
        )
    }
}

public extension UsageSnapshotRecord {
    init(_ snapshot: UsageSnapshot) {
        self.id = snapshot.id.uuidString
        self.accountId = snapshot.accountId.uuidString
        self.provider = snapshot.provider.rawValue
        self.windowType = snapshot.windowType.rawValue
        self.windowStart = snapshot.windowStart
        self.windowEnd = snapshot.windowEnd
        self.usedValue = snapshot.usedValue
        self.usedUnit = snapshot.usedUnit
        self.limitValue = snapshot.limitValue
        self.limitUnit = snapshot.limitUnit
        self.remainingValue = snapshot.remainingValue
        self.batteryPercent = snapshot.batteryPercent
        self.confidence = snapshot.confidence.rawValue
        self.source = snapshot.source.rawValue
        self.fetchedAt = snapshot.fetchedAt
    }
}

public extension BatteryStatusRecord {
    init(_ status: BatteryStatus) {
        self.id = status.id.uuidString
        self.accountId = status.accountId.uuidString
        self.batteryPercent = status.batteryPercent
        self.isLow = status.isLow
        self.threshold = status.threshold
        self.health = status.health.rawValue
        self.updatedAt = status.updatedAt
    }
}

public extension SyncRunRecord {
    init(_ syncRun: SyncRun) {
        self.id = syncRun.id.uuidString
        self.accountId = syncRun.accountId.uuidString
        self.startedAt = syncRun.startedAt
        self.endedAt = syncRun.endedAt
        self.result = syncRun.result.rawValue
        self.errorType = syncRun.errorType
        self.errorMessage = syncRun.errorMessage
        self.retryCount = syncRun.retryCount
    }
}
