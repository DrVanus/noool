//
//  BinancePriceResponse.swift
//  CSAI1
//
//  Created by DM on 4/23/25.
//

//
//  PriceViewModel.swift
//  CSAI1
//
//  Created by DM on 4/22/25.
//

import Foundation

/// Fallback model for Binance REST response
struct BinancePriceResponse: Decodable {
    let symbol: String
    let price: String
}

@MainActor
class PriceViewModel: ObservableObject {
    @Published var currentPrice: Double?
    @Published var symbol: String
    private var pollingTask: Task<Void, Never>?
    private let service = CoinbaseService()
    private let maxBackoff: Double = 60.0
    
    /// Fallback: fetch spot price from Binance REST if Coinbase fails.
    private func fetchBinancePrice(for symbol: String) async -> Double? {
        let pair = symbol.uppercased() + "USDT"
        guard let url = URL(string: "https://api.binance.com/api/v3/ticker/price?symbol=\(pair)") else {
            print("PriceViewModel: invalid URL for \(pair)")
            return nil
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode(BinancePriceResponse.self, from: data)
            return Double(decoded.price)
        } catch {
            #if DEBUG
            print("PriceViewModel: Binance fetch error for \(pair): \(error)")
            #endif
            return nil
        }
    }

    /// Map common symbols to CoinGecko IDs
    private func coingeckoID(for symbol: String) -> String {
        switch symbol.uppercased() {
        case "BTC": return "bitcoin"
        case "ETH": return "ethereum"
        case "BNB": return "binancecoin"
        case "SOL": return "solana"
        case "ADA": return "cardano"
        case "XRP": return "ripple"
        case "DOGE": return "dogecoin"
        // add more as needed
        default: return symbol.lowercased()
        }
    }

    /// Fallback: fetch spot price from CoinGecko if Binance fails or is blocked
    private func fetchCoingeckoPrice(for symbol: String) async -> Double? {
        let id = coingeckoID(for: symbol)
        guard let url = URL(string: "https://api.coingecko.com/api/v3/simple/price?ids=\(id)&vs_currencies=usd") else {
            print("PriceViewModel: invalid CoinGecko URL for \(id)")
            return nil
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let entry = json[id] as? [String: Any],
               let price = entry["usd"] as? Double {
                return price
            }
        } catch {
            #if DEBUG
            print("PriceViewModel: CoinGecko fetch error for \(symbol):", error)
            #endif
        }
        return nil
    }
    
    init(symbol: String) {
        self.symbol = symbol
        startPolling()
    }
    
    /// Change the symbol being tracked and restart polling
    func updateSymbol(_ newSymbol: String) {
        symbol = newSymbol
        startPolling()
    }

    /// Start polling in a detached task with exponential backoff on failures
    private func startPolling() {
        pollingTask?.cancel()
        pollingTask = Task.detached { [weak self] in
            guard let self = self else { return }
            var backoffInterval: Double = 5.0
            while !Task.isCancelled {
                let price = await self.fetchPriceChain(for: self.symbol)
                await MainActor.run {
                    if let price = price {
                        self.currentPrice = price
                        #if DEBUG
                        print("PriceViewModel: polled price \(price) for \(self.symbol)")
                        #endif
                    }
                }
                // adjust backoff on failure or reset on success
                if price == nil {
                    backoffInterval = min(self.maxBackoff, backoffInterval * 2)
                } else {
                    backoffInterval = 5.0
                }
                try? await Task.sleep(nanoseconds: UInt64(backoffInterval * 1_000_000_000))
            }
        }
    }

    /// Stop polling
    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    /// Try Coinbase, then Binance, then CoinGecko
    private func fetchPriceChain(for symbol: String) async -> Double? {
        if let price = await service.fetchSpotPrice(coin: symbol) {
            return price
        } else if let price = await fetchBinancePrice(for: symbol) {
            return price
        } else {
            return await fetchCoingeckoPrice(for: symbol)
        }
    }
}
