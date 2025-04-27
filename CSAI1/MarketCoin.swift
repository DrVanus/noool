// MarketCoin.swift

import Foundation

struct MarketCoin: Identifiable {
    // We'll store a UUID as the id for Identifiable.
    let id: UUID

    let symbol: String
    let name: String
    
    // price is var so we can update it after fetching from Coinbase.
    var price: Double
    
    // dailyChange is var in case you want to update it (24H percentage change).
    var dailyChange: Double
    
    // New property for the 1H percentage change.
    var hourlyChange: Double
    
    // volume is var in case you want to update it.
    var volume: Double
    
    // New property for market capitalization.
    var marketCap: Double
    
    // isFavorite is var so you can toggle it.
    var isFavorite: Bool
    
    // sparklineData is var so you can update it after fetching.
    var sparklineData: [Double]
    
    // The raw image URL, e.g. from CoinGecko.
    let imageUrl: String?
    
    // New property to store the stable final image URL (e.g. from Cryptologos).
    let finalImageUrl: String?
    
    // Custom initializer removed; decoding is handled via Decodable extension.
}

extension MarketCoin {
    /// Returns the 1H percentage change for use in the UI.
    var change1h: Double {
        return hourlyChange
    }
    
    /// Returns the 24H percentage change for use in the UI.
    var change24h: Double {
        return dailyChange
    }
}

// MARK: - Decoding from API
extension MarketCoin: Decodable {
    private enum CodingKeys: String, CodingKey {
        case symbol
        case name
        case price = "current_price"
        case dailyChange = "price_change_percentage_24h"
        case hourlyChange = "price_change_percentage_1h"
        case volume = "total_volume"
        case marketCap = "market_cap"
        case sparklineData = "sparkline_in_7d"
        case imageUrl = "image"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.symbol = try container.decode(String.self, forKey: .symbol)
        self.name = try container.decode(String.self, forKey: .name)
        self.price = try container.decode(Double.self, forKey: .price)
        self.dailyChange = try container.decode(Double.self, forKey: .dailyChange)
        self.hourlyChange = try container.decode(Double.self, forKey: .hourlyChange)
        self.volume = try container.decode(Double.self, forKey: .volume)
        self.marketCap = try container.decode(Double.self, forKey: .marketCap)
        self.sparklineData = try container.decode([Double].self, forKey: .sparklineData)
        self.imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        self.finalImageUrl = nil
        self.isFavorite = false
    }
}
