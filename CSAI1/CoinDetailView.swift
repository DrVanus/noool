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
    static let goldButton = Color(red: 0.83, green: 0.68, blue: 0.21)
    static let pillBackground = Color.white.opacity(0.15)
}

// MARK: - ChartType
enum ChartType: String, CaseIterable {
    case cryptoSageAI = "CryptoSage AI Chart"
    case tradingView  = "TradingView"
}

// MARK: - ChartInterval
// Removed 1Y to avoid invalid interval issues
enum ChartInterval: String, CaseIterable {
    case fifteenMin  = "15m"
    case thirtyMin   = "30m"
    case oneHour     = "1H"
    case fourHour    = "4H"
    case oneDay      = "1D"
    case oneWeek     = "1W"
    case oneMonth    = "1M"
    
    var binanceInterval: String {
        switch self {
        case .fifteenMin: return "15m"
        case .thirtyMin:  return "30m"
        case .oneHour:    return "1h"
        case .fourHour:   return "4h"
        case .oneDay:     return "1d"
        case .oneWeek:    return "1w"
        case .oneMonth:   return "1M"
        }
    }
    
    var binanceLimit: Int {
        switch self {
        case .fifteenMin: return 24
        case .thirtyMin:  return 24
        case .oneHour:    return 48
        case .fourHour:   return 84
        case .oneDay:     return 60
        case .oneWeek:    return 52
        case .oneMonth:   return 12
        }
    }
    
    var tvValue: String {
        switch self {
        case .fifteenMin: return "15"
        case .thirtyMin:  return "30"
        case .oneHour:    return "60"
        case .fourHour:   return "240"
        case .oneDay:     return "D"
        case .oneWeek:    return "W"
        case .oneMonth:   return "M"
        }
    }
}

// MARK: - CoinDetailView
struct CoinDetailView: View {
    let coin: MarketCoin  // Must have at least 'symbol' and 'price' in MarketCoin

    @State private var selectedChartType: ChartType = .cryptoSageAI
    @State private var selectedInterval: ChartInterval = .oneDay
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    
    // For live stats via CoinPaprika (optional)
    @StateObject private var statsVM = CoinPaprikaStatsViewModel()
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 16) {
                    
                    // Nav Bar with symbol + price (no iconURL)
                    ZStack {
                        // Left: gold back arrow
                        HStack {
                            Button {
                                presentationMode.wrappedValue.dismiss()
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "chevron.left")
                                        .foregroundColor(.goldButton)
                                    Text("Back")
                                        .foregroundColor(.goldButton)
                                }
                            }
                            Spacer()
                        }
                        
                        // Center: symbol + price
                        VStack(spacing: 2) {
                            Text(coin.symbol.uppercased())
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text(formatWithCommas(coin.price))
                                .font(.system(size: 22, weight: .heavy))
                                .foregroundColor(.white)
                                .padding(.top, 2)
                        }
                    }
                    .padding(.vertical, 8)
                    .overlay(
                        Rectangle()
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 1),
                        alignment: .bottom
                    )
                    
                    // The chart
                    chartSection
                        .clipped()
                    
                    // Chart type toggle
                    chartTypeToggle
                    
                    // Time intervals
                    intervalScroll
                    
                    // (Optional) Live stats from CoinPaprika
                    CoinPaprikaStatsView(coinSymbol: coin.symbol, vm: statsVM)
                }
                .padding()
                .padding(.bottom, 80)
            }
            .background(Color.black.ignoresSafeArea())
            
            // Sticky “Trade” button (assuming your existing TradeView has no init args)
            VStack {
                Spacer()
                tradeButton
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            // Attempt to fetch from CoinPaprika
            statsVM.fetchCoinPaprikaStats(coinSymbol: coin.symbol)
        }
    }
    
    // Format Double with grouping separators, 2 decimals
    private func formatWithCommas(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        // Prepend $
        return "$" + (formatter.string(from: NSNumber(value: value)) ?? String(value))
    }
}

// MARK: - Subviews
extension CoinDetailView {
    
