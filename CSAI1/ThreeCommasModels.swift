//
//  Account.swift
//  CSAI1
//
//  Created by DM on 4/20/25.
//


import Foundation

/// Represents a 3Commas account entry returned by the accounts endpoint.
struct Account: Decodable {
    /// Unique identifier for the account.
    let id: Int
    /// Human-readable name of the account (if provided).
    let name: String?
    /// Currency code (e.g. "BTC", "ETH").
    let currency: String?
}

/// Represents a balance entry for a specific currency within an account.
struct AccountBalance: Decodable {
    /// The currency code (e.g. "BTC", "USDT").
    let currency: String
    /// The available balance for that currency.
    let balance: Double
}
