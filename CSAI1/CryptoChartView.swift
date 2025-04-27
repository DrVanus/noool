//
//  ChartDataPoint.swift
//  CSAI1
//
//  Created by DM on 4/23/25.
//


// Live window duration in seconds for the live chart interval
private let liveWindow: TimeInterval = 300
import Foundation
import SwiftUI
import Charts
import Combine

// MARK: – Data Model
struct ChartDataPoint: Identifiable, Equatable {
    let id: UUID
    let date: Date
    let close: Double
    let volume: Double

    init(id: UUID = UUID(), date: Date, close: Double, volume: Double = 0) {
        self.id = id
        self.date = date
        self.close = close
        self.volume = volume
    }
}

// MARK: – Interval Enum
enum ChartInterval: String, CaseIterable {
    case live = "LIVE"
    case oneMin = "1m", fiveMin = "5m", fifteenMin = "15m", thirtyMin = "30m"
    case oneHour = "1H", fourHour = "4H", oneDay = "1D", oneWeek = "1W"
    case oneMonth = "1M", threeMonth = "3M", oneYear = "1Y", threeYear = "3Y", all = "ALL"
    
    var binanceInterval: String {
        switch self {
        case .live:
            return "1m"
        default:
            return self.rawValue.lowercased()
        }
    }
    var binanceLimit: Int {
        switch self {
        case .live:      return Int(liveWindow)
        case .oneMin:     return 60
        case .fiveMin:    return 48
        case .fifteenMin: return 24
        case .thirtyMin:  return 24
        case .oneHour:    return 48
        case .fourHour:   return 120
        case .oneDay:     return 60
        case .oneWeek:    return 52
        case .oneMonth:   return 12
        case .threeMonth: return 90
        case .oneYear:    return 365
        case .threeYear:  return 1095
        case .all:        return 999
        }
    }
    var hideCrosshairTime: Bool {
        switch self {
        case .oneWeek, .oneMonth, .threeMonth, .oneYear, .threeYear, .all:
            return true
        default:
            return false
        }
    }
}

// MARK: – ViewModel
class CryptoChartViewModel: ObservableObject {
    @Published var dataPoints   : [ChartDataPoint] = []
    @Published var isLoading    = false
    @Published var errorMessage : String? = nil

    private var lastLiveUpdate: Date = .init(timeIntervalSince1970: 0)

    // Combine throttling for live data
    private var liveSubject = PassthroughSubject<ChartDataPoint, Never>()
    private var cancellables = Set<AnyCancellable>()