    private var chartSection: some View {
        Group {
            if selectedChartType == .cryptoSageAI {
                CoinDetailCustomChart(symbol: coin.symbol, interval: selectedInterval)
                    .frame(height: 340)
                    .padding(.vertical, 8)
            } else {
                let tvSymbol = "BINANCE:\(coin.symbol.uppercased())USDT"
                let tvTheme = (colorScheme == .dark) ? "Dark" : "Light"
                CoinDetailTradingViewWebView(
                    symbol: tvSymbol,
                    interval: selectedInterval.tvValue,
                    theme: tvTheme
                )
                .frame(height: 340)
                .padding(.vertical, 8)
            }
        }
    }
    
    private var chartTypeToggle: some View {
        HStack(spacing: 0) {
            ForEach(ChartType.allCases, id: \.self) { type in
                Button {
                    selectedChartType = type
                } label: {
                    Text(type.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(selectedChartType == type ? Color.goldButton : Color.pillBackground)
                        .foregroundColor(selectedChartType == type ? .black : .white)
                        .cornerRadius(8)
                }
            }
        }
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)
    }
    
    private var intervalScroll: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ChartInterval.allCases, id: \.self) { interval in
                    Button {
                        selectedInterval = interval
                    } label: {
                        Text(interval.rawValue)
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(selectedInterval == interval ? Color.goldButton : Color.pillBackground)
                            .foregroundColor(selectedInterval == interval ? .black : .white)
                            .cornerRadius(16)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    /// Example “Trade” button linking to a no-args TradeView
    private var tradeButton: some View {
        NavigationLink(destination: TradeView()) {
            Text("Trade \(coin.symbol.uppercased())")
                .font(.headline)
                .foregroundColor(.black)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.goldButton)
                .cornerRadius(12)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
        }
        .background(Color.black.opacity(0.8))
        .shadow(color: Color.black.opacity(0.6), radius: 10, x: 0, y: -3)
    }
}

// MARK: - CoinDetailCustomChart
struct CoinDetailCustomChart: View {
    let symbol: String
    let interval: ChartInterval
    
    @StateObject private var vm = CoinDetailChartViewModel()
    
    @State private var crosshairValue: ChartDataPoint? = nil
    @State private var showCrosshair: Bool = false
    
