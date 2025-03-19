//
//  MarketView.swift
//  CRYPTOSAI
//
//  Large Market screen (~400+ lines) preserving your existing:
//    - Sorting, favorites, search, segments
//    - Optional mini sparkline in the row (iOS 16+)
//  Tapping a coin row navigates to CoinDetailView(coin: coin).
//

import SwiftUI
import Charts  // If you want mini-sparklines on iOS 16+

// Example model. Adjust if your "MarketCoin" differs:
struct MarketCoin: Identifiable {
    let id = UUID()
    let symbol: String
    let name: String
    let price: Double
    let dailyChange: Double
    let volume: Double
    var isFavorite: Bool = false
    
    // For a mini sparkline. Provide e.g. [Double] of 7-day prices
    let sparklineData: [Double]
}

// Segment filter
enum MarketSegment: String, CaseIterable {
    case all = "All"
    case favorites = "Favorites"
    case gainers = "Gainers"
    case losers  = "Losers"
}

// Sorting
enum SortField: String {
    case coin, price, dailyChange, volume, none
}
enum SortDirection {
    case asc, desc
}

// MARK: - ViewModel
class MarketViewModel: ObservableObject {
    @Published var coins: [MarketCoin] = []
    @Published var filteredCoins: [MarketCoin] = []
    
    // Segment & search
    @Published var selectedSegment: MarketSegment = .all
    @Published var showSearchBar: Bool = false
    @Published var searchText: String = ""
    
    // Sorting
    @Published var sortField: SortField = .none
    @Published var sortDirection: SortDirection = .asc
    
    // Favorites persistence
    private let favoritesKey = "favoriteCoinSymbols"
    
    init() {
        // If you want sample data first, uncomment:
        // loadSampleCoins()
        loadFavorites()
        
        // Call the new real-data function so we see live CoinGecko data
        fetchRealCoinsFromCoinGecko()
        
        // applyAllFiltersAndSort() is called after we fetch
        // but if you keep loadSampleCoins(), you can also call it here
        // applyAllFiltersAndSort()
    }
    
    private func loadSampleCoins() {
        // Example data (with sparkline placeholders)
        coins = [
            MarketCoin(
                symbol: "BTC",
                name: "Bitcoin",
                price: 27950.00,
                dailyChange: 1.24,
                volume: 450_000_000,
                isFavorite: false,
                sparklineData: [27900, 27920, 27880, 28000, 27910, 27950, 27970]
            ),
            MarketCoin(
                symbol: "ETH",
                name: "Ethereum",
                price: 1800.25,
                dailyChange: -0.56,
                volume: 210_000_000,
                isFavorite: false,
                sparklineData: [1810, 1805, 1800, 1798, 1802, 1795, 1800]
            ),
            MarketCoin(
                symbol: "SOL",
                name: "Solana",
                price: 22.00,
                dailyChange: 3.44,
                volume: 50_000_000,
                isFavorite: false,
                sparklineData: [21.2, 21.5, 21.9, 22.2, 22.0, 21.8, 22.0]
            ),
            MarketCoin(
                symbol: "XRP",
                name: "XRP",
                price: 0.464,
                dailyChange: -3.16,
                volume: 120_000_000,
                isFavorite: false,
                sparklineData: [0.470, 0.468, 0.465, 0.463, 0.460, 0.464, 0.462]
            ),
            MarketCoin(
                symbol: "DOGE",
                name: "Dogecoin",
                price: 0.080,
                dailyChange: 2.15,
                volume: 90_000_000,
                isFavorite: false,
                sparklineData: [0.078, 0.079, 0.080, 0.082, 0.081, 0.080, 0.080]
            ),
            MarketCoin(
                symbol: "ADA",
                name: "Cardano",
                price: 0.390,
                dailyChange: 1.05,
                volume: 75_000_000,
                isFavorite: false,
                sparklineData: [0.388, 0.389, 0.387, 0.390, 0.392, 0.391, 0.390]
            )
        ]
    }
    
    // Favorites
    private func loadFavorites() {
        let saved = UserDefaults.standard.stringArray(forKey: favoritesKey) ?? []
        for i in coins.indices {
            if saved.contains(coins[i].symbol.uppercased()) {
                coins[i].isFavorite = true
            }
        }
    }
    private func saveFavorites() {
        let faves = coins.filter { $0.isFavorite }.map { $0.symbol.uppercased() }
        UserDefaults.standard.setValue(faves, forKey: favoritesKey)
    }
    func toggleFavorite(_ coin: MarketCoin) {
        guard let idx = coins.firstIndex(where: { $0.id == coin.id }) else { return }
        withAnimation(.spring()) {
            coins[idx].isFavorite.toggle()
        }
        saveFavorites()
        applyAllFiltersAndSort()
    }
    
