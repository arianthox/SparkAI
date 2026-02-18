import CoreDatabase
import CoreSecurity
import SharedContracts
import SwiftUI

public struct AccountsView: View {
    @StateObject private var model: AccountsViewModel

    public init(database: DatabaseService, credentialService: CredentialService) {
        _model = StateObject(wrappedValue: AccountsViewModel(database: database, credentialService: credentialService))
    }

    public var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Accounts")
                        .font(.title2)
                        .bold()
                    Spacer()
                    Button("Add Sample") {
                        Task { await model.addSampleAccount() }
                    }
                }

                List(model.accounts) { account in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(account.displayName).bold()
                            Spacer()
                            Text(account.provider.rawValue.capitalized)
                        }
                        Text("Auth: \(account.authType.rawValue)")
                            .foregroundStyle(.secondary)
                        if let workspace = account.workspaceIdentifier, !workspace.isEmpty {
                            Text("Workspace: \(workspace)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .listStyle(.plain)
            }
            .padding()
            .task { await model.load() }
        }
    }
}

@MainActor
public final class AccountsViewModel: ObservableObject {
    @Published public var accounts: [Account] = []

    private let database: DatabaseService
    private let credentialService: CredentialService

    public init(database: DatabaseService, credentialService: CredentialService) {
        self.database = database
        self.credentialService = credentialService
    }

    public func load() async {
        do {
            accounts = try await database.fetchAccounts()
        } catch {
            accounts = []
        }
    }

    public func addSampleAccount() async {
        do {
            var account = try Account(
                provider: .openai,
                displayName: "OpenAI Primary",
                workspaceIdentifier: "default",
                authType: .manual,
                syncEnabled: true,
                syncIntervalSeconds: 120,
                status: .unknown
            )
            let metadata = try credentialService.saveSecret(accountId: account.id, authType: .manual, secret: "manual")
            account.credentialRef = metadata.keychainAccount
            try await database.upsert(account: account)
            await load()
        } catch {
            await load()
        }
    }
}
