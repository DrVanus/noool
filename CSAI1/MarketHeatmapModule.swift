import SwiftUI
import Combine

// MARK: - Tile Model
public struct HeatMapTile: Identifiable, Equatable, Decodable {
    public let id: String
    public let symbol: String
    public let pctChange24h: Double
    public let marketCap: Double
    public let volume: Double

    private enum CodingKeys: String, CodingKey {
        case symbol
        case pctChange24h = "price_change_percentage_24h"
        case marketCap    = "market_cap"
        case volume       = "total_volume"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        symbol = try c.decode(String.self, forKey: .symbol)
        id = symbol
        pctChange24h = (try? c.decode(Double.self, forKey: .pctChange24h)) ?? 0
        marketCap    = (try? c.decode(Double.self, forKey: .marketCap))    ?? 0
        volume       = (try? c.decode(Double.self, forKey: .volume))       ?? 0
    }

    public init(id: String, symbol: String, pctChange24h: Double, marketCap: Double, volume: Double) {
        self.id = id
        self.symbol = symbol
        self.pctChange24h = pctChange24h
        self.marketCap = marketCap
        self.volume = volume
    }
}

// MARK: - ViewModel
public final class HeatMapViewModel: ObservableObject {
    /// Fallback sample data if network fails or times out
    private static let sampleTiles: [HeatMapTile] = [
        HeatMapTile(id: "BTC", symbol: "BTC", pctChange24h: 2.3, marketCap: 800_000_000_000, volume: 25_000_000_000),
        HeatMapTile(id: "ETH", symbol: "ETH", pctChange24h: -1.1, marketCap: 350_000_000_000, volume: 18_000_000_000),
        HeatMapTile(id: "SOL", symbol: "SOL", pctChange24h: 3.8, marketCap: 60_000_000_000, volume: 3_000_000_000),
        HeatMapTile(id: "ADA", symbol: "ADA", pctChange24h: 1.5, marketCap: 40_000_000_000, volume: 5_000_000_000),
        HeatMapTile(id: "DOT", symbol: "DOT", pctChange24h: -0.8, marketCap: 30_000_000_000, volume: 2_000_000_000),
        HeatMapTile(id: "DOGE", symbol: "DOGE", pctChange24h: 10.2, marketCap: 20_000_000_000, volume: 8_000_000_000)
    ]
    @Published public var tiles: [HeatMapTile] = []
    @Published public var isLoading: Bool = false
    @Published public var fetchError: Error? = nil
    private var cancellables = Set<AnyCancellable>()

    public init() {
        // show sample immediately while real data loads
        self.tiles = Self.sampleTiles
        fetchData()
        Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.fetchData() }
            .store(in: &cancellables)
    }

    public func fetchData() {
        guard let url = URL(string:
            "https://api.coingecko.com/api/v3/coins/markets?" +
            "vs_currency=usd&order=market_cap_desc&per_page=20" +
            "&page=1&sparkline=false&price_change_percentage=24h"
        ) else { return }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10  // fail fast

        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: [HeatMapTile].self, decoder: JSONDecoder())
            .catch { error in
                // on any error, fall back to sample
                Just(Self.sampleTiles)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newTiles in
                self?.tiles = newTiles
            }
            .store(in: &cancellables)
    }

    /// Exponentially weight marketCap for layout
    public func weights() -> [Double] {
        tiles.map { pow($0.marketCap, 0.7) }
    }
}

// MARK: - Treemap Layout
private func squarify(
    items: [HeatMapTile],
    weights: [Double],
    rect: CGRect
) -> [CGRect] {
    var rects: [CGRect] = []
    func layout(_ entries: [(HeatMapTile, Double)], in r: CGRect) {
        guard !entries.isEmpty else { return }
        let horizontal = r.width < r.height
        var row: [(HeatMapTile, Double)] = []
        var remaining = entries

        func worstRatio(_ row: [(HeatMapTile, Double)], in r: CGRect) -> CGFloat {
            let total = row.reduce(0) { $0 + $1.1 }
            let side = horizontal ? r.width : r.height
            return row.map { _, w in
                let frac = CGFloat(w / total)
                let length = (horizontal ? r.height : r.width) * frac
                return max(side / length, length / side)
            }.max() ?? .infinity
        }

        while let next = remaining.first {
            let newRow = row + [next]
            if row.isEmpty || worstRatio(newRow, in: r) <= worstRatio(row, in: r) {
                row = newRow
                remaining.removeFirst()
            } else { break }
        }

        let totalW = row.reduce(0) { $0 + $1.1 }
        var offset: CGFloat = 0
        for (tile, w) in row {
            let frac = totalW > 0 ? w / totalW : 0
            let slice: CGRect
            if horizontal {
                let h = r.height * CGFloat(frac)
                slice = CGRect(x: r.minX, y: r.minY + offset, width: r.width, height: h)
                offset += h
            } else {
                let w = r.width * CGFloat(frac)
                slice = CGRect(x: r.minX + offset, y: r.minY, width: w, height: r.height)
                offset += w
            }
            rects.append(slice)
        }

        let usedFrac = row.reduce(0) { $0 + $1.1 } / entries.reduce(0) { $0 + $1.1 }
        let leftover: CGRect
        if horizontal {
            let usedH = r.height * CGFloat(usedFrac)
            leftover = CGRect(x: r.minX, y: r.minY + usedH, width: r.width, height: r.height - usedH)
        } else {
            let usedW = r.width * CGFloat(usedFrac)
            leftover = CGRect(x: r.minX + usedW, y: r.minY, width: r.width - usedW, height: r.height)
        }

        layout(remaining, in: leftover)
    }
    layout(Array(zip(items, weights)), in: rect)
    return rects
}

