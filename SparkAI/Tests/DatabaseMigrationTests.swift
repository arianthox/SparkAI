import CoreDatabase
import Foundation
import XCTest

final class DatabaseMigrationTests: XCTestCase {
    func testMigrationCreatesExpectedTables() async throws {
        let temp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".sqlite")
        let service = try DatabaseService(databasePath: temp.path)
        let names = try await service.dbQueue.read { db in
            try String.fetchAll(db, sql: "SELECT name FROM sqlite_master WHERE type = 'table'")
        }
        XCTAssertTrue(names.contains("accounts"))
        XCTAssertTrue(names.contains("usage_snapshots"))
        XCTAssertTrue(names.contains("usage_windows"))
        XCTAssertTrue(names.contains("battery_status"))
        XCTAssertTrue(names.contains("sync_runs"))
    }
}
