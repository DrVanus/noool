//
//  CoinbaseService.swift
//  CSAI1
//
//  Created by DM on 3/21/25.
//  Updated with improved error handling, retry logic, coin pair filtering, session reuse,
//  and caching for invalid coin pair logging.
//

import Foundation

struct CoinbaseSpotPriceResponse: Decodable {
    let data: DataField?

    struct DataField: Decodable {
        let base: String      // e.g., "BTC"
        let currency: String  // e.g., "USD"
        let amount: String    // e.g., "27450.12"
    }
}

actor CoinbaseService {
    
    // A set of known valid coin pairs. Update this list as needed.
    private let validPairs: Set<String> = [
        "BTC-USD", "ETH-USD", "USDT-USD", "XRP-USD", "BNB-USD",
        "USDC-USD", "SOL-USD", "DOGE-USD", "ADA-USD", "TRX-USD",
        "WBTC-USD", "WETH-USD", "WEETH-USD", "UNI-USD", "DAI-USD",
        "APT-USD", "TON-USD", "LINK-USD", "XLM-USD", "WSTETH-USD",
        "AVAX-USD", "SUI-USD", "SHIB-USD", "HBAR-USD", "LTC-USD",
        "OM-USD", "DOT-USD", "BCH-USD", "SUSDE-USD", "AAVE-USD",
        "ATOM-USD", "CRO-USD", "NEAR-USD", "PEPE-USD", "OKB-USD",
        "CBBTC-USD", "GT-USD"
    ]
    
    // Cache for coin pairs already logged as invalid so each is logged only once.
    private var invalidPairsLogged: Set<String> = []
    
    // Reuse a shared URLSession with custom configuration.
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 15
        return URLSession(configuration: config)
    }()
    
    /// Asynchronously fetch the spot price for a given coin (default "BTC") in a specified fiat (default "USD").
    /// Uses retry logic (with exponential backoff) and coin pair filtering.
    /// Returns a Double value if successful; otherwise, returns nil.
    func fetchSpotPrice(coin: String = "BTC", fiat: String = "USD", maxRetries: Int = 3, allowUnlistedPairs: Bool = false) async -> Double? {
        let coinPair = "\(coin.uppercased())-\(fiat.uppercased())"
        
        // If filtering is enabled and the pair is not in the valid list, log it only once.
        if !allowUnlistedPairs && !validPairs.contains(coinPair) {
            if !invalidPairsLogged.contains(coinPair) {
                print("CoinbaseService: \(coinPair) is not in the list of valid pairs.")
                invalidPairsLogged.insert(coinPair)
            }
            return nil
        }
        
        let endpoint = "https://api.coinbase.com/v2/prices/\(coinPair)/spot"
        guard let url = URL(string: endpoint) else {
            print("CoinbaseService: Invalid URL: \(endpoint)")
            return nil
        }
        
        var attempt = 0
        while attempt < maxRetries {
            attempt += 1
            do {
                // Perform the network request.
                let (data, response) = try await session.data(from: url)
                
                // Check the HTTP status code.
                if let httpResponse = response as? HTTPURLResponse,
                   !(200...299).contains(httpResponse.statusCode) {
                    print("CoinbaseService: HTTP status code = \(httpResponse.statusCode) on attempt \(attempt) for \(coinPair)")
                    
                    // For specific error codes, abort retries.
                    if httpResponse.statusCode == 404 || httpResponse.statusCode == 400 {
                        if let responseString = String(data: data, encoding: .utf8) {
                            print("CoinbaseService: Response body = \(responseString)")
                        }
                        print("CoinbaseService: Coin pair \(coinPair) appears to be invalid. Aborting retries.")
                        return nil
                    }
                }
                
                // Attempt to decode the JSON response.
                let decoded = try JSONDecoder().decode(CoinbaseSpotPriceResponse.self, from: data)
                guard let dataField = decoded.data else {
                    print("CoinbaseService: 'data' field was missing in the response on attempt \(attempt).")
                    return nil
                }
                
                if let price = Double(dataField.amount) {
                    print("CoinbaseService: Successfully fetched price \(price) for \(coinPair) on attempt \(attempt)")
                    return price
                } else {
                    print("CoinbaseService: Failed to convert amount \(dataField.amount) to Double on attempt \(attempt)")
                    return nil
                }
                
            } catch {
                print("CoinbaseService error on attempt \(attempt) for \(coinPair): \(error.localizedDescription)")
                if attempt < maxRetries {
                    let delaySeconds = Double(attempt * 2)
                    print("CoinbaseService: Retrying in \(delaySeconds) seconds...")
                    try? await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))
                } else {
                    print("CoinbaseService: All attempts failed for \(coinPair). Last error: \(error.localizedDescription)")
                    return nil
                }
            }
        }
        return nil
    }
}
