import Foundation

struct ThreeCommasConfig {
    private static func string(forKey key: String) -> String {
        if let value = Bundle.main.object(forInfoDictionaryKey: key) as? String, !value.isEmpty {
            return value
        } else {
            // Log a warning but don’t crash; return an empty string as a safe fallback
            print("⚠️ Warning: Missing or empty \(key) in Info.plist")
            return ""
        }
    }

    /// Read-only API key from Info.plist
    static var readOnlyAPIKey: String {
        string(forKey: "3COMMAS_READ_ONLY_KEY")
    }

    /// Read-only secret from Info.plist
    static var readOnlySecret: String {
        string(forKey: "3COMMAS_READ_ONLY_SECRET")
    }

    /// Trading API key from Info.plist
    static var tradingAPIKey: String {
        string(forKey: "3COMMAS_TRADING_API_KEY")
    }

    /// Trading secret from Info.plist
    static var tradingSecret: String {
        string(forKey: "3COMMAS_TRADING_SECRET")
    }

    /// Alias for the trading API key
    static var apiKey: String {
        tradingAPIKey
    }

    /// 3Commas account ID from Info.plist
    static var accountId: Int {
        let idString = string(forKey: "3COMMAS_ACCOUNT_ID")
        if let id = Int(idString) {
            return id
        } else {
            // Warn on invalid format and return a safe default
            print("⚠️ Warning: Invalid 3COMMAS_ACCOUNT_ID: \(idString)")
            return 0
        }
    }

    /// Base URL for 3Commas API
    static let baseURL = URL(string: "https://api.3commas.io")!
}
