import Foundation

public enum Provider: String, Codable, CaseIterable, Sendable {
    case openai
    case claude
    case cursor
}

public enum AuthType: String, Codable, CaseIterable, Sendable {
    case apiKey
    case session
    case manual
}

public enum AccountStatus: String, Codable, CaseIterable, Sendable {
    case valid
    case invalid
    case unknown
}

public enum WindowType: String, Codable, CaseIterable, Sendable {
    case daily
    case weekly
    case monthly
    case rolling30Day
}

public enum UsageConfidence: String, Codable, CaseIterable, Sendable {
    case exact
    case estimated
    case manual
}

public enum UsageSource: String, Codable, CaseIterable, Sendable {
    case officialApi
    case officialExport
    case manual
}

public enum HealthBadge: String, Codable, CaseIterable, Sendable {
    case healthy
    case degraded
    case failing
    case unknown
}

public struct Account: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public var provider: Provider
    public var displayName: String
    public var workspaceIdentifier: String?
    public var authType: AuthType
    public var syncEnabled: Bool
    public var syncIntervalSeconds: Int?
    public var credentialRef: String?
    public var lastValidatedAt: Date?
    public var expiresAt: Date?
    public var status: AccountStatus
    public var lastError: String?

    public init(
        id: UUID = UUID(),
        provider: Provider,
        displayName: String,
        workspaceIdentifier: String? = nil,
        authType: AuthType,
        syncEnabled: Bool = true,
        syncIntervalSeconds: Int? = nil,
        credentialRef: String? = nil,
        lastValidatedAt: Date? = nil,
        expiresAt: Date? = nil,
        status: AccountStatus = .unknown,
        lastError: String? = nil
    ) throws {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw ValidationError.invalidAccountDisplayName
        }
        if let interval = syncIntervalSeconds {
            guard (30...3600).contains(interval) else {
                throw ValidationError.invalidSyncInterval
            }
        }
        self.id = id
        self.provider = provider
        self.displayName = trimmed
        self.workspaceIdentifier = workspaceIdentifier
        self.authType = authType
        self.syncEnabled = syncEnabled
        self.syncIntervalSeconds = syncIntervalSeconds
        self.credentialRef = credentialRef
        self.lastValidatedAt = lastValidatedAt
        self.expiresAt = expiresAt
        self.status = status
        self.lastError = lastError
    }
}

public struct UsageWindow: Codable, Equatable, Sendable {
    public var type: WindowType
    public var start: Date
    public var end: Date

    public init(type: WindowType, start: Date, end: Date) throws {
        guard start <= end else {
            throw ValidationError.invalidUsageWindow
        }
        self.type = type
        self.start = start
        self.end = end
    }
}

public struct UsageSnapshot: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public let accountId: UUID
    public let provider: Provider
    public let windowType: WindowType
    public let windowStart: Date
    public let windowEnd: Date
    public let usedValue: Double
    public let usedUnit: String
    public let limitValue: Double
    public let limitUnit: String
    public let remainingValue: Double
    public let batteryPercent: Double
    public let confidence: UsageConfidence
    public let source: UsageSource
    public let fetchedAt: Date

    public init(
        id: UUID = UUID(),
        accountId: UUID,
        provider: Provider,
        windowType: WindowType,
        windowStart: Date,
        windowEnd: Date,
        usedValue: Double,
        usedUnit: String,
        limitValue: Double,
        limitUnit: String,
        remainingValue: Double,
        batteryPercent: Double,
        confidence: UsageConfidence,
        source: UsageSource,
        fetchedAt: Date = Date()
    ) throws {
        guard usedValue >= 0, limitValue > 0, remainingValue >= 0 else {
            throw ValidationError.invalidUsageValues
        }
        guard (0...100).contains(batteryPercent) else {
            throw ValidationError.invalidBatteryPercent
        }
        self.id = id
        self.accountId = accountId
        self.provider = provider
        self.windowType = windowType
        self.windowStart = windowStart
        self.windowEnd = windowEnd
        self.usedValue = usedValue
        self.usedUnit = usedUnit
        self.limitValue = limitValue
        self.limitUnit = limitUnit
        self.remainingValue = remainingValue
        self.batteryPercent = batteryPercent
        self.confidence = confidence
        self.source = source
        self.fetchedAt = fetchedAt
    }
}

public struct BatteryStatus: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public let accountId: UUID
    public let batteryPercent: Double
    public let isLow: Bool
    public let threshold: Double
    public let health: HealthBadge
    public let updatedAt: Date

    public init(
        id: UUID = UUID(),
        accountId: UUID,
        batteryPercent: Double,
        threshold: Double,
        health: HealthBadge,
        updatedAt: Date = Date()
    ) throws {
        guard (0...100).contains(batteryPercent), (0...100).contains(threshold) else {
            throw ValidationError.invalidBatteryPercent
        }
        self.id = id
        self.accountId = accountId
        self.batteryPercent = batteryPercent
        self.isLow = batteryPercent <= threshold
        self.threshold = threshold
        self.health = health
        self.updatedAt = updatedAt
    }
}

public struct SyncRun: Codable, Identifiable, Equatable, Sendable {
    public enum Result: String, Codable, CaseIterable, Sendable {
        case success
        case failure
    }

    public let id: UUID
    public let accountId: UUID
    public let startedAt: Date
    public let endedAt: Date
    public let result: Result
    public let errorType: String?
    public let errorMessage: String?
    public let retryCount: Int

    public init(
        id: UUID = UUID(),
        accountId: UUID,
        startedAt: Date,
        endedAt: Date,
        result: Result,
        errorType: String? = nil,
        errorMessage: String? = nil,
        retryCount: Int = 0
    ) throws {
        guard startedAt <= endedAt else {
            throw ValidationError.invalidSyncRunDates
        }
        self.id = id
        self.accountId = accountId
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.result = result
        self.errorType = errorType
        self.errorMessage = errorMessage
        self.retryCount = retryCount
    }
}

public enum ValidationError: Error, LocalizedError {
    case invalidAccountDisplayName
    case invalidSyncInterval
    case invalidUsageWindow
    case invalidUsageValues
    case invalidBatteryPercent
    case invalidSyncRunDates

    public var errorDescription: String? {
        switch self {
        case .invalidAccountDisplayName:
            return "Display name is required."
        case .invalidSyncInterval:
            return "Sync interval must be between 30 and 3600 seconds."
        case .invalidUsageWindow:
            return "Usage window start must be before end."
        case .invalidUsageValues:
            return "Usage values must be non-negative and limit > 0."
        case .invalidBatteryPercent:
            return "Battery percentage must be between 0 and 100."
        case .invalidSyncRunDates:
            return "Sync run start date must be before end date."
        }
    }
}
