//
//  CoinDetailView.swift
//  CSAI1
//
//  Created by ... on ...
//
//  Displays a coin’s detail page with two chart modes:
//  - Custom Swift Charts line chart (iOS 16+)
//  - TradingView WebView chart
//
//  NOTE: Remove any duplicate MarketCoin struct from here if you
//  already have MarketCoin declared in MarketView.swift!
//

import SwiftUI
import Charts   // iOS 16+ for Swift Charts
import WebKit   // For TradingView WebView

// ---------------------------------------------------------
// IMPORTANT: Use the same MarketCoin definition you have in
// MarketView.swift. Do NOT duplicate it here to avoid errors.
//
// Example (remove or comment out if you have MarketCoin elsewhere):
//
// struct MarketCoin: Identifiable {
//     let id = UUID()
//     let symbol: String
//     let name: String
//     var price: Double
//     let dailyChange: Double
//     let volume: Double
//     var isFavorite: Bool = false
//     var sparklineData: [Double]
//     let imageUrl: String?
// }
// ---------------------------------------------------------

// MARK: - ChartType and ChartInterval

enum ChartType: String, CaseIterable {
    case custom      = "Custom"
    case tradingView = "TradingView"
}

enum ChartInterval: String, CaseIterable {
    case fifteenMin = "15m"
    case oneHour    = "1H"
    case fourHour   = "4H"
    case oneDay     = "1D"
    case oneWeek    = "1W"
    
    // Convert to Binance intervals for the custom chart fetch
    var binanceInterval: String {
        switch self {
        case .fifteenMin: return "15m"
        case .oneHour:    return "1h"
        case .fourHour:   return "4h"
        case .oneDay:     return "1d"
        case .oneWeek:    return "1w"
        }
    }
    
    // Convert to TradingView intervals
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

// MARK: - CoinDetailView

/// Displays details for a single MarketCoin, including:
///  - Header (icon, name, price, daily change)
///  - Toggle for custom Swift chart vs. TradingView
///  - Basic stats
///  - "Trade" button
///
/// Make sure MarketCoin is declared elsewhere (e.g. MarketView).
struct CoinDetailView: View {
    let coin: MarketCoin
    
    @State private var selectedChartType: ChartType = .custom
    @State private var selectedInterval: ChartInterval = .oneDay
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                
                headerSection
                chartToggleSection
                chartSection
                basicStatsSection
                
                // ... any extra sections you want ...
                
                tradeButton
            }
            .padding()
        }
        .background(Color.black.ignoresSafeArea())
        .navigationBarTitle(coin.symbol.uppercased(), displayMode: .inline)
    }
}

// MARK: - Subviews

extension CoinDetailView {
    
