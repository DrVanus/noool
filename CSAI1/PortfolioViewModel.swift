//
//  PortfolioViewModel.swift
//  CSAI1
//
//  Created by DM on 3/16/25.
//


//
//  PortfolioViewModel.swift
//  CRYPTOSAI
//
//  Example portfolio model referencing CoinGeckoCoin for holdings.
//

import Foundation

class PortfolioViewModel: ObservableObject {
    @Published var holdings: [CoinGeckoCoin] = []
    @Published var totalValue: Double = 0.0
    
    func fetchHoldings() {
        // For now, just dummy data or empty
        // If you want real holdings, store them or fetch them from an API
        let btc = CoinGeckoCoin(
            id: "bitcoin",
            symbol: "btc",
            name: "Bitcoin",
            image: nil,
            current_price: 28000,
            market_cap: nil,
            market_cap_rank: nil,
            total_volume: nil,
            high_24h: nil,
            low_24h: nil,
            price_change_24h: nil,
            price_change_percentage_24h: nil,
            fully_diluted_valuation: nil,
            circulating_supply: nil,
            total_supply: nil,
            ath: nil,
            ath_change_percentage: nil,
            ath_date: nil,
            atl: nil,
            atl_change_percentage: nil,
            atl_date: nil,
            last_updated: nil,
            coin_id: nil,
            thumb: nil,
            small: nil,
            large: nil,
            slug: nil
        )
        let eth = CoinGeckoCoin(
            id: "ethereum",
            symbol: "eth",
            name: "Ethereum",
            image: nil,
            current_price: 1800,
            market_cap: nil,
            market_cap_rank: nil,
            total_volume: nil,
            high_24h: nil,
            low_24h: nil,
            price_change_24h: nil,
            price_change_percentage_24h: nil,
            fully_diluted_valuation: nil,
            circulating_supply: nil,
            total_supply: nil,
            ath: nil,
            ath_change_percentage: nil,
            ath_date: nil,
            atl: nil,
            atl_change_percentage: nil,
            atl_date: nil,
            last_updated: nil,
            coin_id: nil,
            thumb: nil,
            small: nil,
            large: nil,
            slug: nil
        )
        holdings = [btc, eth]
        calculateTotalValue()
    }
    
    func calculateTotalValue() {
        totalValue = holdings.reduce(0) { $0 + ($1.current_price ?? 0) }
    }
}
