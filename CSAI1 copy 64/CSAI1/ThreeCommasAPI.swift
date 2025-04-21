import Foundation
import CryptoKit

// MARK: - ThreeCommas API Client

final class ThreeCommasAPI {
    static let shared = ThreeCommasAPI()
    private init() {}

    /// Test connection using trading credentials
    func connect(apiKey: String, apiSecret: String) async throws -> Bool {
        // TODO: implement POST /public/api/ver1/connect
        guard !apiKey.isEmpty, !apiSecret.isEmpty else {
            throw NSError(domain: "ThreeCommasAPI", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid API credentials"])
        }
        return true
    }

    /// Fetch all 3Commas accounts asynchronously and decode to [Account]
    func listAccounts() async throws -> [Account] {
        let url = ThreeCommasConfig.baseURL.appendingPathComponent("public/api/ver1/accounts")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(ThreeCommasConfig.readOnlyAPIKey, forHTTPHeaderField: "APIKEY")
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode([Account].self, from: data)
    }

    /// Fetch balances for a single 3Commas account ID asynchronously and decode to [AccountBalance]
    func loadAccountBalances(accountId: Int) async throws -> [AccountBalance] {
        let url = ThreeCommasConfig.baseURL
            .appendingPathComponent("public/api/ver1/accounts/\(accountId)/balances")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(ThreeCommasConfig.readOnlyAPIKey, forHTTPHeaderField: "APIKEY")
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode([AccountBalance].self, from: data)
    }

    /// Create/start a new trading bot
    func startBot(
        side: TradeSide,
        orderType: OrderType,
        quantity: Double,
        slippage: Double
    ) async throws {
        let url = ThreeCommasConfig.baseURL
            .appendingPathComponent("public/api/ver1/bots/create_trading_bot")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(ThreeCommasConfig.apiKey, forHTTPHeaderField: "APIKEY")
        // TODO: add signature header if required

        let payload: [String: Any] = [
            "pair": "\(side.rawValue)_\(orderType.rawValue)",
            "account_id": ThreeCommasConfig.accountId,
            "quantity": quantity,
            "slippage": slippage
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        // Compute HMAC-SHA256 signature
        let bodyData = request.httpBody ?? Data()
        let secretKey = SymmetricKey(data: Data(ThreeCommasConfig.tradingSecret.utf8))
        let signature = HMAC<SHA256>.authenticationCode(for: bodyData, using: secretKey)
        let signatureHex = signature.map { String(format: "%02x", $0) }.joined()
        request.addValue(signatureHex, forHTTPHeaderField: "Signature")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        _ = try await URLSession.shared.data(for: request)
    }

    /// Cancel/stop an existing trading bot
    func stopBot(botId: Int) async throws {
        let url = ThreeCommasConfig.baseURL
            .appendingPathComponent("public/api/ver1/bots/cancel_trading_bot")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(ThreeCommasConfig.apiKey, forHTTPHeaderField: "APIKEY")
        // TODO: add signature header if required

        let payload = ["id": botId]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        // Compute HMAC-SHA256 signature
        let bodyData = request.httpBody ?? Data()
        let secretKey = SymmetricKey(data: Data(ThreeCommasConfig.tradingSecret.utf8))
        let signature = HMAC<SHA256>.authenticationCode(for: bodyData, using: secretKey)
        let signatureHex = signature.map { String(format: "%02x", $0) }.joined()
        request.addValue(signatureHex, forHTTPHeaderField: "Signature")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        _ = try await URLSession.shared.data(for: request)
    }
}