    // Segment & Search
    func updateSegment(_ seg: MarketSegment) {
        selectedSegment = seg
        applyAllFiltersAndSort()
    }
    func updateSearch(_ query: String) {
        searchText = query
        applyAllFiltersAndSort()
    }
    
    // Sorting
    func toggleSort(for field: SortField) {
        if sortField == field {
            sortDirection = (sortDirection == .asc) ? .desc : .asc
        } else {
            sortField = field
            sortDirection = .asc
        }
        applyAllFiltersAndSort()
    }
    
    // Filter & Sort
    func applyAllFiltersAndSort() {
        var result = coins
        
        // 1) search
        let lowerSearch = searchText.lowercased()
        if !lowerSearch.isEmpty {
            result = result.filter {
                $0.symbol.lowercased().contains(lowerSearch) ||
                $0.name.lowercased().contains(lowerSearch)
            }
        }
        
        // 2) segment
        switch selectedSegment {
        case .all: break
        case .favorites:
            result = result.filter { $0.isFavorite }
        case .gainers:
            result = result.filter { $0.dailyChange > 0 }
        case .losers:
            result = result.filter { $0.dailyChange < 0 }
        }
        
        // 3) sort
        filteredCoins = sortCoins(result)
    }
    private func sortCoins(_ arr: [MarketCoin]) -> [MarketCoin] {
        guard sortField != .none else { return arr }
        return arr.sorted { lhs, rhs in
            switch sortField {
            case .coin:
                let compare = lhs.symbol.localizedCaseInsensitiveCompare(rhs.symbol)
                return sortDirection == .asc
                    ? (compare == .orderedAscending)
                    : (compare == .orderedDescending)
            case .price:
                return sortDirection == .asc ? (lhs.price < rhs.price) : (lhs.price > rhs.price)
            case .dailyChange:
                return sortDirection == .asc ? (lhs.dailyChange < rhs.dailyChange) : (lhs.dailyChange > rhs.dailyChange)
            case .volume:
                return sortDirection == .asc ? (lhs.volume < rhs.volume) : (lhs.volume > rhs.volume)
            case .none:
                return false
            }
        }
    }
    
    // ================================
    // MARK: - CoinGecko Integration
    // ================================

    // Step 1: Decodable structs for CoinGecko data
    struct CoinGeckoAPIResponse: Decodable {
        let id: String
        let symbol: String
        let name: String
        let image: String?
        let current_price: Double
        let price_change_percentage_24h: Double?
        let total_volume: Double?
        let sparkline_in_7d: SparklineIn7D?
    }
    struct SparklineIn7D: Decodable {
        let price: [Double]?
    }

    // Step 2: Function to fetch real data
    func fetchRealCoinsFromCoinGecko() {
        // Example: top 20 coins, sorted by market cap, with sparkline data
        let urlString = "https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=20&sparkline=true"
        
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard
                let data = data,
                error == nil,
                let decoded = try? JSONDecoder().decode([CoinGeckoAPIResponse].self, from: data)
            else {
                print("Failed to fetch or decode real data.")
                return
            }
            
            // Map the CoinGecko data to your existing MarketCoin model
            let newCoins: [MarketCoin] = decoded.map { item in
                let sparkline = item.sparkline_in_7d?.price ?? []
                
                return MarketCoin(
                    symbol: item.symbol.uppercased(),
                    name: item.name,
                    price: item.current_price,
                    dailyChange: item.price_change_percentage_24h ?? 0.0,
                    volume: item.total_volume ?? 0.0,
                    isFavorite: false, // We'll restore favorites below
                    sparklineData: sparkline
                )
            }
            
            DispatchQueue.main.async {
                // Replace your existing coins with the newly fetched coins
                self.coins = newCoins
                
                // Restore favorites if you have them saved
                self.loadFavorites()
                
                // Apply filters/sorting so your existing logic (segments, search) works
                self.applyAllFiltersAndSort()
            }
        }.resume()
    }
}

// MARK: - Main MarketView
struct MarketView: View {
    @StateObject private var vm = MarketViewModel()
    
    // Column widths
    private let coinWidth: CGFloat   = 140
    private let priceWidth: CGFloat  = 70
    private let dailyWidth: CGFloat  = 50
    private let volumeWidth: CGFloat = 70
    private let starWidth: CGFloat   = 40
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    topBar
                    segmentRow
                    if vm.showSearchBar {
                        searchBar
                    }
                    columnHeader
                    
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            ForEach(vm.filteredCoins) { coin in
                                // Wrap row in a NavigationLink to CoinDetailView
                                NavigationLink(destination: CoinDetailView(coin: coin)) {
                                    coinRow(coin)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Divider()
                                    .background(Color.white.opacity(0.1))
                                    .padding(.leading, 16)
                            }
                        }
                        .padding(.bottom, 12)
                    }
                    .refreshable {
                        // If you have refresh logic, put it here
                        try? await Task.sleep(nanoseconds: 1_000_000_000)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle()) // So it doesn't break on iPad
    }
}

