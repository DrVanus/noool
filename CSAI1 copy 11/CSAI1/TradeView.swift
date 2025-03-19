//
//  TradeView.swift
//  CSAI1
//
//  Created by DM on 3/16/25.
//


//
//  TradeView.swift
//  CRYPTOSAI
//
//  Displays a basic trading interface.
//

import SwiftUI

struct TradeView: View {
    @StateObject private var viewModel = TradeViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                // For a real chart, you could embed a TradingViewWebView or Sparkline
                Text("Trading Chart Placeholder")
                    .frame(height: 200)
                    .background(Color.gray.opacity(0.2))
                
                Form {
                    Section(header: Text("Order Type")) {
                        Picker("Type", selection: $viewModel.orderType) {
                            Text("Buy").tag("Buy")
                            Text("Sell").tag("Sell")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    Section(header: Text("Amount")) {
                        TextField("Enter amount", text: $viewModel.amount)
                            .keyboardType(.decimalPad)
                    }
                    
                    Button(action: {
                        viewModel.placeOrder()
                    }) {
                        Text("Place Order")
                    }
                }
            }
            .navigationTitle("Trade")
        }
    }
}

struct TradeView_Previews: PreviewProvider {
    static var previews: some View {
        TradeView()
    }
}
