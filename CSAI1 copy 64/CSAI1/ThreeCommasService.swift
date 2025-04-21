import Foundation
import Combine

class ThreeCommasService: ObservableObject {
    static let shared = ThreeCommasService()
    private init() {}
    
    @Published var balance: Double = 0.0
    
    // Other properties and methods...

    func fetchBalance(for symbol: String) {
        Task {
            do {
                let accounts = try await ThreeCommasAPI.shared.listAccounts()
                guard let firstAccount = accounts.first else {
                    await MainActor.run { self.balance = 0.0 }
                    return
                }
                let balances = try await ThreeCommasAPI.shared
                    .loadAccountBalances(accountId: firstAccount.id)
                if let entry = balances.first(where: { $0.currency == symbol }) {
                    await MainActor.run { self.balance = entry.balance }
                } else {
                    await MainActor.run { self.balance = 0.0 }
                }
            } catch {
                await MainActor.run { self.balance = 0.0 }
            }
        }
    }
    
    // MARK: - Account & Balance Proxies

    /// List all 3Commas accounts
    func listAccounts() async throws -> [Account] {
        try await ThreeCommasAPI.shared.listAccounts()
    }

    /// Load balances for a specific account ID
    func loadAccountBalances(accountId: Int) async throws -> [AccountBalance] {
        return try await ThreeCommasAPI.shared.loadAccountBalances(accountId: accountId)
    }

    /// Start a trading bot via 3Commas
    func startBot(side: TradeSide, orderType: OrderType, quantity: Double, slippage: Double) async throws {
        // TODO: implement using ThreeCommasAPI endpoints
    }

    /// Stop the currently running trading bot
    func stopBot() async throws {
        // TODO: implement using ThreeCommasAPI endpoints
    }
}
