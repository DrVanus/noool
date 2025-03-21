import SwiftUI
import Charts

/// Note: DO NOT redeclare EnhancedChartPricePoint here.
/// It's defined in EnhancedCryptoChartView.swift with Equatable conformance.

/// The order types for placing trades.
enum OrderType: String, CaseIterable {
    case market = "Market"
    case limit = "Limit"
    case stopLimit = "Stop-Limit"
    case trailingStop = "Trailing Stop"
}

/// Possible time ranges for the chart
enum TimeRange: String, CaseIterable {
    case fifteenMin = "15m"
    case thirtyMin  = "30m"
    case oneHour    = "1H"
    case fourHours  = "4H"
    case oneDay     = "1D"
    case oneWeek    = "1W"
    case oneMonth   = "1M"
    case threeMonths = "3M"
    case oneYear    = "1Y"

    var dataPointCount: Int {
        switch self {
        case .fifteenMin:   return 15
        case .thirtyMin:    return 30
        case .oneHour:      return 60
        case .fourHours:    return 48
        case .oneDay:       return 24
        case .oneWeek:      return 168
        case .oneMonth:     return 30
        case .threeMonths:  return 90
        case .oneYear:      return 365
        }
    }

    var intervalInMinutes: Int {
        switch self {
        case .fifteenMin:   return 1
        case .thirtyMin:    return 1
        case .oneHour:      return 1
        case .fourHours:    return 5
        case .oneDay:       return 60
        case .oneWeek:      return 60
        case .oneMonth:     return 24 * 60
        case .threeMonths:  return 24 * 60
        case .oneYear:      return 24 * 60
        }
    }
}

struct TradeView: View {
    // MARK: - State
    @State private var selectedPair: String = "BTC-USD"
    @State private var isBuyOrder: Bool = true
    @State private var orderType: OrderType = .market
    
    // EnhancedChartPricePoint from EnhancedCryptoChartView.swift (conforms to Equatable now)
    @State private var tradeChartData: [EnhancedChartPricePoint] = []
    @State private var selectedRange: TimeRange = .oneDay

    // User input
    @State private var quantity: String = ""
    private let pairs = ["BTC-USD", "ETH-USD", "SOL-USD", "ADA-USD"]
    private let brandColor = Color.yellow

    // Animated glow on buy/sell toggle
    @State private var glowPulse: Bool = false

    // Toggle a simple moving average line
    @State private var showMovingAverage: Bool = false

    // User-chosen horizontal line
    @State private var userLinePrice: Double? = nil

