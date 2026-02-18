import CoreDatabase
import CoreProviders
import CoreSecurity
import CoreSync
import FeatureAccounts
import FeatureDashboard
import FeatureSettings
import AppKit
import Foundation
import SwiftUI

@main
struct SparkAIApp: App {
    @State private var appContext: AppContext?
    @State private var selectedSection: TraySection = .dashboard

    var body: some Scene {
        MenuBarExtra("SparkAI", systemImage: "bolt.circle.fill") {
            MenuBarRootView(
                appContext: appContext,
                selectedSection: $selectedSection,
                onBootstrap: bootstrap
            )
        }
        .menuBarExtraStyle(.window)

        Settings {
            if let appContext {
                SettingsView(settingsStore: appContext.settingsStore, syncService: appContext.syncService)
                    .frame(minWidth: 420, minHeight: 320)
            } else {
                ProgressView("Starting SparkAI...")
                    .frame(width: 320, height: 120)
            }
        }
    }

    @MainActor
    private func bootstrap() async {
        guard appContext == nil else { return }
        do {
            configureMenuBarApp()
            let support = try fileSupportDirectory()
            let dbPath = support.appendingPathComponent("sparkai.sqlite").path
            let database = try DatabaseService(databasePath: dbPath)
            let notificationService = NotificationService()
            await notificationService.requestAuthorization()
            let settingsStore = SettingsStore()
            let syncSettings = settingsStore.load()

            let registry = AdapterRegistry(adapters: [
                OpenAIAdapter(),
                ClaudeAdapter(),
                CursorAdapter()
            ])
            let syncService = SyncService(
                database: database,
                registry: registry,
                notificationService: notificationService,
                settings: syncSettings
            )

            appContext = AppContext(
                database: database,
                syncService: syncService,
                settingsStore: settingsStore,
                credentialService: CredentialService()
            )

            Task.detached {
                await syncService.scheduleLoop()
            }
        } catch {
            print("SparkAI bootstrap failed: \(error)")
        }
    }

    private func fileSupportDirectory() throws -> URL {
        let url = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let appURL = url.appendingPathComponent("SparkAI", isDirectory: true)
        try FileManager.default.createDirectory(at: appURL, withIntermediateDirectories: true)
        return appURL
    }

    @MainActor
    private func configureMenuBarApp() {
        NSApplication.shared.setActivationPolicy(.accessory)
    }
}

struct AppContext {
    let database: DatabaseService
    let syncService: SyncService
    let settingsStore: SettingsStore
    let credentialService: CredentialService
}

struct RootView: View {
    let context: AppContext

    var body: some View {
        TabView {
            DashboardView(database: context.database, syncService: context.syncService)
                .tabItem { Label("Dashboard", systemImage: "chart.bar.fill") }

            AccountsView(database: context.database, credentialService: context.credentialService)
                .tabItem { Label("Accounts", systemImage: "person.3.fill") }

            SettingsView(settingsStore: context.settingsStore, syncService: context.syncService)
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}

private enum TraySection: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case accounts = "Accounts"
    case settings = "Settings"

    var id: String { rawValue }
}

private struct MenuBarRootView: View {
    let appContext: AppContext?
    @Binding var selectedSection: TraySection
    let onBootstrap: @MainActor () async -> Void

    var body: some View {
        Group {
            if let appContext {
                VStack(spacing: 12) {
                    Picker("Section", selection: $selectedSection) {
                        ForEach(TraySection.allCases) { section in
                            Text(section.rawValue).tag(section)
                        }
                    }
                    .pickerStyle(.segmented)

                    Group {
                        switch selectedSection {
                        case .dashboard:
                            DashboardView(database: appContext.database, syncService: appContext.syncService)
                        case .accounts:
                            AccountsView(database: appContext.database, credentialService: appContext.credentialService)
                        case .settings:
                            SettingsView(settingsStore: appContext.settingsStore, syncService: appContext.syncService)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    Divider()
                    HStack {
                        Button("Refresh") {
                            Task { await appContext.syncService.runOnce() }
                        }
                        Spacer()
                        Button("Quit SparkAI") {
                            NSApplication.shared.terminate(nil)
                        }
                    }
                }
                .padding(12)
                .frame(width: 520, height: 560)
            } else {
                ProgressView("Starting SparkAI...")
                    .frame(width: 260, height: 120)
                    .task {
                        await onBootstrap()
                    }
            }
        }
    }
}
