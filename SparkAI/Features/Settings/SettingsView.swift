import CoreSync
import SwiftUI

public struct SettingsView: View {
    @StateObject private var model: SettingsViewModel

    public init(settingsStore: SettingsStore, syncService: SyncService) {
        _model = StateObject(wrappedValue: SettingsViewModel(settingsStore: settingsStore, syncService: syncService))
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Sync") {
                    Stepper(value: $model.settings.defaultIntervalSeconds, in: 30...600, step: 30) {
                        Text("Interval: \(model.settings.defaultIntervalSeconds)s")
                    }
                }
                Section("Notifications") {
                    Slider(value: $model.settings.lowBatteryThreshold, in: 1...50, step: 1)
                    Text("Low battery threshold: \(Int(model.settings.lowBatteryThreshold))%")
                        .foregroundStyle(.secondary)
                }
                Section("Diagnostics") {
                    Toggle("Enable debug logs", isOn: $model.settings.debugLoggingEnabled)
                }
                Button("Save Settings") {
                    model.save()
                }
            }
            .padding()
        }
    }
}

@MainActor
public final class SettingsViewModel: ObservableObject {
    @Published public var settings: SyncSettings

    private let store: SettingsStore
    private let syncService: SyncService

    public init(settingsStore: SettingsStore, syncService: SyncService) {
        self.store = settingsStore
        self.syncService = syncService
        self.settings = settingsStore.load()
    }

    public func save() {
        store.save(settings)
        Task { await syncService.updateSettings(settings) }
    }
}