    private let session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest  = 10
        cfg.timeoutIntervalForResource = 10
        return URLSession(configuration: cfg)
    }()

    private var liveSocket: URLSessionWebSocketTask? = nil

    init() {
        liveSubject
            .throttle(for: .seconds(1), scheduler: RunLoop.main, latest: true)
            .sink { [weak self] pt in
                guard let self = self else { return }
                self.dataPoints.append(pt)
                if self.dataPoints.count > Int(liveWindow) {
                    self.dataPoints.removeFirst()
                }
                self.isLoading = false
            }
            .store(in: &cancellables)
    }

    func startLive(symbol: String) {
        let stream = (symbol + "USDT").lowercased() + "@trade"
        // Reset state and show loading before starting live socket
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
            self.dataPoints.removeAll()
        }
        liveSocket = URLSession.shared.webSocketTask(with: URL(string: "wss://stream.binance.com:9443/ws/\(stream)")!)
        liveSocket?.resume()
        receiveLive()
    }

    private func receiveLive() {
        liveSocket?.receive { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let err):
                DispatchQueue.main.async {
                    self.errorMessage = err.localizedDescription
                    self.isLoading = false
                }
            case .success(.data(let data)):
                handleLiveData(data)
            case .success(.string(let text)):
                if let data = text.data(using: .utf8) {
                    handleLiveData(data)
                }
            @unknown default:
                break
            }
            self.receiveLive()
        }
    }

    // helper to parse and append a live data point
    private func handleLiveData(_ data: Data) {
        if let msg = try? JSONDecoder().decode(TradeMessage.self, from: data),
           let price = Double(msg.p) {
            let pt = ChartDataPoint(date: Date(timeIntervalSince1970: msg.T / 1000), close: price)
            let current = Date()
            guard current.timeIntervalSince(lastLiveUpdate) >= 1 else { return }
            lastLiveUpdate = current
            // send new point through throttling pipeline instead of direct append
            liveSubject.send(pt)
        }
    }

    func stopLive() {
        liveSocket?.cancel(with: .goingAway, reason: nil)
        liveSocket = nil
    }

    private struct TradeMessage: Decodable {
        let p: String
        let T: TimeInterval
    }

    func fetchData(symbol: String, interval: ChartInterval) {
        if interval == .live {
            self.stopLive()    // tear down any previous stream
            self.startLive(symbol: symbol)
            return
        }
        let pair = symbol.uppercased() + "USDT"
        let urlStr = "https://api.binance.com/api/v3/klines?symbol=\(pair)&interval=\(interval.binanceInterval)&limit=\(interval.binanceLimit)"
        guard let url = URL(string: urlStr) else {
            DispatchQueue.main.async { self.errorMessage = "Invalid URL" }
            return
        }

        DispatchQueue.main.async {
            self.isLoading    = true
            self.errorMessage = nil
        }

        session.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            DispatchQueue.main.async { self.isLoading = false }
            if let err = error {
                return DispatchQueue.main.async { self.errorMessage = err.localizedDescription }
            }
            if let http = response as? HTTPURLResponse, http.statusCode == 451 {
                self.fetchDataFromUS(symbol: symbol, interval: interval)
                return
            }
            guard let data = data else {
                return DispatchQueue.main.async { self.errorMessage = "No data" }
            }
            self.parse(data: data)
        }.resume()
    }

    private func parse(data: Data) {
        do {
            guard let raw = try JSONSerialization.jsonObject(with: data) as? [[Any]] else {
                return DispatchQueue.main.async { self.errorMessage = "Bad JSON" }
            }
            var pts: [ChartDataPoint] = []
            for entry in raw {
                guard entry.count >= 5,
                      let t = entry[0] as? Double
                else { continue }
                let closeRaw = entry[4]
                let date = Date(timeIntervalSince1970: t / 1000)
                let close: Double? = {
                    if let d = closeRaw as? Double { return d }
                    if let s = closeRaw as? String { return Double(s) }
                    return nil
                }()
                let rawVolume = entry[5]
                let volume: Double? = {
                    if let d = rawVolume as? Double { return d }
                    if let s = rawVolume as? String { return Double(s) }
                    return nil
                }()
                if let c = close {
                    pts.append(.init(date: date, close: c, volume: volume ?? 0))
                }
            }
            pts.sort { $0.date < $1.date }
            DispatchQueue.main.async { self.dataPoints = pts }
        } catch {
            DispatchQueue.main.async { self.errorMessage = error.localizedDescription }
        }
    }

    /// If Binance.com returns HTTP 451, try Binance.US
    private func fetchDataFromUS(symbol: String, interval: ChartInterval) {
        let pair = symbol.uppercased() + "USDT"
        let urlStr = "https://api.binance.us/api/v3/klines?symbol=\(pair)&interval=\(interval.binanceInterval)&limit=\(interval.binanceLimit)"
        guard let url = URL(string: urlStr) else {
            DispatchQueue.main.async { self.errorMessage = "Invalid US URL" }
            return
        }
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        session.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async { self.isLoading = false }
            if let err = error {
                return DispatchQueue.main.async { self.errorMessage = err.localizedDescription }
            }
            guard let data = data else {
                return DispatchQueue.main.async { self.errorMessage = "No data from US" }
            }
            self.parse(data: data)
        }.resume()
    }
}

// MARK: – View
struct CryptoChartView: View {
    let symbol  : String
    let interval: ChartInterval
    let height  : CGFloat

    @StateObject private var vm             = CryptoChartViewModel()
    @State private var showCrosshair        = false
    @State private var crosshairDataPoint   : ChartDataPoint? = nil
    @State private var now: Date = Date()
    @State private var shouldAnimate = false

