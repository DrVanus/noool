import SwiftUI
import Charts

/// NOTE:
/// Do NOT redeclare EnhancedChartPricePoint here.
/// It's defined in EnhancedChartPricePoint.swift with Equatable conformance.

enum OrderType: String, CaseIterable {
    case market = "Market"
    case limit = "Limit"
    case stopLimit = "Stop-Limit"
    case trailingStop = "Trailing Stop"
}

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

    // Chart data
    @State private var tradeChartData: [EnhancedChartPricePoint] = []
    @State private var selectedRange: TimeRange = .oneDay

    // User inputs
    @State private var quantity: String = ""
    @State private var limitPrice: String = ""
    @State private var stopPrice: String = ""
    @State private var trailingOffset: String = ""

    // Crosshair for chart
    @State private var crosshairValue: EnhancedChartPricePoint? = nil
    @State private var showCrosshair: Bool = false

    // Toggles
    @State private var showMovingAverage: Bool = false
    @State private var userLinePrice: Double? = nil

    // Animated glow on buy/sell
    @State private var glowPulse: Bool = false

    private let pairs = ["BTC-USD", "ETH-USD", "SOL-USD", "ADA-USD"]
    private let brandColor = Color.yellow

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

            // Neon ring
            Circle()
                .stroke(brandColor.opacity(0.2), lineWidth: 6)
                .frame(width: 450, height: 450)
                .blur(radius: 20)
                .offset(y: 250)

            VStack(spacing: 0) {
                // Scrollable content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        chartCard
                        orderFields // everything except final confirm button
                        Spacer(minLength: 100) // so last fields don't hide behind pinned button
                    }
                    .padding(.top, 20)
                }
                .edgesIgnoringSafeArea(.bottom)

                // Pinned buy/sell button
                pinnedBuySellButton
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // Animate glow
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                glowPulse.toggle()
            }
            // Generate chart data
            generateChartData(for: selectedRange)
        }
    }

    // MARK: - Chart Card
    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Toggle row
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

            // Chart
            Chart {
                gradientArea
                mainLine
                userLineMark
                movingAverageMark
                crosshairMarks
            }
            .frame(height: 300) // adjust as desired
            .chartXAxis {
                AxisMarks(values: .automatic) {
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.hour().minute())
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) {
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
                                .onChanged { drag in
                                    let plotOrigin = geo[proxy.plotAreaFrame].origin
                                    let xPos = drag.location.x - plotOrigin.x
                                    let yPos = drag.location.y - plotOrigin.y
                                    if let date: Date = proxy.value(atX: xPos),
                                       let _ = proxy.value(atY: yPos) as Double? {
                                        crosshairValue = findClosest(to: date, in: tradeChartData)
                                        showCrosshair = true
                                    }
                                }
                                .onEnded { _ in
                                    showCrosshair = false
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

    // MARK: - Scrollable Order Fields (minus final button)
    private var orderFields: some View {
        VStack(alignment: .leading, spacing: 20) {
            pairBuySellRow
            orderTypeRow
            quantityField

            if orderType == .limit {
                limitPriceField
            } else if orderType == .stopLimit {
                stopPriceField
                limitPriceField
            } else if orderType == .trailingStop {
                trailingStopField
            }

            percentageRow
            orderSummary
        }
        .padding(16)
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
        .padding(.horizontal, 16)
        .shadow(color: Color.black.opacity(0.4), radius: 10, x: 0, y: 5)
    }

    // MARK: - Pinned Buy/Sell Button
    private var pinnedBuySellButton: some View {
        HStack {
            Button {
                // place order logic
            } label: {
                Text("\(isBuyOrder ? "Buy" : "Sell") \(selectedPair)")
                    .font(.headline)
                    .foregroundColor(isBuyOrder ? .black : .white)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(isBuyOrder ? brandColor.opacity(0.85) : Color.red.opacity(0.85))
                    .cornerRadius(12)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.8))
        .shadow(color: Color.black.opacity(0.6), radius: 10, x: 0, y: -3)
    }

    // MARK: - Chart Content Builders
    @ChartContentBuilder
    private var gradientArea: some ChartContent {
        ForEach(tradeChartData, id: \.id) { point in
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
    }

    @ChartContentBuilder
    private var mainLine: some ChartContent {
        ForEach(tradeChartData, id: \.id) { point in
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

    @ChartContentBuilder
    private var userLineMark: some ChartContent {
        if let linePrice = userLinePrice {
            RuleMark(y: .value("UserLine", linePrice))
                .foregroundStyle(.red)
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [6,4]))
        }
    }

    @ChartContentBuilder
    private var movingAverageMark: some ChartContent {
        if showMovingAverage {
            let maPoints = computeMovingAveragePoints(tradeChartData)
            ForEach(maPoints, id: \.id) { mp in
                LineMark(
                    x: .value("Time", mp.time),
                    y: .value("MA", mp.price)
                )
                .foregroundStyle(.blue)
                .interpolationMethod(.catmullRom)
            }
        }
    }

    @ChartContentBuilder
    private var crosshairMarks: some ChartContent {
        if showCrosshair, let cVal = crosshairValue {
            RuleMark(x: .value("CrosshairTime", cVal.time))
                .foregroundStyle(.white.opacity(0.6))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [3,3]))

            PointMark(
                x: .value("Time", cVal.time),
                y: .value("Price", cVal.price)
            )
            .symbolSize(100)
            .foregroundStyle(.white)
            .annotation(position: .top, alignment: .center) {
                VStack(spacing: 2) {
                    Text("\(cVal.time, format: .dateTime.hour().minute())")
                        .font(.caption2)
                        .foregroundColor(.white)
                    Text("$\(Int(cVal.price))")
                        .font(.caption)
                        .bold()
                        .foregroundColor(.white)
                }
                .padding(6)
                .background(Color.black.opacity(0.8))
                .cornerRadius(6)
                .offset(y: -8)
            }
        }
    }

    // MARK: - Pair + Buy/Sell
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
                .shadow(color: isBuyOrder ? brandColor.opacity(glowPulse ? 0.5 : 0.2) : .clear,
                        radius: glowPulse ? 12 : 0, x: 0, y: 0)

                Button("Sell") {
                    isBuyOrder = false
                }
                .font(.headline)
                .foregroundColor(!isBuyOrder ? .black : .white)
                .padding(.vertical, 8)
                .padding(.horizontal, 20)
                .background(!isBuyOrder ? Color.red.opacity(0.8) : Color.white.opacity(0.1))
                .shadow(color: !isBuyOrder ? Color.red.opacity(glowPulse ? 0.5 : 0.2) : .clear,
                        radius: glowPulse ? 12 : 0, x: 0, y: 0)
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

    // MARK: - Quantity Field (+/-)
    private var quantityField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Quantity")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            HStack(spacing: 8) {
                Button {
                    decrementQuantity()
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                TextField("0.00", text: $quantity)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(10)
                    .frame(width: 100)
                Button {
                    incrementQuantity()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                Spacer()
            }
        }
    }

    // MARK: - Advanced Fields
    private var limitPriceField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Limit Price")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            TextField("0.00", text: $limitPrice)
                .keyboardType(.decimalPad)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.1))
                .cornerRadius(10)
        }
    }

    private var stopPriceField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Stop Price")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            TextField("0.00", text: $stopPrice)
                .keyboardType(.decimalPad)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.1))
                .cornerRadius(10)
        }
    }

    private var trailingStopField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Trailing Offset")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            TextField("e.g. 100 (USD) or 5 (%)", text: $trailingOffset)
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

    // MARK: - Order Summary
    private var orderSummary: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Order Summary")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            Text("Price: \(displayPrice())")
                .foregroundColor(.white.opacity(0.8))
            Text("Quantity: \(quantity.isEmpty ? "0.00" : quantity)")
                .foregroundColor(.white.opacity(0.8))
            Text("Estimated Fees: $0.50")
                .foregroundColor(.white.opacity(0.8))
            Text("Estimated Total: \(displayEstimatedTotal())")
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.top, 4)
    }

    // MARK: - Helpers
    private func displayPrice() -> String {
        switch orderType {
        case .market:
            return "$28,000 (market)"
        case .limit:
            return "$\(limitPrice.isEmpty ? "0.00" : limitPrice)"
        case .stopLimit:
            let stopVal = stopPrice.isEmpty ? "0.00" : stopPrice
            let limitVal = limitPrice.isEmpty ? "0.00" : limitPrice
            return "Stop: \(stopVal), Limit: \(limitVal)"
        case .trailingStop:
            return "Offset: \(trailingOffset.isEmpty ? "n/a" : trailingOffset)"
        }
    }

    private func displayEstimatedTotal() -> String {
        guard let qty = Double(quantity), qty > 0 else {
            return "$0.00"
        }
        switch orderType {
        case .market:
            let total = 28000.0 * qty
            return String(format: "$%.2f", total)
        case .limit, .stopLimit:
            if let lp = Double(limitPrice), lp > 0 {
                return String(format: "$%.2f", lp * qty)
            }
            return "$0.00"
        case .trailingStop:
            return "Depends on trigger"
        }
    }

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

    private func computeMovingAveragePoints(_ data: [EnhancedChartPricePoint]) -> [EnhancedChartPricePoint] {
        guard data.count > 2 else { return [] }
        let sortedData = data.sorted { $0.time < $1.time }
        var result: [EnhancedChartPricePoint] = []
        for i in 2..<sortedData.count {
            let slice = sortedData[(i-2)...i]
            let avgPrice = slice.map { $0.price }.reduce(0, +) / 3.0
            result.append(EnhancedChartPricePoint(time: sortedData[i].time, price: avgPrice))
        }
        return result
    }

    private func findClosest(to target: Date, in data: [EnhancedChartPricePoint]) -> EnhancedChartPricePoint? {
        guard !data.isEmpty else { return nil }
        let sorted = data.sorted { $0.time < $1.time }
        if target <= sorted.first!.time { return sorted.first! }
        if target >= sorted.last!.time { return sorted.last! }
        for i in 0..<(sorted.count - 1) {
            let curr = sorted[i]
            let next = sorted[i + 1]
            if curr.time <= target && target <= next.time {
                if target == curr.time { return curr }
                if target == next.time { return next }
                let t0 = curr.time.timeIntervalSince1970
                let t1 = next.time.timeIntervalSince1970
                let t = target.timeIntervalSince1970
                let ratio = (t - t0) / (t1 - t0)
                let interpolatedPrice = curr.price + ratio * (next.price - curr.price)
                return EnhancedChartPricePoint(time: target, price: interpolatedPrice)
            }
        }
        return nil
    }

    private func incrementQuantity() {
        let current = Double(quantity) ?? 0
        quantity = String(format: "%.4f", current + 0.01)
    }

    private func decrementQuantity() {
        let current = Double(quantity) ?? 0
        let newVal = max(0, current - 0.01)
        quantity = String(format: "%.4f", newVal)
    }
}

struct TradeView_Previews: PreviewProvider {
    static var previews: some View {
        TradeView()
            .preferredColorScheme(.dark)
    }
}
