//
//  CoinDetailView.swift
//  CSAI1
//
//  IMPORTANT:
//    - Do NOT redefine MarketCoin here if it’s already in MarketView.swift.
//    - Remove or rename any extra TradingViewWebView if you have duplicates.
//

import SwiftUI
import Charts
import WebKit

// MARK: - Design Helpers
extension Color {
    /// A gold color that contrasts nicely with dark backgrounds
    static let goldButton = Color(red: 0.83, green: 0.68, blue: 0.21)
}

// MARK: - ChartType & ChartInterval
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
    
    /// The exact interval string Binance expects
    var binanceInterval: String {
        switch self {
        case .fifteenMin: return "15m"
        case .oneHour:    return "1h"
        case .fourHour:   return "4h"
        case .oneDay:     return "1d"
        case .oneWeek:    return "1w"
        }
    }
    
    /// Adaptive limit to fetch a reasonable amount of data for each timeframe
    var binanceLimit: Int {
        switch self {
        case .fifteenMin:
            // 15m * 96 = 24 hours of data
            return 96
        case .oneHour:
            // 1h * 168 = 1 week
            return 168
        case .fourHour:
            // 4h * 180 ~ 30 days
            return 180
        case .oneDay:
            // 1d * 90 ~ 3 months
            return 90
        case .oneWeek:
            // 1w * 104 ~ 2 years
            return 104
        }
    }
    
    /// The interval string for TradingView's widget
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
// Use MarketCoin from MarketView.swift; do NOT redefine it here.
struct CoinDetailView: View {
    let coin: MarketCoin  // from MarketView.swift
    
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
    
    private var headerSection: some View {
        VStack(spacing: 6) {
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
                        Circle().fill(Color.gray.opacity(0.6))
                            .frame(width: 64, height: 64)
                    case .empty:
                        ProgressView().frame(width: 64, height: 64)
                    @unknown default:
                        Circle().fill(Color.gray.opacity(0.6))
                            .frame(width: 64, height: 64)
                    }
                }
            } else {
                Circle().fill(Color.gray.opacity(0.6))
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
            }
        }
        .padding(.horizontal, 4)
    }
    
    private var chartSection: some View {
        Group {
            if selectedChartType == .custom {
                CoinDetailCustomChart(symbol: coin.symbol, interval: selectedInterval)
                    .frame(height: 300)
                    .padding(.top, 8)
            } else {
                let tvSymbol = "BINANCE:\(coin.symbol.uppercased())USDT"
                let tvTheme = (colorScheme == .dark) ? "Dark" : "Light"
                CoinDetailTradingViewWebView(
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
    
    private var basicStatsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Basic Stats")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack {
                Text("Volume (24h):")
                    .foregroundColor(.gray)
                Spacer()
                Text(shortVolume(coin.volume))
                    .foregroundColor(.white)
            }
            HStack {
                Text("Open (24h):")
                    .foregroundColor(.gray)
                Spacer()
                Text("$\(coin.price - 2, specifier: "%.2f")")
                    .foregroundColor(.white)
            }
            HStack {
                Text("High (24h):")
                    .foregroundColor(.gray)
                Spacer()
                Text("$\(coin.price + 5, specifier: "%.2f")")
                    .foregroundColor(.white)
            }
            HStack {
                Text("Low (24h):")
                    .foregroundColor(.gray)
                Spacer()
                Text("$\(coin.price - 3, specifier: "%.2f")")
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
    
    private var tradeButton: some View {
        Button {
            print("Trade \(coin.symbol.uppercased()) tapped")
        } label: {
            Text("Trade \(coin.symbol.uppercased())")
                .font(.headline)
                .foregroundColor(.black)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.goldButton)
                .cornerRadius(8)
        }
        .padding(.top, 8)
    }
    
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

// MARK: - Custom Chart
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
                    
                    if let errorMsg = vm.errorMessage {
                        VStack(spacing: 12) {
                            Text("Error loading chart:")
                                .foregroundColor(.red)
                                .font(.headline)
                            Text(errorMsg)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                            
                            Button("Retry") {
                                vm.fetchBinanceData(
                                    symbol: symbol,
                                    interval: interval.binanceInterval,
                                    limit: interval.binanceLimit
                                )
                            }
                            .padding()
                            .foregroundColor(.black)
                            .background(Color.goldButton)
                            .cornerRadius(8)
                        }
                    }
                    else if vm.dataPoints.isEmpty {
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
                        .chartXAxis { AxisMarks() }
                        .chartYAxis { AxisMarks() }
                    }
                } else {
                    Text("iOS 16+ required for Swift Charts")
                        .foregroundColor(.gray)
                }
            }
        }
        .onAppear {
            vm.fetchBinanceData(symbol: symbol, interval: interval.binanceInterval, limit: interval.binanceLimit)
        }
        .onChange(of: interval) { newInterval in
            vm.fetchBinanceData(symbol: symbol, interval: newInterval.binanceInterval, limit: newInterval.binanceLimit)
        }
    }
}

