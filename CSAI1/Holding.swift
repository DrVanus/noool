//
//  Holding.swift
//  CSAI1
//
//  Created by DM on 3/19/25.
//


//
//  Holding.swift
//  CSAI1
//
//  Represents a single crypto holding, including cost basis for profit/loss calculations.
//

import Foundation

struct Holding: Identifiable {
    let id = UUID()
    var coinName: String
    var coinSymbol: String
    var quantity: Double
    var currentPrice: Double
    var costBasis: Double  // total amount spent on this holding
    var imageUrl: String?  // optional URL for the coin's logo
    
    /// Current market value of this holding
    var currentValue: Double {
        quantity * currentPrice
    }
    
    /// Profit/loss computed as current value minus cost basis
    var profitLoss: Double {
        currentValue - costBasis
    }
}