    var body: some View {
        ZStack {
            // Loading overlay
            if vm.isLoading && vm.dataPoints.isEmpty && interval == .live {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
            }

            // Error or chart content
            if let err = vm.errorMessage {
                errorView(err)
            } else {
                chartContent
                    .padding(.leading, 16)
                    .padding(.trailing, 24)
                    .padding(.top, 24)
                    .frame(height: height)
            }
        }
        .onAppear {
            vm.errorMessage = nil
            if interval == .live {
                vm.startLive(symbol: symbol)
            } else {
                vm.fetchData(symbol: symbol, interval: interval)
            }
            shouldAnimate = false
        }
        .onChange(of: symbol) { newSymbol in
            vm.errorMessage = nil
            vm.stopLive()
            if interval == .live {
                vm.startLive(symbol: newSymbol)
            } else {
                vm.fetchData(symbol: newSymbol, interval: interval)
            }
        }
        .onChange(of: interval) { newInterval in
            vm.errorMessage = nil
            vm.stopLive()
            if newInterval == .live {
                // Load an initial minute's worth of historical data before streaming
                vm.fetchData(symbol: symbol, interval: .oneMin)
                vm.startLive(symbol: symbol)
            } else {
                vm.fetchData(symbol: symbol, interval: newInterval)
            }
            shouldAnimate = true
        }
        .onDisappear {
            vm.stopLive()
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { date in
            self.now = date
        }
    }

    private var chartContent: some View {
        VStack(spacing: 4) {
            // Price chart...
            Chart {
                ForEach(vm.dataPoints) { pt in
                    LineMark(x: .value("Time", pt.date),
                             y: .value("Price", pt.close))
                        .interpolationMethod(.cardinal)
                        .foregroundStyle(.yellow)

                    // only draw gradient fill on historical intervals
                    if interval != .live {
                        AreaMark(x: .value("Time", pt.date),
                                 yStart: .value("Price", yDomain.lowerBound),
                                 yEnd: .value("Price", pt.close))
                            .foregroundStyle(
                                LinearGradient(gradient: Gradient(colors: [
                                    .yellow.opacity(0.3),
                                    .yellow.opacity(0.15),
                                    .yellow.opacity(0.05),
                                    .clear
                                ]), startPoint: .top, endPoint: .bottom)
                            )
                    }
                }

                if showCrosshair, let cp = crosshairDataPoint {
                    // Vertical crosshair line
                    RuleMark(x: .value("Time", cp.date))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                        .foregroundStyle(.white.opacity(0.7))
                    // Horizontal crosshair line
                    RuleMark(y: .value("Price", cp.close))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                        .foregroundStyle(.white.opacity(0.7))
                    PointMark(x: .value("Time", cp.date),
                              y: .value("Price", cp.close))
                        .symbolSize(80)
                        .foregroundStyle(.white)
                        .annotation(position: .top) {
                            VStack(spacing: 4) {
                                crosshairDate(cp.date)
                                Text(formatPrice(cp.close))
                                    .font(.caption2)
                                    .foregroundColor(.white)
                            }
                            .padding(6)
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(6)
                        }
                }
            }
            .transaction { transaction in
                transaction.animation = shouldAnimate ? .easeInOut(duration: 0.3) : nil
            }
            .chartYScale(domain: yDomain)
            .chartXScale(domain: xDomain)
            .chartXScale(range: 0.05...0.95)
            .chartPlotStyle { plotArea in
                plotArea
                    .background(Color.black.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .chartXAxis {
                if !xAxisTickValues.isEmpty {
                    // Major ticks: only start, mid, end with labels
                    AxisMarks(values: xAxisTickValues) { value in
                        AxisGridLine().foregroundStyle(.white.opacity(0.2))
                        AxisValueLabel() {
                            if let dateValue = value.as(Date.self) {
                                if interval == .live && abs(dateValue.timeIntervalSince(now)) < 1 {
                                    Text("Now")
                                        .font(.footnote)
                                        .foregroundStyle(.white)
                                } else {
                                    Text(formatAxisDate(dateValue))
                                        .font(.footnote)
                                        .foregroundStyle(.white)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.5)
                                }
                            }
                        }
                    }
                    // Minor ticks: automatic gridlines only, no labels
                    AxisMarks(values: .automatic(desiredCount: dynamicXAxisCount)) { _ in
                        AxisGridLine().foregroundStyle(.white.opacity(0.1))
                    }
                } else {
                    // Default ticks for other intervals: gridlines + labels
                    AxisMarks(values: .automatic(desiredCount: dynamicXAxisCount)) { value in
                        AxisGridLine().foregroundStyle(.white.opacity(0.2))
                        AxisValueLabel() {
                            if let dateValue = value.as(Date.self) {
                                if interval == .live && abs(dateValue.timeIntervalSince(now)) < 1 {
                                    Text("Now")
                                        .font(.footnote)
                                        .foregroundStyle(.white)
                                } else {
                                    Text(formatAxisDate(dateValue))
                                        .font(.footnote)
                                        .foregroundStyle(.white)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.5)
                                }
                            }
                        }
                    }
                }
            }
            .chartYAxis {
                // Baseline at minimum price
                AxisMarks(position: .trailing, values: [yDomain.lowerBound]) { _ in
                    AxisGridLine()
                        .foregroundStyle(Color.white.opacity(0.3))
                    AxisTick()
                        .foregroundStyle(Color.white.opacity(0.3))
                }

                // Major gridlines with ticks and labels
                AxisMarks(position: .trailing, values: .automatic(desiredCount: 4)) { value in
                    AxisGridLine()
                        .foregroundStyle(Color.white.opacity(0.2))
                    AxisTick()
                        .foregroundStyle(Color.white.opacity(0.4))
                    AxisValueLabel()
                        .font(.caption2)
                        .foregroundStyle(Color.white.opacity(0.7))
                }

                // Minor gridlines only
                AxisMarks(position: .trailing, values: .automatic(desiredCount: 8)) { _ in
                    AxisGridLine()
                        .foregroundStyle(Color.white.opacity(0.1))
                }
            }
            // only enable crosshair dragging on non-live intervals
            .if(interval != .live) { view in
                view.chartOverlay { proxy in
                    GeometryReader { geo in
                        Rectangle().fill(Color.clear).contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { gesture in
                                        showCrosshair = true
                                        let xPos = gesture.location.x - geo[proxy.plotAreaFrame].origin.x
                                        if let date: Date = proxy.value(atX: xPos),
                                           let nearest = findClosest(to: date) {
                                            crosshairDataPoint = nearest
                                        }
                                    }
                                    .onEnded { _ in showCrosshair = false }
                            )
                    }
                }
            }
            // subtle fade at bottom edge
            .overlay(
                LinearGradient(
                    colors: [.clear, Color.black.opacity(0.5)],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 40)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .allowsHitTesting(false)
            )

            // Volume histogram below price
            Chart {
                ForEach(vm.dataPoints) { pt in
                    BarMark(
                        x: .value("Time", pt.date),
                        y: .value("Volume", pt.volume)
                    )
                    .foregroundStyle(Color.yellow.opacity(0.25))
                }
                RuleMark(y: .value("Zero", 0))
                    .foregroundStyle(Color.white.opacity(0.2))
                    .lineStyle(StrokeStyle(lineWidth: 1))
                if showCrosshair, let cp = crosshairDataPoint {
                    // Vertical crosshair line for volume chart
                    RuleMark(x: .value("Time", cp.date))
                        .foregroundStyle(.white.opacity(0.7))
                    // Marker at the volume point
                    PointMark(
                        x: .value("Time", cp.date),
                        y: .value("Volume", cp.volume)
                    )
                    .symbolSize(40)
                    .foregroundStyle(.white)
                    .annotation(position: .bottom) {
                        Text("\(Int(cp.volume))")
                            .font(.caption2)
                            .foregroundStyle(.white)
                    }
                }
            }
            .chartXScale(domain: xDomain)
            .chartXScale(range: 0.05...0.95)
            .chartPlotStyle { plotArea in
                plotArea.background(Color.black.opacity(0.1))
            }
            .chartYScale(domain: 0...maxVolume)
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .padding(.horizontal, 16)
            .frame(height: 30)
        }
    }

