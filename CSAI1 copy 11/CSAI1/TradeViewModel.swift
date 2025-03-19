//
//  TradeViewModel.swift
//  CSAI1
//
//  Created by DM on 3/16/25.
//


//
//  TradeViewModel.swift
//  CRYPTOSAI
//
//  Placeholder for trading logic.
//

import Foundation

class TradeViewModel: ObservableObject {
    @Published var orderType: String = "Buy"
    @Published var amount: String = ""
    
    func placeOrder() {
        print("Placing \(orderType) order for amount: \(amount)")
    }
}
