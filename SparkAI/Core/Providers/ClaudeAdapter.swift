import Foundation
import SharedContracts

public struct ClaudeAdapter: ProviderAdapter {
    public let provider: Provider = .claude

    public init() {}

    public func validateCredentials(account: Account, credential: String?) async throws {
        if account.authType == .manual { return }
        guard let credential, !credential.isEmpty else {
            throw ProviderError.auth("Missing Claude credential.")
        }
    }

    public func fetchUsage(account: Account, window: UsageWindow, credential: String?) async throws -> RawUsagePayload {
        if account.authType == .manual {
            return RawUsagePayload(
                accountId: account.id,
                provider: provider,
                window: window,
                used: 0,
                limit: 100,
                unit: "messages",
                source: .manual,
                confidence: .manual
            )
        }
        guard credential != nil else {
            throw ProviderError.auth("Credential unavailable for Claude account.")
        }

        // Placeholder for official endpoint integration.
        return RawUsagePayload(
            accountId: account.id,
            provider: provider,
            window: window,
            used: 48,
            limit: 100,
            unit: "messages",
            source: .officialApi,
            confidence: .estimated
        )
    }

    public func normalize(raw: RawUsagePayload) throws -> UsageSnapshot {
        let remaining = max(0, raw.limit - raw.used)
        let percent = raw.limit > 0 ? (remaining / raw.limit) * 100 : 0
        return try UsageSnapshot(
            accountId: raw.accountId,
            provider: raw.provider,
            windowType: raw.window.type,
            windowStart: raw.window.start,
            windowEnd: raw.window.end,
            usedValue: raw.used,
            usedUnit: raw.unit,
            limitValue: raw.limit,
            limitUnit: raw.unit,
            remainingValue: remaining,
            batteryPercent: percent,
            confidence: raw.confidence,
            source: raw.source
        )
    }
}
