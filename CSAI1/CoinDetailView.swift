//
//  CoinDetailView.swift
//  CSAI1
//
//  A detail page for a single coin with a toggle between
//  a custom Swift chart (iOS 16+ for Swift Charts) and a TradingView chart.
//  Also re-fetches custom chart data on interval changes.
//

import SwiftUI
import Charts  // iOS 16+ for Swift Charts

// -----------------------------------------------------------
// MARK: - Enums used only by this detail screen
// (If you want these used app-wide, you can move them
// to a shared file, but DO NOT duplicate MarketCoin, etc.)
// -----------------------------------------------------------

enum ChartType: String, CaseIterable {
    case custom = "Custom"
    case tradingView = "TradingView"
}

enum ChartInterval: String, CaseIterable {
    case fifteenMin = "15m"
    case oneHour    = "1H"
    case fourHour   = "4H"
    case oneDay     = "1D"
    case oneWeek    = "1W"
    
    var tvValue: String {
        switch self {
        case .fifteenMin: return "15"
        case .oneHour:    return "60"
        case .fourHour:   return "240"
        case .oneDay:     return "D"
        case .oneWeek:    return "W"
        }
    }
}

// -----------------------------------------------------------
// MARK: - Inline custom chart ViewModel (local to this file)
// -----------------------------------------------------------

class InlineCustomChartViewModel: ObservableObject {
    @Published var chartData: [PricePoint] = []
    @Published var isLoading: Bool = false
    
    func fetchData(symbol: String, interval: String) {
        print("CustomChartVM -> fetchData symbol=\(symbol), interval=\(interval)")
        isLoading = true
        
        // Simulate an async fetch (replace with real logic if needed)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            self.chartData = (1...20).map { i in
                PricePoint(index: i, price: Double.random(in: 8000...90000))
            }
            self.isLoading = false
        }
    }
}

// Simple model for chart data
struct PricePoint: Identifiable {
    let id = UUID()
    let index: Int
    let price: Double
}

// -----------------------------------------------------------
// MARK: - CoinDetailView
// NOTE: We assume `MarketCoin` is declared in MarketView.swift
// or somewhere else in your project, so we do NOT redeclare it here.
// -----------------------------------------------------------

struct CoinDetailView: View {
    
    // We reference the existing MarketCoin type (defined in MarketView.swift).
    // Make sure you do NOT redefine MarketCoin in this file.
    let coin: MarketCoin
    
    @State private var selectedChartType: ChartType = .custom
    @State private var selectedInterval: ChartInterval = .oneDay
    
    @Environment(\.colorScheme) var colorScheme
    
    @StateObject private var customChartVM = InlineCustomChartViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                
                headerSection
                chartToggleSection
                chartSection
                basicStatsSection
                additionalStatsSection
                newsSection
                tradeButton
            }
            .padding()
        }
        .background(Color.black.ignoresSafeArea())
        .navigationBarTitle(coin.symbol.uppercased(), displayMode: .inline)
        .onAppear {
            // Kick off data fetch for custom chart
            customChartVM.fetchData(symbol: coin.symbol, interval: selectedInterval.tvValue)
        }
        .onChange(of: selectedInterval) { newInterval in
            if selectedChartType == .custom {
                customChartVM.fetchData(symbol: coin.symbol, interval: newInterval.tvValue)
            }
        }
        .onChange(of: selectedChartType) { newType in
            if newType == .custom {
                customChartVM.fetchData(symbol: coin.symbol, interval: selectedInterval.tvValue)
            }
        }
    }
}

// MARK: - Subviews
extension CoinDetailView {
    