    var body: some View {
        ZStack {
            // Background
            RadialGradient(
                gradient: Gradient(colors: [.black, brandColor.opacity(0.04), .black]),
                center: .center,
                startRadius: 10,
                endRadius: 500
            )
            .ignoresSafeArea()

            // Neon ring behind order card
            Circle()
                .stroke(brandColor.opacity(0.2), lineWidth: 6)
                .frame(width: 450, height: 450)
                .blur(radius: 20)
                .offset(y: 250)

            VStack(spacing: 24) {
                chartCard
                placeOrderCard
                    .padding(.top, -20)
                Spacer()
            }
            .padding(.top, 20)
        }
        .navigationBarHidden(true)
        .onAppear {
            // Animate the glow on buy/sell toggle
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                glowPulse.toggle()
            }
            // Generate initial chart data
            generateChartData(for: selectedRange)
        }
    }

    // MARK: - Chart Card
    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Toggle row for advanced features
            HStack {
                Toggle("Show MA", isOn: $showMovingAverage)
                    .toggleStyle(.switch)
                    .foregroundColor(.white)
                Spacer()
                if userLinePrice != nil {
                    Button("Clear Line") {
                        userLinePrice = nil
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(6)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            // The Chart with gradient fill, main line, user line, and moving average
            Chart {
                gradientAreaAndLine
                userLine
                movingAverageLine
            }
            // SwiftUI requires Equatable conformance to animate changes in the array
            .animation(.easeInOut, value: tradeChartData)
            .frame(height: 300)
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.hour().minute())
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                                .onEnded { drag in
                                    let loc = drag.location
                                    let origin = geo[proxy.plotAreaFrame].origin
                                    let locationY = loc.y - origin.y
                                    if let priceVal: Double = proxy.value(atY: locationY) {
                                        userLinePrice = priceVal
                                    }
                                }
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            // Time range buttons
            HStack {
                Spacer()
                HStack(spacing: 8) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Button(range.rawValue) {
                            selectedRange = range
                            generateChartData(for: range)
                        }
                        .font(.footnote)
                        .foregroundColor(selectedRange == range ? .black : .white)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(
                            selectedRange == range
                            ? brandColor.opacity(0.9)
                            : Color.white.opacity(0.1)
                        )
                        .cornerRadius(8)
                    }
                }
                .padding(.trailing, 12)
            }
            .padding(.bottom, 10)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.25))
                .blur(radius: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(brandColor.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(20)
        .padding(.horizontal, 8)
        .shadow(color: Color.black.opacity(0.4), radius: 10, x: 0, y: 5)
    }

    // MARK: - Chart Content Builders

    /// Combines a gradient area and main price line.
    @ChartContentBuilder
    private var gradientAreaAndLine: some ChartContent {
        // Gradient area under the price line
        ForEach(tradeChartData) { point in
            AreaMark(
                x: .value("Time", point.time),
                y: .value("Price", point.price)
            )
            .foregroundStyle(
                .linearGradient(
                    colors: [brandColor.opacity(0.4), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)
        }
        // Main price line with subtle glow
        ForEach(tradeChartData) { point in
            LineMark(
                x: .value("Time", point.time),
                y: .value("Price", point.price)
            )
            .foregroundStyle(brandColor)
            .interpolationMethod(.catmullRom)
            .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
            .shadow(color: brandColor.opacity(0.5), radius: 3, x: 0, y: 0)
        }
    }

    /// User-chosen horizontal line.
    @ChartContentBuilder
    private var userLine: some ChartContent {
        if let linePrice = userLinePrice {
            RuleMark(y: .value("UserLine", linePrice))
                .foregroundStyle(.red)
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [6,4]))
        }
    }

    /// Optional moving average line.
    @ChartContentBuilder
    private var movingAverageLine: some ChartContent {
        if showMovingAverage {
            let maPoints = computeMovingAveragePoints(tradeChartData)
            ForEach(maPoints) { mp in
                LineMark(
                    x: .value("Time", mp.time),
                    y: .value("MA", mp.price)
                )
                .foregroundStyle(.blue)
                .interpolationMethod(.catmullRom)
            }
        }
    }

    // MARK: - Place an Order Card
    private var placeOrderCard: some View {
        let cardBackground = Color.black.opacity(0.25).blur(radius: 8)
        return VStack(alignment: .leading, spacing: 20) {
            Text("Place an Order")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            // Balance
            HStack {
                Text("Balance: $5,000.00")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
            }
            // Pair + Buy/Sell row
            pairBuySellRow
            // Order type row
            orderTypeRow
            // Quantity field
            quantityField
            // Percentage row
            percentageRow
            // Confirm button
            Button {
                // place order logic
            } label: {
                Text("\(isBuyOrder ? "Buy" : "Sell") \(selectedPair)")
                    .font(.headline)
                    // For Buy, text is black over a yellow (gold) background; Sell remains white
                    .foregroundColor(isBuyOrder ? .black : .white)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(isBuyOrder ? brandColor.opacity(0.85) : Color.red.opacity(0.85))
                    .cornerRadius(12)
            }
            .shadow(color: Color.black.opacity(0.4), radius: 5, x: 0, y: 2)
        }
        .padding(20)
        .background(cardBackground)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(brandColor.opacity(0.15), lineWidth: 1)
        )
        .cornerRadius(20)
        .padding(.horizontal, 16)
        .shadow(color: Color.black.opacity(0.6), radius: 10, x: 0, y: 5)
    }

    // MARK: - Pair + Buy/Sell Row
    private var pairBuySellRow: some View {
        HStack {
            Menu {
                ForEach(pairs, id: \.self) { pair in
                    Button(pair) { selectedPair = pair }
                }
            } label: {
                HStack {
                    Text(selectedPair).font(.headline)
                    Image(systemName: "chevron.down").font(.caption)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.1))
                .cornerRadius(10)
            }
            Spacer()
            HStack(spacing: 0) {
                Button("Buy") {
                    isBuyOrder = true
                }
                .font(.headline)
                .foregroundColor(isBuyOrder ? .black : .white)
                .padding(.vertical, 8)
                .padding(.horizontal, 20)
                .background(isBuyOrder ? brandColor.opacity(0.8) : Color.white.opacity(0.1))
                .shadow(color: isBuyOrder ? brandColor.opacity(glowPulse ? 0.5 : 0.2) : .clear, radius: glowPulse ? 12 : 0, x: 0, y: 0)
                
                Button("Sell") {
                    isBuyOrder = false
                }
                .font(.headline)
                .foregroundColor(!isBuyOrder ? .black : .white)
                .padding(.vertical, 8)
                .padding(.horizontal, 20)
                .background(!isBuyOrder ? Color.red.opacity(0.8) : Color.white.opacity(0.1))
                .shadow(color: !isBuyOrder ? Color.red.opacity(glowPulse ? 0.5 : 0.2) : .clear, radius: glowPulse ? 12 : 0, x: 0, y: 0)
            }
            .cornerRadius(10)
        }
    }

    // MARK: - Order Type Row
    private var orderTypeRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(OrderType.allCases, id: \.self) { type in
                    Button(type.rawValue) {
                        orderType = type
                    }
                    .font(.footnote)
                    .foregroundColor(orderType == type ? .black : .white)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 14)
                    .background(orderType == type ? brandColor.opacity(0.85) : Color.white.opacity(0.1))
                    .cornerRadius(10)
                }
            }
        }
    }

    // MARK: - Quantity Field
    private var quantityField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Quantity")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            TextField("0.00", text: $quantity)
                .keyboardType(.decimalPad)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.1))
                .cornerRadius(10)
        }
    }

    // MARK: - Percentage Row
    private var percentageRow: some View {
        HStack {
            ForEach([25, 50, 75, 100], id: \.self) { percent in
                Button("\(percent)%") {
                    quantity = "\(percent)"
                }
                .font(.footnote)
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
            }
            Spacer()
        }
    }

    // MARK: - Generate Chart Data
    private func generateChartData(for range: TimeRange) {
        let now = Date()
        let totalPoints = range.dataPointCount
        let interval = range.intervalInMinutes

        var tempData: [EnhancedChartPricePoint] = []
        var currentTime = now

        for _ in 0..<totalPoints {
            let price = Double.random(in: 20000...25000)
            tempData.append(EnhancedChartPricePoint(time: currentTime, price: price))
            if let newTime = Calendar.current.date(byAdding: .minute, value: -interval, to: currentTime) {
                currentTime = newTime
            }
        }
        tradeChartData = tempData.sorted { $0.time < $1.time }
    }

    // MARK: - Compute a Simple Moving Average
    private func computeMovingAveragePoints(_ data: [EnhancedChartPricePoint]) -> [EnhancedChartPricePoint] {
        guard data.count > 2 else { return [] }
        var result: [EnhancedChartPricePoint] = []
        let sortedData = data.sorted { $0.time < $1.time }
        for i in 2..<sortedData.count {
            let slice = sortedData[(i-2)...i]
            let avgPrice = slice.map { $0.price }.reduce(0, +) / 3.0
            let time = sortedData[i].time
            result.append(EnhancedChartPricePoint(time: time, price: avgPrice))
        }
        return result
    }
}

struct TradeView_Previews: PreviewProvider {
    static var previews: some View {
        TradeView()
            .preferredColorScheme(.dark)
    }
}