// Minimal model & ViewModel for chart data
struct ChartDataPoint: Identifiable {
    let id = UUID()
    let index: Int
    let close: Double
}

class CoinDetailChartViewModel: ObservableObject {
    @Published var dataPoints: [ChartDataPoint] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    /// Fetch data from Binance US for the given symbol & interval
    func fetchBinanceData(symbol: String, interval: String, limit: Int) {
        let pair = symbol.uppercased() + "USDT"
        // NOTE: Switched to api.binance.us
        let urlString = "https://api.binance.us/api/v3/klines?symbol=\(pair)&interval=\(interval)&limit=\(limit)"
        print("BinanceUS fetch URL:", urlString)
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.dataPoints = []
            self.errorMessage = nil
        }
        
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Invalid URL string."
            }
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
            }
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Network error: \(error.localizedDescription)"
                }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP status code:", httpResponse.statusCode)
                if httpResponse.statusCode != 200 {
                    let errorBody = String(data: data ?? Data(), encoding: .utf8) ?? "N/A"
                    DispatchQueue.main.async {
                        self.errorMessage = """
                        HTTP \(httpResponse.statusCode)
                        \(errorBody)
                        """
                    }
                    return
                }
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    self.errorMessage = "No data received from Binance US."
                }
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [[Any]] {
                    if json.isEmpty {
                        DispatchQueue.main.async {
                            self.errorMessage = "Binance US returned an empty array.\nInvalid symbol or no data."
                        }
                        return
                    }
                    var results: [ChartDataPoint] = []
                    
                    for (i, kline) in json.enumerated() {
                        // Each kline: [openTime, open, high, low, close, volume, closeTime, ...]
                        if kline.count >= 5 {
                            var closeVal: Double? = nil
                            
                            if let value = kline[4] as? Double {
                                closeVal = value
                            } else if let valueStr = kline[4] as? String, let value = Double(valueStr) {
                                closeVal = value
                            }
                            
                            if let close = closeVal {
                                results.append(ChartDataPoint(index: i, close: close))
                            } else {
                                print("Failed to parse close value for kline at index \(i)")
                            }
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.dataPoints = results
                        print("Parsed dataPoints:", results.map { $0.close })
                    }
                } else {
                    DispatchQueue.main.async {
                        self.errorMessage = "JSON parse error: Expected an array of arrays."
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "JSON parse error: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
}

// MARK: - TradingView WebView
struct CoinDetailTradingViewWebView: UIViewRepresentable {
    let symbol: String   // e.g. "BINANCE:BTCUSDT"
    let interval: String // e.g. "15", "60", "D", "W"
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
        let html = """
        <!DOCTYPE html>
        <html>
          <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
              html, body { margin: 0; padding: 0; height: 100%; background: #000; }
              #tv_chart_container { width:100%; height:100%; }
            </style>
          </head>
          <body>
            <div id="tv_chart_container"></div>
            <script src="https://s3.tradingview.com/tv.js"></script>
            <script>
              new TradingView.widget({
                "container_id": "tv_chart_container",
                "symbol": "\(symbol)",
                "interval": "\(interval)",
                "timezone": "Etc/UTC",
                "theme": "\(theme)",
                "style": "1",
                "locale": "en",
                "toolbar_bg": "#f1f3f6",
                "enable_publishing": false,
                "allow_symbol_change": true,
                "autosize": true
              });
            </script>
          </body>
        </html>
        """
        print("Loading TradingView with symbol:", symbol, "interval:", interval)
        webView.loadHTMLString(html, baseURL: URL(string: "https://s3.tradingview.com"))
    }
}
