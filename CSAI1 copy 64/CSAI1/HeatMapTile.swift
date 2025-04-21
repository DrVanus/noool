//
//  HeatMapTile.swift
//  CSAI1
//
//  Created by DM on 4/19/25.
//

import SwiftUI
import Combine
import Charts

// MARK: - Heat Map Timeframe
enum HeatMapTimeframe: String, CaseIterable, Identifiable {
    case oneHour  = "1h"
    case oneDay   = "24h"
    case oneWeek  = "7d"
    case oneMonth = "30d"
    var id: String { rawValue }
}

// MARK: - Tile Model
struct HeatMapTile: Identifiable, Equatable {
    let id = UUID()
    let symbol: String
    let pctChange: Double
    let marketCapRank: Int
    let sparkline: [Double]
}

// MARK: - ViewModel
class HeatMapVM: ObservableObject {
    var timeframe: HeatMapTimeframe
    let showWatchlistOnly: Bool
    @Published var tiles: [HeatMapTile] = []
    private var cancellables = Set<AnyCancellable>()

    private struct CoinGeckoRaw: Decodable {
        let symbol: String
        let price_change_percentage_24h: Double?
        let price_change_percentage_1h_in_currency: Double?
        let price_change_percentage_7d_in_currency: Double?
        let price_change_percentage_30d_in_currency: Double?
        let sparkline_in_7d: SparklineData?
    }
    
    private struct SparklineData: Decodable {
        let price: [Double]
    }

    init(timeframe: HeatMapTimeframe, showWatchlistOnly: Bool) {
        self.timeframe = timeframe
        self.showWatchlistOnly = showWatchlistOnly
        // Temporary dummy data
        self.tiles = (0..<20).map { idx in
            HeatMapTile(
                symbol: ["BTC","ETH","SOL","BNB","XRP","ADA","DOT","DOGE","LTC","LINK",
                         "MATIC","ATOM","AVAX","UNI","SHIB","ALGO","FIL","ICP","TRX","AXS"][idx],
                pctChange: Double.random(in: -10...10),
                marketCapRank: idx + 1,
                sparkline: []
            )
        }
        fetchHeatMapData()
    }

    func fetchHeatMapData() {
        let timeframeParams = HeatMapTimeframe.allCases.map { $0.rawValue }.joined(separator: ",")
        guard let url = URL(string:
            "https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=50&page=1&sparkline=true&price_change_percentage=\(timeframeParams)"
        ) else { return }

        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: [CoinGeckoRaw].self, decoder: JSONDecoder())
            .map { raws in
                raws.enumerated().compactMap { idx, raw in
                    let pct: Double?
                    switch self.timeframe {
                    case .oneHour: pct = raw.price_change_percentage_1h_in_currency
                    case .oneDay:  pct = raw.price_change_percentage_24h
                    case .oneWeek: pct = raw.price_change_percentage_7d_in_currency
                    case .oneMonth:pct = raw.price_change_percentage_30d_in_currency
                    }
                    guard let pct = pct else { return nil }
                    return HeatMapTile(
                        symbol: raw.symbol.uppercased(),
                        pctChange: pct,
                        marketCapRank: idx + 1,
                        sparkline: raw.sparkline_in_7d?.price ?? []
                    )
                }
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in },
                  receiveValue: { [weak self] tiles in
                      self?.tiles = tiles
                  })
            .store(in: &cancellables)
    }
    
    func fetchHeatMapData(for timeframe: HeatMapTimeframe) {
        // update the underlying timeframe, then re-fetch
        self.timeframe = timeframe
        fetchHeatMapData()
    }
}

// MARK: - HeatMapCard View
struct HeatMapCard: View {
    @StateObject private var vm: HeatMapVM
    @State private var selectedTile: HeatMapTile?
    @State private var selectedTimeframe: HeatMapTimeframe = .oneDay
    @State private var showWatchlistOnly: Bool = false
    private let showControls: Bool

    init(timeframe: HeatMapTimeframe = .oneDay, showWatchlistOnly: Bool = false, showControls: Bool = true) {
        _vm = StateObject(wrappedValue: HeatMapVM(timeframe: timeframe, showWatchlistOnly: showWatchlistOnly))
        self.showWatchlistOnly = showWatchlistOnly
        self.showControls = showControls
        _selectedTimeframe = State(initialValue: timeframe)
    }

