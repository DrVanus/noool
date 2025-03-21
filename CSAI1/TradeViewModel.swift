import SwiftUI
import Combine

class TradeViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var selectedSymbol: String = "BTC-USD" {
        didSet {
            // When the symbol changes, fetch the new price
            fetchCurrentPrice()
        }
    }
    @Published var side: String = "Buy"
    @Published var orderType: String = "Market"
    @Published var quantity: String = ""
    @Published var limitPrice: String = ""
    @Published var userBalance: Double = 5000.0
    @Published var showAdvanced: Bool = false
    
    // Live price from CoinGecko
    @Published var currentPrice: Double? = nil
    
    // Symbol options
    let symbolOptions = ["BTC-USD", "ETH-USD", "SOL-USD"]
    let orderTypes = ["Market", "Limit", "Stop-Limit", "Trailing Stop"]
    
    // Convert user selection to TradingView format, if needed
    var convertedSymbol: String {
        switch selectedSymbol {
        case "BTC-USD": return "BINANCE:BTCUSDT"
        case "ETH-USD": return "BINANCE:ETHUSDT"
        case "SOL-USD": return "BINANCE:SOLUSDT"
        default: return "BINANCE:BTCUSDT"
        }
    }
    
    // Map user selection to CoinGecko IDs
    // e.g., "BTC-USD" -> "bitcoin"
    private func coinID(for symbol: String) -> String {
        switch symbol {
        case "BTC-USD": return "bitcoin"
        case "ETH-USD": return "ethereum"
        case "SOL-USD": return "solana"
        default: return "bitcoin"
        }
    }
    
    // MARK: - Fetch Current Price
    func fetchCurrentPrice() {
        let id = coinID(for: selectedSymbol)
        CryptoAPIService.shared.fetchCoinData(coinID: id) { [weak self] coinData in
            DispatchQueue.main.async {
                if let coinData = coinData {
                    self?.currentPrice = coinData.current_price
                } else {
                    self?.currentPrice = nil
                }
            }
        }
    }
    
    // MARK: - Quick Fraction
    func applyFraction(_ fraction: Double) {
        guard let price = currentPrice else {
            // If we have no price, do nothing or fallback
            print("No current price available.")
            return
        }
        let amountToSpend = userBalance * fraction
        let calculatedQuantity = amountToSpend / price
        quantity = String(format: "%.4f", calculatedQuantity)
    }
    
    // MARK: - Submit Order
    func submitOrder() {
        guard let qty = Double(quantity), qty > 0 else {
            print("Invalid quantity")
            return
        }
        
        // If not Market, we rely on user input for limitPrice
        if orderType != "Market" {
            guard let p = Double(limitPrice), p > 0 else {
                print("Invalid price for \(orderType) order")
                return
            }
        }
        
        // Determine final execution price
        let executionPrice: Double
        if orderType == "Market" {
            // Use the live price if we have it, else fallback to 20000
            executionPrice = currentPrice ?? 20000.0
        } else {
            executionPrice = Double(limitPrice) ?? 20000.0
        }
        
        let totalCost = qty * executionPrice
        
        if side == "Buy" {
            if totalCost > userBalance {
                print("Insufficient balance")
                return
            }
            userBalance -= totalCost
            print("Bought \(qty) of \(selectedSymbol) at $\(executionPrice) each, total $\(totalCost)")
        } else {
            // Sell
            userBalance += totalCost
            print("Sold \(qty) of \(selectedSymbol) at $\(executionPrice) each, total $\(totalCost)")
        }
        
        // Reset order fields
        quantity = ""
        limitPrice = ""
    }
}
