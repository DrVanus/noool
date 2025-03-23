import SwiftUI
import Charts
import WebKit

// MARK: - TradeSide / OrderType
enum TradeSide: String, CaseIterable {
    case buy, sell
}
enum OrderType: String, CaseIterable {
    case market
    case limit
    case stopLimit = "stop-limit"
    case trailingStop = "trailing stop"
}

// MARK: - TradeChartType
enum TradeChartType: String, CaseIterable {
    case cryptoSageAI = "CryptoSage AI"
    case tradingView  = "TradingView"
}

// MARK: - TradeView
struct TradeView: View {
    
    let symbol: String
    
    @StateObject private var vm = TradeViewModel()
    @StateObject private var orderBookVM = OrderBookViewModel()
    @StateObject private var priceVM: PriceViewModel  // For live price

    // Chart & Trade states
    @State private var selectedChartType: TradeChartType = .cryptoSageAI
    @State private var selectedInterval: ChartInterval = .oneHour
    @State private var selectedSide: TradeSide = .buy
    @State private var orderType: OrderType = .market
    @State private var quantity: String = "0.0"
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    // Init with a default symbol "BTC"
    init(symbol: String = "BTC") {
        self.symbol = symbol
        // Initialize the price view model
        _priceVM = StateObject(wrappedValue: PriceViewModel(symbol: symbol))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            // 1) Nav Bar
            navBar
            
            // 2) Live Price Row
            priceRow
            
            // 3) Chart (like coin pages)
            chartSection
                .frame(height: 240)
            
            // 4) Interval Picker
            intervalPicker
            
            // 5) Chart Type Toggle
            chartTypeToggle
            
            // 6) Trade Form
            tradeForm
            
            // 7) Order Book (live)
            orderBookSection
            
            Spacer()
        }
        .background(Color.black.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .onAppear {
            vm.currentSymbol = symbol
            orderBookVM.startFetchingOrderBook(for: symbol)
        }
        .onDisappear {
            orderBookVM.stopFetching()
        }
    }
    
