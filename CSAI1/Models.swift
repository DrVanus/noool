//
//  Models.swift
//  CRYPTOSAI
//
//  Defines CoinGeckoCoin, trending response types, and chat models.
//

import Foundation

// MARK: - Existing Coin Models
struct CoinGeckoCoin: Identifiable, Codable {
    let id: String
    let symbol: String
    let name: String?
    let image: String?
    let current_price: Double?
    
    let market_cap: Double?
    let market_cap_rank: Int?
    let total_volume: Double?
    let high_24h: Double?
    let low_24h: Double?
    let price_change_24h: Double?
    let price_change_percentage_24h: Double?
    
    let fully_diluted_valuation: Double?
    let circulating_supply: Double?
    let total_supply: Double?
    let ath: Double?
    let ath_change_percentage: Double?
    let ath_date: String?
    let atl: Double?
    let atl_change_percentage: Double?
    let atl_date: String?
    let last_updated: String?
    
    // For trending endpoint
    let coin_id: Int?
    let thumb: String?
    let small: String?
    let large: String?
    let slug: String?
}

struct TrendingResponse: Codable {
    let coins: [TrendingCoinItem]
}

struct TrendingCoinItem: Codable {
    let item: CoinGeckoCoin
}

// MARK: - Chat Models

/// A single chat message from either the user or the AI.
struct ChatMessage: Identifiable, Codable {
    var id = UUID()
    var sender: String  // "user" or "ai"
    var text: String
    var timestamp: Date = Date()
    var isError: Bool = false
}

/// A conversation thread containing multiple messages (for multi-chat).
struct Conversation: Identifiable, Codable {
    var id = UUID()
    var title: String
    var messages: [ChatMessage]
    var createdAt: Date = Date()
    
    /// New pinned property for pin/unpin functionality
    var pinned: Bool = false
    
    init(
        title: String,
        messages: [ChatMessage] = [],
        pinned: Bool = false
    ) {
        self.title = title
        self.messages = messages
        self.pinned = pinned
    }
}
