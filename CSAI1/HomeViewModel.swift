//
//  HomeViewModel.swift
//  CRYPTOSAI
//
//  Minimal ViewModel to avoid duplication of coin structs.
//  Provides placeholders for watchlist, trending, and news.
//

import Foundation
import Combine
import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {
    @Published var portfolioVM = PortfolioViewModel()
    @Published var marketVM    = MarketViewModel()
    @Published var newsVM      = CryptoNewsFeedViewModel()
    @Published var heatMapVM   = HeatMapViewModel()
    
    private let stables = ["USDT", "USDC", "BUSD", "DAI"]

    var liveTrending: [MarketCoin] {
        marketVM.coins
            .filter { !stables.contains($0.symbol.uppercased()) }
            .sorted { $0.volume > $1.volume }
            .map { $0 }
    }

    var liveTopGainers: [MarketCoin] {
        Array(marketVM.coins.sorted { $0.dailyChange > $1.dailyChange })
    }

    var liveTopLosers: [MarketCoin] {
        Array(marketVM.coins.sorted { $0.dailyChange < $1.dailyChange })
    }

    var heatMapTiles: [HeatMapTile] {
        heatMapVM.tiles
    }

    var heatMapWeights: [Double] {
        heatMapVM.weights()
    }
}
