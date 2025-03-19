import SwiftUI
import Charts  // For mini-sparklines on iOS 16+

// MARK: - Model
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
    
    // New: imageUrl for coin icon
    let imageUrl: String?
}

enum MarketSegment: String, CaseIterable {
    case all = "All"
    case favorites = "Favorites"
    case gainers = "Gainers"
    case losers  = "Losers"
}

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
    
    // Loading indicator
    @Published var isLoading: Bool = false
    
    init() {
        loadFavorites()
        // Start the spinner
        isLoading = true
        fetchRealCoinsFromCoinGecko()
    }
    
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
        case .all:
            break
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
                return sortDirection == .asc ? (compare == .orderedAscending) : (compare == .orderedDescending)
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
    
    // MARK: - CoinGecko Integration
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
    
    func fetchRealCoinsFromCoinGecko() {
        print("DEBUG: Starting fetch from CoinGecko (top 20, sparkline=false).")
        
        let urlString = "https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=20&page=1&sparkline=false"
        guard let url = URL(string: urlString) else {
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            defer {
                // remove spinner in any case
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
            if let error = error {
                print("DEBUG: Network error:", error.localizedDescription)
                return
            }
            
            if let httpResp = response as? HTTPURLResponse {
                print("DEBUG: HTTP status code:", httpResp.statusCode)
            }
            
            guard let data = data else {
                print("DEBUG: No data returned.")
                return
            }
            
            guard let decoded = try? JSONDecoder().decode([CoinGeckoAPIResponse].self, from: data) else {
                print("DEBUG: Decoding error.")
                return
            }
            
            let newCoins: [MarketCoin] = decoded.map { item in
                MarketCoin(
                    symbol: item.symbol.uppercased(),
                    name: item.name,
                    price: item.current_price,
                    dailyChange: item.price_change_percentage_24h ?? 0.0,
                    volume: item.total_volume ?? 0.0,
                    isFavorite: false,
                    sparklineData: [],
                    imageUrl: item.image
                )
            }
            
            DispatchQueue.main.async {
                print("DEBUG: Successfully fetched and decoded top 20 coins!")
                self.coins = newCoins
                self.loadFavorites()
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
                
                if vm.isLoading {
                    // Show a spinner while loading
                    VStack {
                        ProgressView("Loading Market Data...")
                            .foregroundColor(.white)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .padding()
                    }
                } else {
                    VStack(spacing: 0) {
                        topBar
                        segmentRow
                        if vm.showSearchBar {
                            searchBar
                        }
                        columnHeader
                        
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 0) {
                                if vm.filteredCoins.isEmpty {
                                    // If no coins after filtering
                                    VStack {
                                        Text(vm.searchText.isEmpty
                                             ? "Unable to load coin data."
                                             : "No coins match your search.")
                                            .foregroundColor(.gray)
                                            .padding(.top, 40)
                                    }
                                } else {
                                    ForEach(vm.filteredCoins) { coin in
                                        NavigationLink(destination: CoinDetailView(coin: coin)) {
                                            coinRow(coin)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        
                                        Divider()
                                            .background(Color.white.opacity(0.1))
                                            .padding(.leading, 16)
                                    }
                                }
                            }
                            .padding(.bottom, 12)
                        }
                        .refreshable {
                            // Pull-to-refresh
                            try? await Task.sleep(nanoseconds: 1_000_000_000)
                            DispatchQueue.main.async {
                                vm.isLoading = true
                                vm.fetchRealCoinsFromCoinGecko()
                            }
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
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
            // Coin icon + name
            HStack(spacing: 8) {
                // Async coin image
                if let urlStr = coin.imageUrl, let url = URL(string: urlStr) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 32, height: 32)
                                .clipShape(Circle())
                        case .failure(_):
                            Circle()
                                .fill(Color.gray.opacity(0.6))
                                .frame(width: 32, height: 32)
                        case .empty:
                            ProgressView()
                                .frame(width: 32, height: 32)
                        @unknown default:
                            Circle()
                                .fill(Color.gray.opacity(0.6))
                                .frame(width: 32, height: 32)
                        }
                    }
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.6))
                        .frame(width: 32, height: 32)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(coin.symbol.uppercased())
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text(coin.name)
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
            .frame(width: coinWidth, alignment: .leading)
            
            // Sparkline (7d) or placeholder
            if #available(iOS 16, *) {
                sparkline(coin.sparklineData)
                    .frame(width: 40, height: 24)
            } else {
                Spacer().frame(width: 40)
            }
            
            // Price
            Text(String(format: "$%.2f", coin.price))
                .font(.subheadline)
                .foregroundColor(.white)
                .frame(width: priceWidth, alignment: .trailing)
                .lineLimit(1)
            
            // 24h
            Text(String(format: "%.2f%%", coin.dailyChange))
                .font(.caption)
                .foregroundColor(coin.dailyChange >= 0 ? .green : .red)
                .frame(width: dailyWidth, alignment: .trailing)
                .lineLimit(1)
            
            // Volume
            Text(shortVolume(coin.volume))
                .font(.caption2)
                .foregroundColor(.white.opacity(0.9))
                .frame(width: volumeWidth, alignment: .trailing)
                .lineLimit(1)
            
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
    
    @ViewBuilder
    private func sparkline(_ data: [Double]) -> some View {
        if data.isEmpty {
            Rectangle().fill(Color.white.opacity(0.1))
        } else {
            Chart {
                ForEach(data.indices, id: \.self) { i in
                    LineMark(
                        x: .value("Index", i),
                        y: .value("Price", data[i])
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle((data.last ?? 0) >= (data.first ?? 0) ? Color.green : Color.red)
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