    private var headerSection: some View {
        VStack(spacing: 6) {
            // Coin icon
            if let urlStr = coin.imageUrl, let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                    case .failure(_):
                        Circle().fill(Color.gray.opacity(0.6))
                            .frame(width: 80, height: 80)
                    case .empty:
                        ProgressView().frame(width: 80, height: 80)
                    @unknown default:
                        Circle().fill(Color.gray.opacity(0.6))
                            .frame(width: 80, height: 80)
                    }
                }
            } else {
                Circle().fill(Color.gray.opacity(0.6))
                    .frame(width: 80, height: 80)
            }
            
            Text(coin.name)
                .font(.title3)
                .foregroundColor(.white.opacity(0.8))
            
            Text("$\(coin.price, specifier: "%.2f")")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
            
            Text("\(coin.dailyChange, specifier: "%.2f")% (24h)")
                .font(.headline)
                .foregroundColor(coin.dailyChange >= 0 ? .green : .red)
        }
    }
    
    private var chartToggleSection: some View {
        VStack(spacing: 12) {
            // Toggle between custom Swift chart and TradingView
            Picker("Chart Type", selection: $selectedChartType) {
                ForEach(ChartType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal, 16)
            
            // Intervals
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ChartInterval.allCases, id: \.self) { interval in
                        Button {
                            selectedInterval = interval
                        } label: {
                            Text(interval.rawValue)
                                .font(.caption)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(
                                    selectedInterval == interval
                                    ? Color.white
                                    : Color.white.opacity(0.1)
                                )
                                .foregroundColor(selectedInterval == interval ? .black : .white)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    private var chartSection: some View {
        Group {
            if selectedChartType == .custom {
                // Our custom Swift chart
                if customChartVM.isLoading {
                    ProgressView("Loading chart...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(height: 250)
                } else {
                    if #available(iOS 16, *) {
                        Chart {
                            ForEach(customChartVM.chartData) { point in
                                LineMark(
                                    x: .value("Index", point.index),
                                    y: .value("Price", point.price)
                                )
                                .foregroundStyle(.yellow)
                                
                                AreaMark(
                                    x: .value("Index", point.index),
                                    y: .value("Price", point.price)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.yellow.opacity(0.3), .clear]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            }
                        }
                        .chartXAxis(.hidden)
                        .chartYAxis(.hidden)
                        .frame(height: 250)
                    } else {
                        Text("iOS 16 required for Swift Charts")
                            .foregroundColor(.gray)
                            .frame(height: 250)
                    }
                }
            } else {
                // TradingView chart
                let symbolForTV = "BINANCE:\(coin.symbol.uppercased())USDT"
                let tvTheme = (colorScheme == .dark) ? "Dark" : "Light"
                
                TradingViewWebView(
                    symbol: symbolForTV,
                    interval: selectedInterval.tvValue,
                    theme: tvTheme
                )
                .frame(height: 250)
            }
        }
        .animation(.easeInOut, value: selectedChartType)
    }
    
    private var basicStatsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Basic Stats")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack {
                Text("Volume (24h):").foregroundColor(.gray)
                Spacer()
                Text(shortVolume(coin.volume)).foregroundColor(.white)
            }
            HStack {
                Text("Open (24h):").foregroundColor(.gray)
                Spacer()
                Text("$\(coin.price - 2, specifier: "%.2f")").foregroundColor(.white)
            }
            HStack {
                Text("High (24h):").foregroundColor(.gray)
                Spacer()
                Text("$\(coin.price + 5, specifier: "%.2f")").foregroundColor(.white)
            }
            HStack {
                Text("Low (24h):").foregroundColor(.gray)
                Spacer()
                Text("$\(coin.price - 3, specifier: "%.2f")").foregroundColor(.white)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
    
    private var additionalStatsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Additional Stats")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("• Market cap, supply, etc.\n• Possibly on-chain metrics.\n• AI-driven analysis (coming soon).")
                .font(.caption)
                .foregroundColor(.white.opacity(0.9))
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
    
    private var newsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("AI / On-Chain Insights")
                .font(.headline)
                .foregroundColor(.white)
            Text("• Curated news, signals, and insights (coming soon).")
                .font(.caption)
                .foregroundColor(.white.opacity(0.9))
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
    
    private var tradeButton: some View {
        Button {
            print("Trade \(coin.symbol) tapped")
        } label: {
            Text("Trade \(coin.symbol.uppercased())")
                .font(.headline)
                .foregroundColor(.black)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green)
                .cornerRadius(8)
        }
        .padding(.top, 8)
    }
    
    private func shortVolume(_ vol: Double) -> String {
        if vol >= 1_000_000_000 {
            return String(format: "%.1fB", vol / 1_000_000_000)
        } else if vol >= 1_000_000 {
            return String(format: "%.1fM", vol / 1_000_000)
        } else if vol >= 1_000 {
            return String(format: "%.1fK", vol / 1_000)
        } else {
            return String(format: "%.0f", vol)
        }
    }
}

// -----------------------------------------------------------
// MARK: - TradingViewWebView
// Make sure you have a separate TradingViewWebView.swift
// or put this code below if you want it in the same file
// (But do NOT define it in multiple places).
// -----------------------------------------------------------
struct TradingViewWebView: View {
    let symbol: String
    let interval: String
    let theme: String
    
    var body: some View {
        // A simple WebView or WKWebView-based code that loads TradingView widget
        Text("TradingView placeholder for \(symbol) on \(interval)")
            .foregroundColor(.gray)
    }
}
