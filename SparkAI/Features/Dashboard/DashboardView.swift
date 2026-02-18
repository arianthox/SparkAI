import CoreDatabase
import CoreSync
import SharedContracts
import SwiftUI

public struct DashboardView: View {
    @StateObject private var model: DashboardViewModel

    public init(database: DatabaseService, syncService: SyncService) {
        _model = StateObject(wrappedValue: DashboardViewModel(database: database, syncService: syncService))
    }

    public var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("SparkAI Dashboard")
                        .font(.title2)
                        .bold()
                    Spacer()
                    Button("Refresh Now") {
                        Task { await model.refresh() }
                    }
                }

                if model.accounts.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "bolt.horizontal.circle")
                            .font(.system(size: 32))
                            .foregroundStyle(.secondary)
                        Text("No Accounts")
                            .font(.headline)
                        Text("Add an account in the Accounts tab to begin syncing usage.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(model.accounts) { account in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(account.displayName).bold()
                                Spacer()
                                Text(account.provider.rawValue.capitalized)
                                    .foregroundStyle(.secondary)
                            }
                            Text("Status: \(account.status.rawValue)")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .padding()
            .task { await model.load() }
        }
    }
}

@MainActor
public final class DashboardViewModel: ObservableObject {
    @Published public var accounts: [Account] = []

    private let database: DatabaseService
    private let syncService: SyncService

    public init(database: DatabaseService, syncService: SyncService) {
        self.database = database
        self.syncService = syncService
    }

    public func load() async {
        do {
            accounts = try await database.fetchAccounts()
        } catch {
            accounts = []
        }
    }

    public func refresh() async {
        await syncService.runOnce()
        await load()
    }
}
