import Foundation
import GRDB
import SharedContracts

public actor DatabaseService {
    public let dbQueue: DatabaseQueue

    public init(databasePath: String) throws {
        dbQueue = try DatabaseQueue(path: databasePath)
        try Self.migrator.migrate(dbQueue)
    }

    public static let migrator: DatabaseMigrator = {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1_create_tables") { db in
            try db.create(table: "accounts") { t in
                t.column("id", .text).primaryKey()
                t.column("provider", .text).notNull()
                t.column("displayName", .text).notNull()
                t.column("workspaceIdentifier", .text)
                t.column("authType", .text).notNull()
                t.column("syncEnabled", .boolean).notNull().defaults(to: true)
                t.column("syncIntervalSeconds", .integer)
                t.column("credentialRef", .text)
                t.column("lastValidatedAt", .datetime)
                t.column("expiresAt", .datetime)
                t.column("status", .text).notNull().defaults(to: "unknown")
                t.column("lastError", .text)
            }

            try db.create(table: "usage_windows") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("accountId", .text).notNull().indexed()
                t.column("windowType", .text).notNull()
                t.column("windowStart", .datetime).notNull()
                t.column("windowEnd", .datetime).notNull()
                t.foreignKey(["accountId"], references: "accounts", onDelete: .cascade)
            }

            try db.create(table: "usage_snapshots") { t in
                t.column("id", .text).primaryKey()
                t.column("accountId", .text).notNull().indexed()
                t.column("provider", .text).notNull()
                t.column("windowType", .text).notNull()
                t.column("windowStart", .datetime).notNull()
                t.column("windowEnd", .datetime).notNull()
                t.column("usedValue", .double).notNull()
                t.column("usedUnit", .text).notNull()
                t.column("limitValue", .double).notNull()
                t.column("limitUnit", .text).notNull()
                t.column("remainingValue", .double).notNull()
                t.column("batteryPercent", .double).notNull()
                t.column("confidence", .text).notNull()
                t.column("source", .text).notNull()
                t.column("fetchedAt", .datetime).notNull().indexed()
                t.foreignKey(["accountId"], references: "accounts", onDelete: .cascade)
            }

            try db.create(index: "idx_snapshots_account_fetched", on: "usage_snapshots", columns: ["accountId", "fetchedAt"])

            try db.create(table: "battery_status") { t in
                t.column("id", .text).primaryKey()
                t.column("accountId", .text).notNull().indexed()
                t.column("batteryPercent", .double).notNull()
                t.column("isLow", .boolean).notNull()
                t.column("threshold", .double).notNull()
                t.column("health", .text).notNull()
                t.column("updatedAt", .datetime).notNull()
                t.foreignKey(["accountId"], references: "accounts", onDelete: .cascade)
            }

            try db.create(table: "sync_runs") { t in
                t.column("id", .text).primaryKey()
                t.column("accountId", .text).notNull().indexed()
                t.column("startedAt", .datetime).notNull()
                t.column("endedAt", .datetime).notNull()
                t.column("result", .text).notNull()
                t.column("errorType", .text)
                t.column("errorMessage", .text)
                t.column("retryCount", .integer).notNull().defaults(to: 0)
                t.foreignKey(["accountId"], references: "accounts", onDelete: .cascade)
            }
        }

        return migrator
    }()

    public func upsert(account: Account) throws {
        try dbQueue.write { db in
            let record = AccountRecord(account)
            try record.save(db)
        }
    }

    public func fetchAccounts() throws -> [Account] {
        try dbQueue.read { db in
            let records = try AccountRecord.fetchAll(db)
            return try records.map { try $0.toDomain() }
        }
    }

    public func insert(snapshot: UsageSnapshot) throws {
        try dbQueue.write { db in
            let record = UsageSnapshotRecord(snapshot)
            try record.insert(db)
        }
    }

    public func insert(status: BatteryStatus) throws {
        try dbQueue.write { db in
            let record = BatteryStatusRecord(status)
            try record.insert(db)
        }
    }

    public func insert(syncRun: SyncRun) throws {
        try dbQueue.write { db in
            let record = SyncRunRecord(syncRun)
            try record.insert(db)
        }
    }

    public func recentSnapshots(accountId: UUID, limit: Int = 20) throws -> [UsageSnapshotRecord] {
        try dbQueue.read { db in
            try UsageSnapshotRecord
                .filter(sql: "accountId = ?", arguments: [accountId.uuidString])
                .order(Column("fetchedAt").desc)
                .limit(limit)
                .fetchAll(db)
        }
    }
}