    // Fixed 5‑column flexible layout to evenly fill width
    private let columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Controls: timeframe picker + watchlist toggle
            if showControls {
                HStack(spacing: 12) {
                    // Timeframe segmented picker
                    Picker("", selection: $selectedTimeframe) {
                        ForEach(HeatMapTimeframe.allCases) { tf in
                            Text(tf.rawValue.uppercased())
                                .tag(tf)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(maxWidth: .infinity)
                    .onChange(of: selectedTimeframe) { newTf in
                        vm.fetchHeatMapData(for: newTf)
                    }

                    Toggle(isOn: $showWatchlistOnly) {
                        Text("Watchlist")
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .yellow))
                    .onChange(of: showWatchlistOnly) { _ in
                        // grid will automatically filter
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
            }
            
            // Horizontal scrollable grid
            ScrollView(.horizontal, showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(vm.tiles.filter { !showWatchlistOnly || ["BTC","ETH","SOL"].contains($0.symbol) }) { tile in
                        HeatMapTileView(tile: tile, selectedTile: $selectedTile)
                            .onTapGesture { selectedTile = tile }
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
            }

            // Legend below
            LegendView()
        }
        .padding(8)
        .animation(.easeInOut, value: vm.tiles)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
        )
        .frame(maxWidth: .infinity)
        .sheet(item: $selectedTile) { tile in
            HeatMapDetailView(tile: tile)
        }
    }
}

struct LegendView: View {
    private let steps: [(label: String, color: Color)] = [
        ("<-10%", Color(hue: 0.66, saturation: 0.8, brightness: 0.9)),
        ("-5%", Color(hue: 0.5, saturation: 0.8, brightness: 0.9)),
        ("0%", Color(hue: 0.33, saturation: 0.8, brightness: 0.9)),
        ("+5%", Color(hue: 0.16, saturation: 0.8, brightness: 0.9)),
        (">+10%", Color(hue: 0.0, saturation: 0.8, brightness: 0.9))
    ]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(steps, id: \.label) { step in
                VStack(spacing: 2) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(step.color)
                        .frame(width: 30, height: 8)
                    Text(step.label)
                        .font(.caption2)
                        .foregroundColor(.white)
                }
            }
        }
    }
}

struct HeatMapTileView: View {
    let tile: HeatMapTile
    @Binding var selectedTile: HeatMapTile?

    var body: some View {
        VStack(spacing: 4) {
            if !tile.sparkline.isEmpty {
                Chart {
                    ForEach(Array(tile.sparkline.enumerated()), id: \.0) { idx, value in
                        LineMark(x: .value("Index", idx), y: .value("Price", value))
                            .foregroundStyle(tile.pctChange >= 0 ? Color.green : Color.red)
                            .lineStyle(StrokeStyle(lineWidth: 1.5))
                    }
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .frame(height: 28)
            }
            Text(tile.symbol)
                .font(.caption2).bold()
                .foregroundColor(.white)

            Text(String(format: "%+.1f%%", tile.pctChange))
                .font(.caption2)
                .foregroundColor(.white)
        }
        .padding(4)
        .frame(minWidth: 54)
        .aspectRatio(1, contentMode: .fit)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(color(for: tile.pctChange))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(
                    tile.pctChange >= 0 ? Color.green : Color.red,
                    lineWidth: abs(tile.pctChange) > 5 ? 3 : 1
                )
        )
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: tile.pctChange)
        .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 2)
        .scaleEffect(tile.id == selectedTile?.id ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedTile)
        .contextMenu {
            Button("View Details") { selectedTile = tile }
            Button("Copy Symbol") { UIPasteboard.general.string = tile.symbol }
        }
    }

    private func color(for pct: Double) -> Color {
        let capped = min(max(pct, -10), 10) / 20 + 0.5
        return Color(hue: 0.33 - capped * 0.33, saturation: 0.8, brightness: 0.9)
    }
}

struct HeatMapDetailView: View {
    let tile: HeatMapTile
    var body: some View {
        VStack(spacing: 16) {
            Text(tile.symbol)
                .font(.largeTitle).bold()
            Chart {
                ForEach(Array(tile.sparkline.enumerated()), id: \.0) { idx, value in
                    LineMark(x: .value("Index", idx), y: .value("Price", value))
                }
            }
            .chartYAxis(.hidden)
            .chartXAxis(.hidden)
            Text(String(format: "%+.2f%%", tile.pctChange))
                .font(.title2)
                .foregroundColor(tile.pctChange >= 0 ? .green : .red)
            Spacer()
        }
        .padding()
    }
}

struct HeatMapCard_Previews: PreviewProvider {
    static var previews: some View {
        HeatMapCard(showWatchlistOnly: false)
            .preferredColorScheme(.dark)
            .padding()
            .background(Color.black)
    }
}