    /// Top header with icon, name, price, daily change
    private var headerSection: some View {
        VStack(spacing: 6) {
            // Async coin icon
            if let urlStr = coin.imageUrl, let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 64, height: 64)
                            .clipShape(Circle())
                    case .failure(_):
                        Circle()
                            .fill(Color.gray.opacity(0.6))
                            .frame(width: 64, height: 64)
                    case .empty:
                        ProgressView()
                            .frame(width: 64, height: 64)
                    @unknown default:
                        Circle()
                            .fill(Color.gray.opacity(0.6))
                            .frame(width: 64, height: 64)
                    }
                }
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.6))
                    .frame(width: 64, height: 64)
            }
            
            Text(coin.name)
                .font(.headline)
                .foregroundColor(.white)
            
            Text("$\(coin.price, specifier: "%.2f")")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            
            Text("\(coin.dailyChange, specifier: "%.2f")% (24h)")
                .font(.subheadline)
                .foregroundColor(coin.dailyChange >= 0 ? .green : .red)
        }
    }
    
    /// Picker for chart type + horizontal list of intervals
    private var chartToggleSection: some View {
        VStack(spacing: 12) {
            Picker("Chart Type", selection: $selectedChartType) {
                ForEach(ChartType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
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
                .padding(.top, 4)
            }
        }
        .padding(.horizontal, 4)
    }
    
    /// Displays either our custom Swift chart or TradingView
    private var chartSection: some View {
        Group {
            if selectedChartType == .custom {
                CoinDetailCustomChart(
                    symbol: coin.symbol,
                    interval: selectedInterval
                )
                .frame(height: 300)
                .padding(.top, 8)
            } else {
                // TradingView
                let tvSymbol = "BINANCE:\(coin.symbol.uppercased())USDT"
                let tvTheme = (colorScheme == .dark) ? "Dark" : "Light"
                
                TradingViewWebView(
                    symbol: tvSymbol,
                    interval: selectedInterval.tvValue,
                    theme: tvTheme
                )
                .frame(height: 300)
                .padding(.top, 8)
            }
        }
        .animation(.easeInOut, value: selectedChartType)
    }
    
    /// Basic stats placeholder
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
    
    /// Trade button at bottom
    private var tradeButton: some View {
        Button {
            print("Trade \(coin.symbol.uppercased()) tapped")
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
    
    /// Format volume as e.g. "450.0M"
    private func shortVolume(_ vol: Double) -> String {
        switch vol {
        case 1_000_000_000...:
            return String(format: "%.1fB", vol / 1_000_000_000)
        case 1_000_000...:
            return String(format: "%.1fM", vol / 1_000_000)
        case 1_000...:
            return String(format: "%.1fK", vol / 1_000)
        default:
            return String(format: "%.0f", vol)
        }
    }
}

// MARK: - CoinDetailCustomChart

/// A SwiftUI view that fetches candlestick data from Binance
/// and renders a Swift Charts line chart (iOS 16+).
struct CoinDetailCustomChart: View {
    let symbol: String
    let interval: ChartInterval
    
    @StateObject private var vm = CoinDetailChartViewModel()
    
    var body: some View {
        ZStack {
            if vm.isLoading {
                ProgressView("Loading chart...")
                    .foregroundColor(.white)
            } else {
                if #available(iOS 16, *) {
                    if vm.dataPoints.isEmpty {
                        Text("No chart data")
                            .foregroundColor(.gray)
                    } else {
                        Chart {
                            ForEach(vm.dataPoints) { point in
                                LineMark(
                                    x: .value("Index", point.index),
                                    y: .value("Close", point.close)
                                )
                                .foregroundStyle(.yellow)
                                
                                AreaMark(
                                    x: .value("Index", point.index),
                                    y: .value("Close", point.close)
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
                    }
                } else {
                    // Fallback if iOS < 16
                    Text("iOS 16+ required for Swift Charts")
                        .foregroundColor(.gray)
                }
            }
        }
        .onAppear {
            vm.fetchBinanceData(symbol: symbol, interval: interval.binanceInterval)
        }
        .onChange(of: interval) { newVal in
            vm.fetchBinanceData(symbol: symbol, interval: newVal.binanceInterval)
        }
    }
}

// MARK: - ChartDataPoint + VM

fileprivate struct ChartDataPoint: Identifiable {
    let id = UUID()
    let index: Int
    let close: Double
}

fileprivate class CoinDetailChartViewModel: ObservableObject {
    @Published var dataPoints: [ChartDataPoint] = []
    @Published var isLoading: Bool = false
    
    func fetchBinanceData(symbol: String, interval: String) {
        // e.g. "BTC" -> "BTCUSDT"
        let pair = symbol.uppercased() + "USDT"
        let urlString = "https://api.binance.com/api/v3/klines?symbol=\(pair)&interval=\(interval)&limit=30"
        
        guard let url = URL(string: urlString) else { return }
        
        isLoading = true
        dataPoints = []
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                self.isLoading = false
            }
            if error != nil || data == nil { return }
            do {
                if let json = try JSONSerialization.jsonObject(with: data!) as? [[Any]] {
                    var results: [ChartDataPoint] = []
                    for (i, kline) in json.enumerated() {
                        if kline.count >= 5 {
                            let closeStr = kline[4] as? String ?? "0"
                            if let closeVal = Double(closeStr) {
                                results.append(ChartDataPoint(index: i, close: closeVal))
                            }
                        }
                    }
                    DispatchQueue.main.async {
                        self.dataPoints = results
                    }
                }
            } catch {
                // parse error
            }
        }.resume()
    }
}

// MARK: - TradingViewWebView

struct TradingViewWebView: UIViewRepresentable {
    let symbol: String   // e.g. "BINANCE:BTCUSDT"
    let interval: String // e.g. "15", "60", "240", "D", "W"
    let theme: String    // "Light" or "Dark"
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        loadTradingViewHTML(into: webView)
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        loadTradingViewHTML(into: uiView)
    }
    
    private func loadTradingViewHTML(into webView: WKWebView) {
        // If you have ATS issues, ensure Info.plist allows these requests
        let html = """
        <html>
          <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
          </head>
          <body style="margin:0;padding:0;">
            <div id="tv_chart_container" style="width:100%; height:100%;"></div>
            <script type="text/javascript" src="https://s3.tradingview.com/tv.js"></script>
            <script type="text/javascript">
              new TradingView.widget({
                "container_id": "tv_chart_container",
                "symbol": "\(symbol)",
                "interval": "\(interval)",
                "theme": "\(theme)",
                "style": "1",
                "locale": "en",
                "toolbar_bg": "#f1f3f6",
                "enable_publishing": false,
                "hide_side_toolbar": false,
                "allow_symbol_change": true,
                "autosize": true
              });
            </script>
          </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: nil)
    }
}

// MARK: - Preview

struct CoinDetailView_Previews: PreviewProvider {
    static var previews: some View {
        // Example coin, remove if you have your own
        let sampleCoin = MarketCoin(
            symbol: "BTC",
            name: "Bitcoin",
            price: 84144.26,
            dailyChange: -2.15,
            volume: 450_000_000,
            sparklineData: [],
            imageUrl: "https://www.cryptocompare.com/media/37746251/btc.png"
        )
        
        NavigationView {
            CoinDetailView(coin: sampleCoin)
        }
        .preferredColorScheme(.dark)
    }
}