    var body: some View {
        ZStack {
            if vm.isLoading {
                ProgressView("Loading chart...")
                    .foregroundColor(.white)
            } else {
                if #available(iOS 16, *) {
                    
                    if let errorMsg = vm.errorMessage {
                        VStack(spacing: 10) {
                            Text("Error loading chart")
                                .foregroundColor(.red)
                                .font(.headline)
                            Text(errorMsg)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                            
                            Button("Retry") {
                                vm.fetchBinanceData(symbol: symbol, interval: interval.binanceInterval, limit: interval.binanceLimit)
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.goldButton)
                            .cornerRadius(8)
                        }
                    }
                    else if vm.dataPoints.isEmpty {
                        Text("No chart data")
                            .foregroundColor(.gray)
                    } else {
                        let minClose = vm.dataPoints.map { $0.close }.min() ?? 0
                        let maxClose = vm.dataPoints.map { $0.close }.max() ?? 1
                        let margin = (maxClose - minClose) * 0.05
                        let lowerBound = (minClose - margin)
                        let upperBound = (maxClose + margin)
                        
                        Chart {
                            ForEach(vm.dataPoints) { point in
                                LineMark(
                                    x: .value("Time", point.date),
                                    y: .value("Close", point.close)
                                )
                                .foregroundStyle(.yellow)
                                
                                AreaMark(
                                    x: .value("Time", point.date),
                                    y: .value("Close", point.close)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.yellow.opacity(0.6), .clear]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            }
                            
                            if showCrosshair, let cVal = crosshairValue {
                                RuleMark(x: .value("Crosshair Time", cVal.date))
                                    .foregroundStyle(.white.opacity(0.7))
                                
                                PointMark(
                                    x: .value("Time", cVal.date),
                                    y: .value("Close", cVal.close)
                                )
                                .symbolSize(80)
                                .foregroundStyle(.white)
                                .annotation(position: .top) {
                                    VStack(spacing: 2) {
                                        Text(cVal.date, format: .dateTime
                                            .month(.twoDigits)
                                            .day(.twoDigits)
                                            .hour(.defaultDigits(amPM: .omitted))
                                            .minute(.twoDigits))
                                            .font(.caption2)
                                            .foregroundColor(.white)
                                        Text(formatWithCommas(cVal.close))
                                            .font(.caption2)
                                            .foregroundColor(.white)
                                    }
                                    .padding(6)
                                    .background(Color.black.opacity(0.8))
                                    .cornerRadius(6)
                                }
                            }
                        }
                        .chartYScale(domain: lowerBound...upperBound)
                        .chartXAxis {
                            AxisMarks(values: .automatic(desiredCount: 4)) {
                                AxisGridLine()
                                AxisValueLabel(format: .dateTime
                                    .month(.twoDigits)
                                    .day(.twoDigits)
                                    .hour(.defaultDigits(amPM: .omitted))
                                    .minute(.twoDigits))
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading)
                        }
                        .chartOverlay { proxy in
                            GeometryReader { geo in
                                Rectangle().fill(Color.clear).contentShape(Rectangle())
                                    .gesture(
                                        DragGesture(minimumDistance: 0)
                                            .onChanged { value in
                                                showCrosshair = true
                                                
                                                // For iOS 17, use proxy.plotFrame; iOS 16 uses proxy.plotAreaFrame
                                                let origin = geo[proxy.plotAreaFrame].origin
                                                
                                                let location = CGPoint(
                                                    x: value.location.x - origin.x,
                                                    y: value.location.y - origin.y
                                                )
                                                if let date: Date = proxy.value(atX: location.x) {
                                                    if let closest = findClosest(date: date, in: vm.dataPoints) {
                                                        crosshairValue = closest
                                                    }
                                                }
                                            }
                                            .onEnded { _ in
                                                showCrosshair = false
                                            }
                                    )
                            }
                        }
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
        // For iOS 16 usage (onChange signature)
        .onChange(of: interval) { newInterval in
            vm.fetchBinanceData(symbol: symbol, interval: newInterval.binanceInterval, limit: newInterval.binanceLimit)
        }
    }
    
    // Format with commas for crosshair price
    private func formatWithCommas(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return "$" + (formatter.string(from: NSNumber(value: value)) ?? String(value))
    }
    
    private func findClosest(date: Date, in points: [ChartDataPoint]) -> ChartDataPoint? {
        guard !points.isEmpty else { return nil }
        let sorted = points.sorted { $0.date < $1.date }
        
        if date <= sorted.first!.date {
            return sorted.first!
        }
        if date >= sorted.last!.date {
            return sorted.last!
        }
        
        var closest = sorted.first!
        var minDiff = abs(closest.date.timeIntervalSince(date))
        
        for point in sorted {
            let diff = abs(point.date.timeIntervalSince(date))
            if diff < minDiff {
                minDiff = diff
                closest = point
            }
        }
        return closest
    }
}

// MARK: - ChartDataPoint
struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let close: Double
}

// MARK: - ChartViewModel
class CoinDetailChartViewModel: ObservableObject {
    @Published var dataPoints: [ChartDataPoint] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    func fetchBinanceData(symbol: String, interval: String, limit: Int) {
        let pair = symbol.uppercased() + "USDT"
        let urlString = "https://api.binance.com/api/v3/klines?symbol=\(pair)&interval=\(interval)&limit=\(limit)"
        print("Binance fetch URL:", urlString)
        
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
                // If region restricted or invalid
                if httpResponse.statusCode == 451 {
                    self.fetchBinanceUSData(pair: pair, interval: interval, limit: limit)
                    return
                } else if httpResponse.statusCode == 400 {
                    if let data = data,
                       let body = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let msg = body["msg"] as? String,
                       msg.contains("Invalid interval") {
                        // fallback to 1M
                        self.fetchBinanceData(symbol: symbol, interval: "1M", limit: 12)
                        return
                    }
                } else if httpResponse.statusCode != 200 {
                    let errorBody = String(data: data ?? Data(), encoding: .utf8) ?? "N/A"
                    DispatchQueue.main.async {
                        self.errorMessage = "HTTP \(httpResponse.statusCode)\n\(errorBody)"
                    }
                    return
                }
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    self.errorMessage = "No data received from Binance."
                }
                return
            }
            
            self.parseKlinesJSON(data: data)
        }.resume()
    }
    
    private func fetchBinanceUSData(pair: String, interval: String, limit: Int) {
        let fallbackURL = "https://api.binance.us/api/v3/klines?symbol=\(pair)&interval=\(interval)&limit=\(limit)"
        print("Fallback: Binance US fetch URL:", fallbackURL)
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.dataPoints = []
            self.errorMessage = nil
        }
        
        guard let url = URL(string: fallbackURL) else {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Invalid fallback URL."
            }
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
            }
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Fallback error: \(error.localizedDescription)"
                }
                return
            }
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                let errorBody = String(data: data ?? Data(), encoding: .utf8) ?? "N/A"
                DispatchQueue.main.async {
                    self.errorMessage = "Fallback HTTP \(httpResponse.statusCode)\n\(errorBody)"
                }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async {
                    self.errorMessage = "No data from Binance US."
                }
                return
            }
            
            self.parseKlinesJSON(data: data)
        }.resume()
    }
    
    private func parseKlinesJSON(data: Data) {
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [[Any]] {
                if json.isEmpty {
                    DispatchQueue.main.async {
                        self.errorMessage = "Empty array.\nInvalid symbol or no data."
                    }
                    return
                }
                
                var results: [ChartDataPoint] = []
                for kline in json {
                    if kline.count >= 5 {
                        guard let openTimeMs = kline[0] as? Double else { continue }
                        let date = Date(timeIntervalSince1970: openTimeMs / 1000.0)
                        
                        var closeVal: Double? = nil
                        if let value = kline[4] as? Double {
                            closeVal = value
                        } else if let valueStr = kline[4] as? String, let doubleVal = Double(valueStr) {
                            closeVal = doubleVal
                        }
                        
                        if let close = closeVal {
                            results.append(ChartDataPoint(date: date, close: close))
                        }
                    }
                }
                
                results.sort { $0.date < $1.date }
                DispatchQueue.main.async {
                    self.dataPoints = results
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
    }
}

// MARK: - TradingView with Region Fallback
struct CoinDetailTradingViewWebView: UIViewRepresentable {
    let symbol: String
    let interval: String
    let theme: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        loadTradingViewHTML(into: webView)
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        loadTradingViewHTML(into: uiView)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
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
              try {
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
              } catch(e) {
                document.body.innerHTML = "<h3 style='color:yellow;text-align:center;margin-top:40px;'>TradingView is blocked in your region.</h3>";
              }
            </script>
          </body>
        </html>
        """
        print("Loading TradingView with symbol:", symbol, "interval:", interval)
        webView.loadHTMLString(html, baseURL: URL(string: "https://s3.tradingview.com"))
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            fallbackMessage(in: webView)
        }
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            fallbackMessage(in: webView)
        }
        private func fallbackMessage(in webView: WKWebView) {
            let fallbackHTML = """
            <html><body style="background:#000;color:yellow;text-align:center;padding-top:40px;">
            <h3>TradingView region-blocked or network error.</h3>
            <p>Try a VPN or different region.</p>
            </body></html>
            """
            webView.loadHTMLString(fallbackHTML, baseURL: nil)
        }
    }
}

// MARK: - CoinPaprikaStatsView & ViewModel (Optional)
struct CoinPaprikaStatsView: View {
    let coinSymbol: String
    @ObservedObject var vm: CoinPaprikaStatsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Coin Stats")
                .font(.headline)
                .foregroundColor(.white)
            
            if vm.isLoading {
                ProgressView("Loading stats...")
                    .foregroundColor(.white)
            }
            else if let errorMsg = vm.errorMessage {
                Text("Error: \(errorMsg)")
                    .foregroundColor(.red)
                    .font(.subheadline)
            }
            else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    statCell(title: "Price (USD)", value: vm.price)
                    statCell(title: "24h Change", value: vm.percentChange24h + "%")
                    statCell(title: "Volume (24h)", value: vm.volume24h)
                    statCell(title: "Market Cap", value: vm.marketCap)
                    statCell(title: "Rank", value: vm.rank)
                    statCell(title: "Circulating Supply", value: vm.circulatingSupply)
                    statCell(title: "Max Supply", value: vm.maxSupply)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .blur(radius: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.goldButton.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(20)
        .padding(.horizontal, 16)
        .shadow(color: Color.black.opacity(0.4), radius: 10, x: 0, y: 5)
    }
    
    private func statCell(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

class CoinPaprikaStatsViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    @Published var price: String = "--"
    @Published var percentChange24h: String = "--"
    @Published var volume24h: String = "--"
    @Published var marketCap: String = "--"
    @Published var rank: String = "--"
    @Published var circulatingSupply: String = "--"
    @Published var maxSupply: String = "--"
    
    func fetchCoinPaprikaStats(coinSymbol: String) {
        let coinID = coinPaprikaMapping(coinSymbol)
        let urlStr = "https://api.coinpaprika.com/v1/tickers/\(coinID)"
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        guard let url = URL(string: urlStr) else {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Invalid CoinPaprika URL."
            }
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                self.isLoading = false
            }
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "CoinPaprika fetch error: \(error.localizedDescription)"
                }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async {
                    self.errorMessage = "No data from CoinPaprika."
                }
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    let rnk = json["rank"] as? Int ?? 0
                    let circ = json["circulating_supply"] as? Double ?? 0
                    let maxS = json["max_supply"] as? Double ?? 0
                    if let quotes = json["quotes"] as? [String: Any],
                       let usd = quotes["USD"] as? [String: Any] {
                        let priceVal = usd["price"] as? Double ?? 0
                        let volVal   = usd["volume_24h"] as? Double ?? 0
                        let capVal   = usd["market_cap"] as? Double ?? 0
                        let change24 = usd["percent_change_24h"] as? Double ?? 0
                        
                        DispatchQueue.main.async { [weak self] in
                            guard let self = self else { return }
                            self.price             = self.formatLargeNumber(priceVal)
                            self.volume24h         = self.formatLargeNumber(volVal)
                            self.marketCap         = self.formatLargeNumber(capVal)
                            self.percentChange24h  = String(format: "%.2f", change24)
                            self.rank              = "#\(rnk)"
                            self.circulatingSupply = self.formatLargeNumber(circ)
                            self.maxSupply         = self.formatLargeNumber(maxS)
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.errorMessage = "CoinPaprika parse error: No 'quotes->USD' found."
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.errorMessage = "CoinPaprika parse error: Unexpected JSON structure."
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "CoinPaprika parse error: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    private func coinPaprikaMapping(_ symbol: String) -> String {
        // Expand with more coin IDs from https://api.coinpaprika.com/v1/coins
        switch symbol.uppercased() {
        case "BTC": return "btc-bitcoin"
        case "ETH": return "eth-ethereum"
        case "DOGE": return "doge-dogecoin"
        case "LINK": return "link-chainlink"
        default:     return "btc-bitcoin" // fallback
        }
    }
    
    private func formatLargeNumber(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        if value >= 1_000_000_000 {
            let shortVal = value / 1_000_000_000
            return formatter.string(from: NSNumber(value: shortVal)).map { "\($0)B" } ?? "--"
        } else if value >= 1_000_000 {
            let shortVal = value / 1_000_000
            return formatter.string(from: NSNumber(value: shortVal)).map { "\($0)M" } ?? "--"
        } else if value >= 1_000 {
            let shortVal = value / 1_000
            return formatter.string(from: NSNumber(value: shortVal)).map { "\($0)K" } ?? "--"
        } else {
            return formatter.string(from: NSNumber(value: value)) ?? String(value)
        }
    }
}