    // MARK: - Nav Bar
    private var navBar: some View {
        ZStack {
            HStack {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.yellow)
                        Text("Back")
                            .foregroundColor(.yellow)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            
            HStack {
                Spacer()
                Text(symbol.uppercased())
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
            }
        }
        .padding(.vertical, 8)
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    // MARK: - Live Price Row
    private var priceRow: some View {
        HStack {
            Text("Price: ")
                .foregroundColor(.white)
            Text("$\(priceVM.currentPrice, specifier: "%.4f")")
                .foregroundColor(.yellow)
                .font(.system(size: 18, weight: .semibold))
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 16)
        .background(Color.white.opacity(0.05))
    }
    
    // MARK: - Chart Section
    @ViewBuilder
    private var chartSection: some View {
        if selectedChartType == .cryptoSageAI {
            TradeCustomChart(symbol: symbol, interval: selectedInterval)
        } else {
            let tvSymbol = "BINANCE:\(symbol.uppercased())USDT"
            let tvTheme = (colorScheme == .dark) ? "Dark" : "Light"
            TradeViewTradingWebView(symbol: tvSymbol,
                                    interval: selectedInterval.tvValue,
                                    theme: tvTheme)
        }
    }
    
    // MARK: - Interval Picker
    private var intervalPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(ChartInterval.allCases, id: \.self) { interval in
                    Button {
                        selectedInterval = interval
                    } label: {
                        Text(interval.rawValue)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .padding(.vertical, 5)
                            .padding(.horizontal, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(selectedInterval == interval
                                          ? Color.yellow
                                          : Color.white.opacity(0.15))
                            )
                            .foregroundColor(selectedInterval == interval ? .black : .white)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Chart Type Toggle
    private var chartTypeToggle: some View {
        HStack(spacing: 0) {
            ForEach(TradeChartType.allCases, id: \.self) { type in
                Button {
                    selectedChartType = type
                } label: {
                    Text(type.rawValue)
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundColor(selectedChartType == type ? .black : .white)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(
                            selectedChartType == type
                            ? Color.yellow
                            : Color.white.opacity(0.15)
                        )
                }
            }
        }
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
    
    // MARK: - Trade Form
    private var tradeForm: some View {
        VStack(spacing: 12) {
            // Buy / Sell Switch
            HStack {
                ForEach(TradeSide.allCases, id: \.self) { side in
                    Button {
                        selectedSide = side
                    } label: {
                        Text(side.rawValue.capitalized)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(
                                selectedSide == side
                                ? (side == .sell ? .white : .black)
                                : .white
                            )
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(
                                selectedSide == side
                                ? (side == .sell ? Color.red : Color.yellow)
                                : Color.white.opacity(0.15)
                            )
                    }
                }
            }
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .padding(.horizontal, 16)
            
            // Order Type
            Picker("Order Type", selection: $orderType) {
                ForEach(OrderType.allCases, id: \.self) { type in
                    Text(type.rawValue.capitalized).tag(type)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal, 16)
            
            // Quantity + - Row
            HStack {
                Text("Quantity:")
                    .foregroundColor(.white)
                
                // - button
                Button {
                    vm.decrementQuantity(&quantity)
                } label: {
                    Image(systemName: "minus.circle")
                        .foregroundColor(.white)
                }
                .padding(6)
                .background(Color.white.opacity(0.15))
                .cornerRadius(6)
                
                TextField("0.0", text: $quantity)
                    .keyboardType(.decimalPad)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                    .frame(width: 80)
                
                // + button
                Button {
                    vm.incrementQuantity(&quantity)
                } label: {
                    Image(systemName: "plus.circle")
                        .foregroundColor(.white)
                }
                .padding(6)
                .background(Color.white.opacity(0.15))
                .cornerRadius(6)
            }
            .padding(.horizontal, 16)
            
            // Quick % Buttons
            HStack(spacing: 8) {
                ForEach([25, 50, 75, 100], id: \.self) { pct in
                    Button {
                        quantity = vm.fillQuantity(forPercent: pct)
                    } label: {
                        Text("\(pct)%")
                            .foregroundColor(.white)
                            .padding(6)
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(6)
                    }
                }
            }
            
            // Submit
            Button(action: {
                vm.executeTrade(side: selectedSide,
                                symbol: symbol,
                                orderType: orderType,
                                quantity: quantity)
            }) {
                Text("\(selectedSide.rawValue.capitalized) \(symbol.uppercased())")
                    .font(.headline)
                    .foregroundColor(selectedSide == .sell ? .white : .black)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(selectedSide == .sell ? Color.red : Color.yellow)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .padding(.top, 12)
        .background(Color.black.opacity(0.1))
    }
    
    // MARK: - Live Order Book
    private var orderBookSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Order Book (Live Depth)")
                .font(.headline)
                .foregroundColor(.white)
            
            if orderBookVM.isLoading {
                ProgressView("Loading order book...")
                    .foregroundColor(.white)
            } else if let err = orderBookVM.errorMessage {
                Text("Error: \(err)")
                    .foregroundColor(.red)
                    .font(.caption)
            } else {
                HStack(alignment: .top, spacing: 16) {
                    // Bids
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Bids")
                            .font(.subheadline)
                            .foregroundColor(.green)
                        ForEach(orderBookVM.bids.prefix(5), id: \.price) { bid in
                            Text("\(bid.price) | \(bid.qty)")
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.white)
                    
                    // Asks
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Asks")
                            .font(.subheadline)
                            .foregroundColor(.red)
                        ForEach(orderBookVM.asks.prefix(5), id: \.price) { ask in
                            Text("\(ask.price) | \(ask.qty)")
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.white)
                }
            }
        }
        .padding(8)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
}

// MARK: - TradeViewModel
class TradeViewModel: ObservableObject {
    @Published var currentSymbol: String = "BTC"
    
    func incrementQuantity(_ quantity: inout String) {
        if let val = Double(quantity) {
            quantity = String(val + 1.0)
        }
    }
    func decrementQuantity(_ quantity: inout String) {
        if let val = Double(quantity), val > 0 {
            quantity = String(max(0, val - 1.0))
        }
    }
    
    func fillQuantity(forPercent pct: Int) -> String {
        // Example: if user has 10 BTC, 25% => 2.5
        // This is just a placeholder
        return "TODO"
    }
    
    func executeTrade(side: TradeSide, symbol: String, orderType: OrderType, quantity: String) {
        // Perform the trade logic, call your backend, etc.
        print("Execute \(side.rawValue) on \(symbol) with \(orderType.rawValue), qty=\(quantity)")
    }
}

// MARK: - OrderBookViewModel
class OrderBookViewModel: ObservableObject {
    struct OrderBookEntry {
        let price: String
        let qty: String
    }
    
    @Published var bids: [OrderBookEntry] = []
    @Published var asks: [OrderBookEntry] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private var timer: Timer?
    
    func startFetchingOrderBook(for symbol: String) {
        let pair = symbol.uppercased() + "USDT"
        fetchOrderBook(pair: pair)
        
        // Refresh every 5s
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            self.fetchOrderBook(pair: pair)
        }
    }
    
    func stopFetching() {
        timer?.invalidate()
        timer = nil
    }
    
    private func fetchOrderBook(pair: String) {
        let urlString = "https://api.binance.com/api/v3/depth?symbol=\(pair)&limit=10"
        
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async {
                self.errorMessage = "Invalid order book URL."
            }
            return
        }
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
            }
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Order book fetch error: \(error.localizedDescription)"
                }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async {
                    self.errorMessage = "No data from order book."
                }
                return
            }
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let bids = json["bids"] as? [[Any]],
                       let asks = json["asks"] as? [[Any]] {
                        
                        let parsedBids: [OrderBookEntry] = bids.map { arr in
                            let price = arr[0] as? String ?? "0"
                            let qty   = arr[1] as? String ?? "0"
                            return OrderBookEntry(price: price, qty: qty)
                        }
                        let parsedAsks: [OrderBookEntry] = asks.map { arr in
                            let price = arr[0] as? String ?? "0"
                            let qty   = arr[1] as? String ?? "0"
                            return OrderBookEntry(price: price, qty: qty)
                        }
                        DispatchQueue.main.async {
                            self.bids = parsedBids
                            self.asks = parsedAsks
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.errorMessage = "Order book parse error."
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.errorMessage = "Invalid JSON for order book."
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

// MARK: - TradeCustomChart
struct TradeCustomChart: View {
    let symbol: String
    let interval: ChartInterval
    
    @StateObject private var vm = CoinDetailChartViewModel()
    @State private var crosshairValue: ChartDataPoint? = nil
    @State private var showCrosshair: Bool = false
    
    var body: some View {
        VStack {
            if vm.isLoading {
                ProgressView("Loading chart...")
                    .foregroundColor(.white)
            } else if let errorMsg = vm.errorMessage {
                errorView(errorMsg)
            } else if vm.dataPoints.isEmpty {
                Text("No chart data")
                    .foregroundColor(.gray)
            } else {
                chartContent
            }
        }
        .onAppear {
            vm.fetchBinanceData(symbol: symbol,
                                interval: interval.binanceInterval,
                                limit: interval.binanceLimit)
        }
        .onChange(of: interval) { _, newVal in
            vm.fetchBinanceData(symbol: symbol,
                                interval: newVal.binanceInterval,
                                limit: newVal.binanceLimit)
        }
    }
    
    @ViewBuilder
    @available(iOS 16.0, *)
    private var chartContent: some View {
        let minClose = vm.dataPoints.map { $0.close }.min() ?? 0
        let maxClose = vm.dataPoints.map { $0.close }.max() ?? 1
        
        let topMargin = (maxClose - minClose) * 0.03
        let clampedLowerBound = max(0, minClose)
        let upperBound = maxClose + topMargin
        
        let firstDate = vm.dataPoints.first?.date ?? Date()
        let lastDate  = vm.dataPoints.last?.date ?? Date()
        
        let axisLabelCount: Int = {
            switch interval {
            case .oneMin, .fiveMin: return 6
            case .oneYear, .threeYear, .all: return 3
            default: return 4
            }
        }()
        
        Chart {
            // Main line + area
            ForEach(vm.dataPoints) { point in
                LineMark(
                    x: .value("Time", point.date),
                    y: .value("Close", point.close)
                )
                .foregroundStyle(.yellow)
                
                AreaMark(
                    x: .value("Time", point.date),
                    yStart: .value("Close", clampedLowerBound),
                    yEnd: .value("Close", point.close)
                )
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            .yellow.opacity(0.3),
                            .yellow.opacity(0.15),
                            .yellow.opacity(0.05),
                            .clear
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            
            // Crosshair
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
                        if interval.hideCrosshairTime {
                            Text(cVal.date, format: .dateTime
                                .month(.abbreviated)
                                .year())
                                .font(.caption2)
                                .foregroundColor(.white)
                        } else {
                            switch interval {
                            case .oneMin, .fiveMin:
                                Text(formatTimeLocalHM(cVal.date))
                                    .font(.caption2)
                                    .foregroundColor(.white)
                            case .fifteenMin, .thirtyMin, .oneHour, .fourHour:
                                Text(formatTimeLocal(cVal.date))
                                    .font(.caption2)
                                    .foregroundColor(.white)
                            case .oneDay, .oneWeek, .oneMonth, .threeMonth:
                                Text(cVal.date, format: .dateTime
                                    .month(.abbreviated)
                                    .day(.twoDigits))
                                    .font(.caption2)
                                    .foregroundColor(.white)
                            default:
                                Text(cVal.date, format: .dateTime
                                    .month(.abbreviated)
                                    .year())
                                    .font(.caption2)
                                    .foregroundColor(.white)
                            }
                        }
                        
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
        .chartYScale(domain: clampedLowerBound...upperBound)
        .chartXScale(domain: firstDate...lastDate)
        .chartXScale(range: 0.05...0.95)
        .chartPlotStyle { plotArea in
            plotArea
                .background(Color.black.opacity(0.05))
                .padding(.bottom, 40)
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: axisLabelCount)) { value in
                AxisGridLine()
                    .foregroundStyle(.white.opacity(0.2))
                
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(formatAxisDate(date))
                            .font(.system(size: 10))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) {
                AxisGridLine()
                    .foregroundStyle(.white.opacity(0.2))
                
                AxisValueLabel()
                    .foregroundStyle(.white)
                    .font(.footnote)
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geo in
                Rectangle().fill(Color.clear).contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { drag in
                                showCrosshair = true
                                let location = drag.location
                                
                                if #available(iOS 17.0, *) {
                                    if let anchor = proxy.plotFrame {
                                        let origin = geo[anchor].origin
                                        let relativeX = location.x - origin.x
                                        if let date: Date = proxy.value(atX: relativeX) {
                                            if let closest = findClosest(date: date, in: vm.dataPoints) {
                                                crosshairValue = closest
                                            }
                                        }
                                    }
                                } else {
                                    let origin = geo[proxy.plotAreaFrame].origin
                                    let relativeX = location.x - origin.x
                                    if let date: Date = proxy.value(atX: relativeX) {
                                        if let closest = findClosest(date: date, in: vm.dataPoints) {
                                            crosshairValue = closest
                                        }
                                    }
                                }
                            }
                            .onEnded { _ in
                                showCrosshair = false
                            }
                    )
            }
        }
        .overlay(
            LinearGradient(gradient: Gradient(colors: [.clear, .black.opacity(0.5)]),
                           startPoint: .top,
                           endPoint: .bottom)
                .frame(height: 40)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .allowsHitTesting(false)
        )
    }
    
    // MARK: - Helpers
    private func formatAxisDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = .current
        
        switch interval {
        case .oneMin, .fiveMin:
            df.dateFormat = "h:mm a"
        case .fifteenMin, .thirtyMin, .oneHour, .fourHour:
            df.dateFormat = "ha"
        case .oneDay, .oneWeek, .oneMonth, .threeMonth:
            let day = Calendar.current.component(.day, from: date)
            df.dateFormat = (day == 1) ? "MMM" : "MMM d"
        default:
            df.dateFormat = "MMM yyyy"
        }
        return df.string(from: date)
    }
    
    private func formatTimeLocalHM(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = .current
        df.dateFormat = "h:mm a"
        return df.string(from: date)
    }
    
    private func formatTimeLocal(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = .current
        df.dateFormat = "ha"
        return df.string(from: date)
    }
    
    private func findClosest(date: Date, in points: [ChartDataPoint]) -> ChartDataPoint? {
        guard !points.isEmpty else { return nil }
        let sorted = points.sorted { $0.date < $1.date }
        if date <= sorted.first!.date { return sorted.first! }
        if date >= sorted.last!.date { return sorted.last! }
        
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
    
    private func errorView(_ errorMsg: String) -> some View {
        VStack(spacing: 10) {
            Text("Error loading chart")
                .foregroundColor(.red)
                .font(.headline)
            Text(errorMsg)
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Button("Retry") {
                vm.fetchBinanceData(symbol: symbol,
                                    interval: interval.binanceInterval,
                                    limit: interval.binanceLimit)
            }
            .foregroundColor(.black)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.yellow)
            .cornerRadius(8)
        }
        .padding()
    }
    
    private func formatWithCommas(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        if value < 1 {
            formatter.maximumFractionDigits = 4
        } else if value < 1000 {
            formatter.maximumFractionDigits = 2
        } else {
            formatter.maximumFractionDigits = 0
        }
        return "$" + (formatter.string(from: NSNumber(value: value)) ?? String(value))
    }
}

// MARK: - TradeViewTradingWebView
struct TradeViewTradingWebView: UIViewRepresentable {
    let symbol: String
    let interval: String
    let theme: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        loadHTML(into: webView)
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        loadHTML(into: uiView)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    private func loadHTML(into webView: WKWebView) {
        let html = """
        <!DOCTYPE html>
        <html>
          <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
              html, body { margin: 0; padding: 0; height: 100%; background: transparent; }
              #tv_chart_container { width:100%; height:100%; }
            </style>
          </head>
          <body>
            <div id="tv_chart_container"></div>
            <script src="https://www.tradingview.com/tv.js"></script>
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
        webView.loadHTMLString(html, baseURL: URL(string: "https://www.tradingview.com"))
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView,
                     didFinish navigation: WKNavigation!) {
            print("TradingView content finished loading.")
        }
        
        func webView(_ webView: WKWebView,
                     didFail navigation: WKNavigation!,
                     withError error: Error) {
            fallbackMessage(in: webView)
        }
        
        func webView(_ webView: WKWebView,
                     didFailProvisionalNavigation navigation: WKNavigation!,
                     withError error: Error) {
            fallbackMessage(in: webView)
        }
        
        private func fallbackMessage(in webView: WKWebView) {
            let fallbackHTML = """
            <html><body style="background:transparent;color:yellow;text-align:center;padding-top:40px;">
            <h3>TradingView is blocked in your region or unavailable.</h3>
            <p>Try a VPN or different region.</p>
            </body></html>
            """
            webView.loadHTMLString(fallbackHTML, baseURL: nil)
        }
    }
}

// MARK: - PriceViewModel (NEW)
class PriceViewModel: ObservableObject {
    @Published var currentPrice: Double = 0.0
    
    private var timer: Timer?
    private let symbol: String
    
    init(symbol: String) {
        self.symbol = symbol.uppercased()
        fetchPrice()
        
        // Update price every 10 seconds (adjust as needed)
        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
            self.fetchPrice()
        }
    }
    
    deinit {
        timer?.invalidate()
    }
    
    private func fetchPrice() {
        // e.g. "BTC" => "BTCUSDT" for Binance
        let pair = symbol + "USDT"
        let urlStr = "https://api.binance.com/api/v3/ticker/price?symbol=\(pair)"
        
        guard let url = URL(string: urlStr) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data, error == nil {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String:Any],
                   let priceStr = json["price"] as? String,
                   let priceDbl = Double(priceStr) {
                    DispatchQueue.main.async {
                        self.currentPrice = priceDbl
                    }
                }
            }
        }.resume()
    }
}