// MARK: - TreemapView
public struct TreemapView: View {
    public var tiles: [HeatMapTile]
    public var weights: [Double]
    public var onTileTap: ((HeatMapTile) -> Void)? = nil

    private let topCount = 8
    private let labelThreshold: CGFloat = 100
    private let spacing: CGFloat = 3
    private let colorBound: Double = 20

    private var displayTiles: [HeatMapTile] {
        var sorted = tiles.sorted { $0.marketCap > $1.marketCap }
        let top = Array(sorted.prefix(topCount))
        let rest = sorted.dropFirst(topCount)
        var list = top
        if !rest.isEmpty {
            let capSum = rest.reduce(0) { $0 + $1.marketCap }
            let avg = rest.reduce(0) { $0 + $1.pctChange24h * $1.marketCap } / max(capSum, 1)
            list.append(
                HeatMapTile(
                    id: "Others",
                    symbol: "Others",
                    pctChange24h: avg,
                    marketCap: capSum,
                    volume: rest.reduce(0) { $0 + $1.volume }
                )
            )
        }
        return list
    }

    public var body: some View {
        GeometryReader { geo in
            let rects = squarify(
                items: displayTiles,
                weights: weightsFor(displayTiles),
                rect: CGRect(origin: .zero, size: geo.size)
            )
            ZStack {
                ForEach(Array(zip(displayTiles, rects)), id: \.0.id) { tile, slice in
                    let r = slice.insetBy(dx: spacing/2, dy: spacing/2)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(color(for: tile.pctChange24h, bound: colorBound))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.1), lineWidth: 1))
                        .frame(width: r.width, height: r.height)
                        .position(x: r.midX, y: r.midY)
                        .onTapGesture { onTileTap?(tile) }
                        .overlay(
                            VStack(alignment: .leading, spacing: 2) {
                                Text(tile.symbol)
                                    .font(.system(size: min(r.width, r.height) * 0.12, weight: .semibold))
                                Text(String(format: "%+.1f%%", tile.pctChange24h))
                                    .font(.caption2)
                            }
                            .foregroundColor(.white)
                            .padding(6)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(4)
                            .opacity((r.width * r.height) > (labelThreshold * labelThreshold) ? 1 : 0),
                            alignment: .topLeading
                        )
                }
            }
            .animation(.easeInOut(duration: 0.3), value: tiles)
        }
    }

    private func weightsFor(_ list: [HeatMapTile]) -> [Double] {
        list.map { tile in
            if let idx = tiles.firstIndex(of: tile) {
                return weights[idx]
            }
            return pow(tile.marketCap, 0.7)
        }
    }
}

// MARK: - WeightedHeatMapView
/// A horizontal “heat bar” where each tile’s width is proportional to its weight.
public struct WeightedHeatMapView: View {
    public let tiles: [HeatMapTile]
    public let weights: [Double]
    public let spacing: CGFloat
    
    public init(tiles: [HeatMapTile], weights: [Double], spacing: CGFloat = 2) {
        self.tiles = tiles
        self.weights = weights
        self.spacing = spacing
    }
    
    public var body: some View {
        GeometryReader { geo in
            let total = weights.reduce(0, +)
            HStack(spacing: spacing) {
                ForEach(Array(zip(tiles, weights)), id: \.0.id) { tile, w in
                    let frac = total > 0 ? w / total : 0
                    ZStack(alignment: .bottomLeading) {
                        Rectangle()
                            .fill(color(for: tile.pctChange24h, bound: 20))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(tile.symbol)
                                .font(.caption)
                                .bold()
                            Text(String(format: "%+.1f%%", tile.pctChange24h))
                                .font(.caption2)
                        }
                        .foregroundColor(.white)
                        .padding(6)
                    }
                    .frame(width: geo.size.width * CGFloat(frac), height: geo.size.height)
                    .cornerRadius(6)
                }
            }
        }
    }
}