// MARK: - Subviews
extension MarketView {
    
    private var topBar: some View {
        HStack {
            Text("Market")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            Spacer()
            Button(action: {
                withAnimation {
                    vm.showSearchBar.toggle()
                }
            }) {
                Image(systemName: vm.showSearchBar ? "magnifyingglass.circle.fill" : "magnifyingglass.circle")
                    .font(.title2)
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    private var segmentRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(MarketSegment.allCases, id: \.self) { seg in
                    Button(action: {
                        vm.updateSegment(seg)
                    }) {
                        Text(seg.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(vm.selectedSegment == seg ? .black : .white)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(vm.selectedSegment == seg ? Color.white : Color.white.opacity(0.1))
                            .cornerRadius(16)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
    }
    
    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Search coins...", text: $vm.searchText)
                .foregroundColor(.white)
                .onChange(of: vm.searchText) { newVal in
                    vm.updateSearch(newVal)
                }
        }
        .padding(8)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
    
    private var columnHeader: some View {
        HStack(spacing: 0) {
            headerButton("Coin", .coin)
                .frame(width: coinWidth, alignment: .leading)
            
            // If you want a timeframe label, e.g. "7D", remove or rename
            // or keep a separate mini-segment for sparkline timeframe
            Text("7D")
                .font(.caption)
                .foregroundColor(.white.opacity(0.9))
                .frame(width: 40, alignment: .trailing)
            
            headerButton("Price", .price)
                .frame(width: priceWidth, alignment: .trailing)
            headerButton("24h", .dailyChange)
                .frame(width: dailyWidth, alignment: .trailing)
            headerButton("Vol", .volume)
                .frame(width: volumeWidth, alignment: .trailing)
            Spacer().frame(width: starWidth)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.05))
    }
    
    private func headerButton(_ label: String, _ field: SortField) -> some View {
        Button {
            vm.toggleSort(for: field)
        } label: {
            HStack(spacing: 4) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
                if vm.sortField == field {
                    Image(systemName: vm.sortDirection == .asc ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .background(vm.sortField == field ? Color.white.opacity(0.05) : Color.clear)
    }
    
    private func coinRow(_ coin: MarketCoin) -> some View {
        HStack(spacing: 0) {
            // Left side: coin symbol & name
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.gray.opacity(0.6))
                    .frame(width: 32, height: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(coin.symbol.uppercased())
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    Text(coin.name)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            .frame(width: coinWidth, alignment: .leading)
            
            // Sparkline
            if #available(iOS 16, *) {
                sparkline(coin.sparklineData)
                    .frame(width: 40, height: 24)
            } else {
                // fallback
                Spacer().frame(width: 40)
            }
            
            // Price
            Text("$\(coin.price, specifier: "%.2f")")
                .font(.subheadline)
                .foregroundColor(.white)
                .frame(width: priceWidth, alignment: .trailing)
            
            // 24h
            Text("\(coin.dailyChange, specifier: "%.2f")%")
                .font(.caption)
                .foregroundColor(coin.dailyChange >= 0 ? .green : .red)
                .frame(width: dailyWidth, alignment: .trailing)
            
            // Volume
            Text(shortVolume(coin.volume))
                .font(.caption2)
                .foregroundColor(.white.opacity(0.9))
                .frame(width: volumeWidth, alignment: .trailing)
            
            // Favorite star
            Button {
                vm.toggleFavorite(coin)
            } label: {
                Image(systemName: coin.isFavorite ? "star.fill" : "star")
                    .foregroundColor(coin.isFavorite ? .yellow : .gray)
            }
            .buttonStyle(PlainButtonStyle())
            .frame(width: starWidth, alignment: .center)
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
    }
    
    // Mini sparkline using Swift Charts
    @ViewBuilder
    private func sparkline(_ data: [Double]) -> some View {
        if data.isEmpty {
            // e.g. empty placeholder
            Rectangle()
                .fill(Color.white.opacity(0.1))
        } else {
            Chart {
                ForEach(data.indices, id: \.self) { i in
                    LineMark(
                        x: .value("Index", i),
                        y: .value("Price", data[i])
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(data.last ?? 0 >= data.first ?? 0 ? Color.green : Color.red)
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
        }
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

// Optional preview
struct MarketView_Previews: PreviewProvider {
    static var previews: some View {
        MarketView()
    }
}