    // MARK: – Helpers

    private var maxVolume: Double {
        vm.dataPoints.map(\.volume).max() ?? 1
    }
    private func errorView(_ msg: String) -> some View {
        VStack(spacing: 8) {
            Text("Error loading chart").foregroundColor(.red)
            Text(msg).font(.caption).foregroundColor(.gray).multilineTextAlignment(.center)
            Button("Retry") { vm.fetchData(symbol: symbol, interval: interval) }
                .padding(6).background(Color.yellow).cornerRadius(8).foregroundColor(.black)
        }
        .padding()
    }

    private func crosshairDate(_ d: Date) -> Text {
        if interval.hideCrosshairTime {
            return Text(d, format: .dateTime.month().year())
        }
        switch interval {
        case .oneMin, .fiveMin:
            return Text(d, format: .dateTime.hour().minute())
        case .fifteenMin, .thirtyMin, .oneHour, .fourHour:
            return Text(d, format: .dateTime.hour())
        case .oneDay, .oneWeek:
            return Text(d, format: .dateTime.month().day())
        default:
            return Text(d, format: .dateTime.month().year())
        }
    }

    private var yDomain: ClosedRange<Double> {
        let prices = vm.dataPoints.map(\.close)
        guard let lo = prices.min(), let hi = prices.max() else { return 0...1 }
        let pad = (hi - lo) * 0.05
        return (lo - pad)...(hi + pad)
    }

