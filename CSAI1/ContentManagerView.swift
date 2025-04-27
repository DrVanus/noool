//
//  ContentManagerView.swift
//  CSAI1
//
//  Created by DM on 3/16/25.
//

//
//  ContentManagerView.swift
//  CRYPTOSAI
//
//  Manages the TabView and switches between tabs.
//

import SwiftUI

struct ContentManagerView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                switch appState.selectedTab {
                case .home:
                    HomeView()
                case .market:
                    MarketView()
                case .trade:
                    TradeView()
                case .portfolio:
                    PortfolioView()
                case .ai:
                    AITabView()
                }
            }
            
            CustomTabBar(selectedTab: $appState.selectedTab)
        }
    }
}

struct ContentManagerView_Previews: PreviewProvider {
    static var previews: some View {
        ContentManagerView()
            .environmentObject(AppState())
            .environmentObject(MarketViewModel())
    }
}