// MARK: - GridHeatMapView
/// A professional grid heat map with equal-sized tiles, adaptive layout, and pop-over details.
public struct GridHeatMapView: View {
    public let tiles: [HeatMapTile]
    private let colorBound: Double = 20
    @State private var selectedTile: HeatMapTile? = nil

    private var gridItems: [GridItem] {
        [GridItem(.adaptive(minimum: 80), spacing: 8)]
    }

    public init(tiles: [HeatMapTile]) {
        self.tiles = tiles
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            LazyVGrid(columns: gridItems, spacing: 8) {
                ForEach(tiles) { tile in
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(color(for: tile.pctChange24h, bound: colorBound))
                        VStack(spacing: 4) {
                            Text(tile.symbol)
                                .font(.subheadline).bold()
                            Text(String(format: "%+.1f%%", tile.pctChange24h))
                                .font(.caption2)
                        }
                        .foregroundColor(.white)
                        .padding(6)
                    }
                    .aspectRatio(1, contentMode: .fit)
                    .onTapGesture {
                        selectedTile = tile
                    }
                }
            }
            .padding(.horizontal, 16)
            .popover(item: $selectedTile) { tile in
                VStack(spacing: 12) {
                    Text(tile.symbol)
                        .font(.title).bold()
                    Text(String(format: "24h Change: %+.2f%%", tile.pctChange24h))
                    Text("Market Cap: \(Int(tile.marketCap).formattedWithSeparator())")
                    Text("Volume: \(Int(tile.volume).formattedWithSeparator())")
                }
                .padding()
            }
        }
    }
}

// MARK: - NumberFormatter Extension
private extension Int {
    func formattedWithSeparator() -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

// MARK: - Color Helper
private func color(for pct: Double, bound: Double) -> Color {
    let redRGB   = (r: 0.839, g: 0.306, b: 0.306)
    let amberRGB = (r: 1.0,   g: 0.827, b: 0.0)
    let greenRGB = (r: 0.307, g: 0.788, b: 0.416)

    let capped = min(max(pct, -bound), bound)
    let t = (capped + bound) / (2 * bound)

    func lerp(_ a: Double, _ b: Double, _ f: Double) -> Double {
        a + (b - a) * f
    }

    if t < 0.5 {
        let f = t / 0.5
        return Color(
            red: lerp(redRGB.r, amberRGB.r, f),
            green: lerp(redRGB.g, amberRGB.g, f),
            blue: lerp(redRGB.b, amberRGB.b, f)
        )
    } else {
        let f = (t - 0.5) / 0.5
        return Color(
            red: lerp(amberRGB.r, greenRGB.r, f),
            green: lerp(amberRGB.g, greenRGB.g, f),
            blue: lerp(amberRGB.b, greenRGB.b, f)
        )
    }
}

// MARK: - LegendView
public struct LegendView: View {
    public let bound: Double

    public var gradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: color(for: -bound, bound: bound), location: 0.0),
                .init(color: color(for: 0.0, bound: bound), location: 0.5),
                .init(color: color(for: bound, bound: bound), location: 1.0)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(String(format: "-%.0f%%", bound)).font(.caption)
                Rectangle().fill(gradient).frame(height: 6).cornerRadius(3)
                Text(String(format: "+%.0f%%", bound)).font(.caption)
            }
            HStack {
                Text("Fear").font(.caption2).frame(maxWidth: .infinity)
                Text("Neutral").font(.caption2).frame(maxWidth: .infinity)
                Text("Greed").font(.caption2).frame(maxWidth: .infinity)
            }
            .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Market Heat Map Section
public struct MarketHeatMapSection: View {
    @StateObject private var viewModel = HeatMapViewModel()
    private let mapHeight: CGFloat = 180

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "square.grid.2x2")
                    .foregroundColor(.yellow)
                Text("Market Heat Map")
                    .font(.headline)
            }
            .padding(.horizontal, 16)

            Group {
                if viewModel.tiles.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: mapHeight)
                } else {
                    TreemapView(
                        tiles: viewModel.tiles,
                        weights: viewModel.weights(),
                        onTileTap: { tile in
                            // handle tile tap if desired
                        }
                    )
                    .frame(height: mapHeight)

                    LegendView(bound: 20)
                }
            }
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
}