    private var xDomain: ClosedRange<Date> {
        if interval == .live {
            let now = self.now
            return now.addingTimeInterval(-liveWindow)...now
        }
        guard let first = vm.dataPoints.first?.date,
              let last  = vm.dataPoints.last?.date else {
            let now = Date()
            return now.addingTimeInterval(-86_400)...now
        }
        return first...last
    }

    private var xAxisCount: Int {
        switch interval {
        case .live, .oneMin:
            return 6
        case .fiveMin:
            return 4
        case .fifteenMin, .thirtyMin, .oneHour:
            return 6
        case .fourHour:
            return 5
        case .oneDay:
            return 6
        default:
            return 3
        }
    }

    /// Compute tick count dynamically based on view width
    private var dynamicXAxisCount: Int {
        // account for 16pt padding each side
        let totalWidth = UIScreen.main.bounds.width - 32
        let approxTickSpacing: CGFloat = 80
        let count = Int(totalWidth / approxTickSpacing)
        return max(2, min(8, count))
    }

    /// Explicit tick dates for key intervals (start, mid, end)
    private var xAxisTickValues: [Date] {
        let start = xDomain.lowerBound
        let end   = xDomain.upperBound
        switch interval {
        case .oneHour, .fourHour, .oneDay:
            let mid = start.addingTimeInterval(end.timeIntervalSince(start) / 2)
            return [start, mid, end]
        default:
            return []
        }
    }

    /// 20-period simple moving average of closing prices
    private var movingAveragePoints: [ChartDataPoint] {
        let windowSize = 20
        let pts = vm.dataPoints
        guard pts.count >= windowSize else { return [] }
        return pts.enumerated().compactMap { idx, pt in
            let start = max(0, idx - windowSize + 1)
            let slice = pts[start...idx]
            let avg = slice.map(\.close).reduce(0, +) / Double(slice.count)
            return ChartDataPoint(date: pt.date, close: avg)
        }
    }

    private func formatAxisDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale   = Locale(identifier: "en_US_POSIX")
        df.timeZone = .current

        switch interval {
        case .live, .oneMin, .fiveMin, .fifteenMin, .thirtyMin:
            // Drop minute markers – always show like "9 PM"
            df.dateFormat = "h a"
        case .oneHour, .fourHour:
            df.dateFormat = "h a"
        case .oneDay, .oneWeek, .oneMonth, .threeMonth:
            df.dateFormat = "MMM d"
        case .oneYear, .threeYear:
            df.dateFormat = "MMM yyyy"
        case .all:
            df.dateFormat = "yyyy"
        }

        return df.string(from: date)
    }

    private func findClosest(to date: Date) -> ChartDataPoint? {
        vm.dataPoints.min(by: {
            abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
        })
    }

    private func formatPrice(_ v: Double) -> String {
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal
        if v < 1 {
            fmt.minimumFractionDigits = 2
            fmt.maximumFractionDigits = 8
        } else {
            fmt.minimumFractionDigits = 2
            fmt.maximumFractionDigits = 2
        }
        return "$" + (fmt.string(from: v as NSNumber) ?? "\(v)")
    }
}

// MARK: – View Extension for Conditional Modifier
extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
