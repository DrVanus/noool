//
//  PortfolioViewModel.swift
//  CSAI1
//
//  Manages holdings, calculates totals, provides performance data.
//

import SwiftUI

/// Possible chart time ranges.
enum ChartTimeRange {
    case week, month, year
}

class PortfolioViewModel: ObservableObject {
    @Published var holdings: [Holding] = []
    @Published var totalValue: Double = 0.0
    @Published var totalProfitLoss: Double = 0.0
    
    /// The array of portfolio values used to draw the mini chart.
    @Published var performanceData: [Double] = []
    
    init() {
        loadHoldings()
        // Default: generate performance data for 1 week
        generatePerformanceData(for: .week)
    }
    
    func loadHoldings() {
        // Example data—replace or extend with real/persistent data
        holdings = [
            Holding(
                coinName: "Bitcoin",
                coinSymbol: "BTC",
                quantity: 1.2,
                currentPrice: 25000,
                costBasis: 20000,
                imageUrl: nil
            ),
            Holding(
                coinName: "Ethereum",
                coinSymbol: "ETH",
                quantity: 5.0,
                currentPrice: 1500,
                costBasis: 4000,
                imageUrl: nil
            )
        ]
        recalcTotals()
    }
    
    func recalcTotals() {
        totalValue = holdings.reduce(0) { $0 + $1.currentValue }
        totalProfitLoss = holdings.reduce(0) { $0 + $1.profitLoss }
    }
    
    func addHolding(coinName: String,
                    coinSymbol: String,
                    quantity: Double,
                    currentPrice: Double,
                    costBasis: Double,
                    imageUrl: String?) {
        let newH = Holding(
            coinName: coinName,
            coinSymbol: coinSymbol,
            quantity: quantity,
            currentPrice: currentPrice,
            costBasis: costBasis,
            imageUrl: imageUrl
        )
        holdings.append(newH)
        recalcTotals()
    }
    
    func removeHolding(at offsets: IndexSet) {
        holdings.remove(atOffsets: offsets)
        recalcTotals()
    }
    
    /// Generates random performance data based on the chosen time range.
    func generatePerformanceData(for range: ChartTimeRange) {
        let base = totalValue
        let count: Int
        switch range {
        case .week:
            count = 7
        case .month:
            count = 30
        case .year:
            count = 52
        }
        performanceData = (0..<count).map { _ in
            let variation = Double.random(in: -2000...2000)
            return max(0, base + variation)
        }
    }
}
