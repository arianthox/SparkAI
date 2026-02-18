import CoreDatabase
import CoreSecurity
import CoreSync
import FeatureAccounts
import FeatureSettings
import Foundation
import XCTest

final class FeatureViewModelTests: XCTestCase {
    func testSettingsViewModelSavePersists() async throws {
        let defaults = UserDefaults(suiteName: "sparkai.tests.\(UUID().uuidString)")!
        let store = SettingsStore(defaults: defaults)
        let dbPath = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".sqlite").path
        let database = try DatabaseService(databasePath: dbPath)
        let sync = SyncService(
            database: database,
            registry: AdapterRegistry(adapters: []),
            notificationService: NotificationService()
        )

        let model = await MainActor.run { SettingsViewModel(settingsStore: store, syncService: sync) }
        await MainActor.run {
            model.settings.defaultIntervalSeconds = 180
            model.settings.lowBatteryThreshold = 15
            model.save()
        }
        XCTAssertEqual(store.load().defaultIntervalSeconds, 180)
        XCTAssertEqual(store.load().lowBatteryThreshold, 15)
    }

    func testAccountsViewModelAddsSampleAccount() async throws {
        let dbPath = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".sqlite").path
        let database = try DatabaseService(databasePath: dbPath)
        let model = await MainActor.run {
            AccountsViewModel(database: database, credentialService: CredentialService())
        }
        await model.addSampleAccount()
        await model.load()
        let count = await MainActor.run { model.accounts.count }
        XCTAssertEqual(count, 1)
    }
}
