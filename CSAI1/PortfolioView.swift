//
//  PortfolioView.swift
//  CSAI1
//
//  Created by DM on 3/16/25.
//


//
//  PortfolioView.swift
//  CRYPTOSAI
//
//  Displays user holdings and total value.
//

import SwiftUI

struct PortfolioView: View {
    @StateObject private var viewModel = PortfolioViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Total Portfolio Value: \(viewModel.totalValue, specifier: "%.2f")")
                    .font(.largeTitle)
                    .padding()
                
                List(viewModel.holdings, id: \.id) { coin in
                    HStack {
                        Text(coin.symbol.uppercased())
                        Spacer()
                        Text("$\(coin.current_price ?? 0, specifier: "%.2f")")
                    }
                }
            }
            .navigationTitle("Portfolio")
        }
        .onAppear {
            viewModel.fetchHoldings()
        }
    }
}

struct PortfolioView_Previews: PreviewProvider {
    static var previews: some View {
        PortfolioView()
    }
}
