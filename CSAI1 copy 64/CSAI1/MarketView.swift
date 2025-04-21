//
//  MarketView.swift
//  Improved with More Priority Coins, Extra Logo Fallbacks, and Search Button Relocation
//
//  Created by ChatGPT on 3/30/25
//

import SwiftUI
import Charts

struct MarketView: View {
    @EnvironmentObject var vm: MarketViewModel  // Provided by your shared MarketViewModel
    
    private let coinWidth: CGFloat   = 140
    private let priceWidth: CGFloat  = 70
    private let dailyWidth: CGFloat  = 50
    private let volumeWidth: CGFloat = 70
    private let starWidth: CGFloat   = 40
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 0) {
                    // GlobalSummaryView inserted at top.
                    GlobalSummaryView()
                        .padding(.bottom, 8)
                    
                    segmentRow
                    if vm.showSearchBar {
                        TextField("Search coins...", text: $vm.searchText)
                            .foregroundColor(.white)
                            .onChange(of: vm.searchText) { _ in
                                vm.applyAllFiltersAndSort()
                            }
                            .padding(8)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(8)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)
                    }
                    columnHeader
                    if vm.isLoading && vm.coins.isEmpty {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Spacer()
                    } else {
                        coinList
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Segment Row
    private var segmentRow: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(MarketSegment.allCases, id: \.self) { seg in
                        Button {
                            vm.updateSegment(seg)
                        } label: {
                            Text(seg.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(vm.selectedSegment == seg ? .black : .white)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .background(vm.selectedSegment == seg ? Color.white : Color.white.opacity(0.1))
                                .cornerRadius(16)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
            }
            
            Button {
                withAnimation { vm.showSearchBar.toggle() }
            } label: {
                Image(systemName: vm.showSearchBar ? "magnifyingglass.circle.fill" : "magnifyingglass.circle")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(.trailing, 16)
            }
        }
        .background(Color.black)
    }
    
    // MARK: - Column Header
    private var columnHeader: some View {
        HStack(spacing: 0) {
            headerButton("Coin", .coin)
                .frame(width: coinWidth, alignment: .leading)
            Text("7D")
                .font(.caption)
                .foregroundColor(.white.opacity(0.9))
                .frame(width: 40, alignment: .trailing)
            headerButton("Price", .price)
                .frame(width: priceWidth, alignment: .trailing)
            headerButton("24h", .dailyChange)
                .frame(width: dailyWidth, alignment: .trailing)
            headerButton("Vol", .volume)
                .frame(width: volumeWidth, alignment: .trailing)
            Spacer().frame(width: starWidth)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.05))
    }
    
    private func headerButton(_ label: String, _ field: SortField) -> some View {
        Button {
            vm.toggleSort(for: field)
        } label: {
            HStack(spacing: 4) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
                if vm.sortField == field {
                    Image(systemName: vm.sortDirection == .asc ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .background(vm.sortField == field ? Color.white.opacity(0.05) : Color.clear)
    }
    
    // MARK: - Coin List
    private var coinList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                if vm.filteredCoins.isEmpty {
                    Text(vm.searchText.isEmpty ? "No coins available." : "No coins match your search.")
                        .foregroundColor(.gray)
                        .padding(.top, 40)
                } else {
                    ForEach(vm.filteredCoins) { coin in
                        NavigationLink(destination: CoinDetailView(coin: coin)) {
                            coinRow(coin)
                                .transition(.opacity)
                        }
                        .buttonStyle(PlainButtonStyle())
                        Divider()
                            .background(Color.white.opacity(0.1))
                            .padding(.leading, 16)
                    }
                }
            }
            .padding(.bottom, 12)
        }
        .refreshable {
            await vm.fetchMarketDataMulti()
            await vm.fetchGlobalMarketDataMulti()
        }
    }
    
    private func coinRow(_ coin: MarketCoin) -> some View {
        HStack(spacing: 0) {
            HStack(spacing: 8) {
                // Use the separate CoinImageView for icons
                CoinImageView(symbol: coin.symbol, urlStr: coin.imageUrl)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(coin.symbol.uppercased())
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text(coin.name)
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
            .frame(width: coinWidth, alignment: .leading)
            
            if #available(iOS 16, *) {
                ZStack {
                    Rectangle().fill(Color.clear).frame(width: 50, height: 30)
                    sparkline(coin.sparklineData, dailyChange: coin.dailyChange)
                }
            } else {
                Spacer().frame(width: 50)
            }
            
            Text(String(format: "$%.2f", coin.price))
                .font(.subheadline)
                .foregroundColor(.white)
                .frame(width: priceWidth, alignment: .trailing)
                .lineLimit(1)
            Text(String(format: "%.2f%%", coin.dailyChange))
                .font(.caption)
                .foregroundColor(coin.dailyChange >= 0 ? .green : .red)
                .frame(width: dailyWidth, alignment: .trailing)
                .lineLimit(1)
            Text(shortVolume(coin.volume))
                .font(.caption2)
                .foregroundColor(.white.opacity(0.9))
                .frame(width: volumeWidth, alignment: .trailing)
                .lineLimit(1)
            Button {
                vm.toggleFavorite(coin)
            } label: {
                Image(systemName: coin.isFavorite ? "star.fill" : "star")
                    .foregroundColor(coin.isFavorite ? .yellow : .gray)
            }
            .buttonStyle(PlainButtonStyle())
            .frame(width: starWidth, alignment: .center)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .frame(height: 60)
    }
    
    // MARK: - Sparkline
    @ViewBuilder
    private func sparkline(_ data: [Double], dailyChange: Double) -> some View {
        if data.isEmpty {
            Rectangle().fill(Color.white.opacity(0.1))
        } else {
            let minValue = data.min() ?? 0
            let maxValue = data.max() ?? 1
            let range = maxValue - minValue
            let domainPaddingFraction = 0.15
            let lowerBound = minValue - range * domainPaddingFraction
            let upperBound = maxValue + range * domainPaddingFraction
            
            Chart {
                ForEach(data.indices, id: \.self) { i in
                    LineMark(
                        x: .value("Index", i),
                        y: .value("Price", data[i])
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(dailyChange >= 0 ? Color.green : Color.red)
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartYScale(domain: lowerBound...upperBound)
            .chartPlotStyle { plotArea in
                plotArea.frame(width: 50, height: 30)
            }
        }
    }
    
    // MARK: - Helpers
    private func shortVolume(_ vol: Double) -> String {
        vol.formattedWithAbbreviations()
    }
}

// MARK: - Extension for Formatting
extension Double {
    func formattedWithAbbreviations() -> String {
        let absValue = abs(self)
        switch absValue {
        case 1_000_000_000_000...:
            return String(format: "%.1fT", self / 1_000_000_000_000)
        case 1_000_000_000...:
            return String(format: "%.1fB", self / 1_000_000_000)
        case 1_000_000...:
            return String(format: "%.1fM", self / 1_000_000)
        case 1_000...:
            return String(format: "%.1fK", self / 1_000)
        default:
            return String(format: "%.0f", self)
        }
    }
}
