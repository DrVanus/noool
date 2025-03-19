import SwiftUI
import Charts  // iOS 16+ for sparkline

// MARK: - Model
struct MarketCoin: Identifiable {
    let id = UUID()
    let symbol: String
    let name: String
    let price: Double
    let dailyChange: Double  // 24h % change
    let volume: Double
    var isFavorite: Bool = false
    
    // 7-day sparkline data
    let sparklineData: [Double]
    
    // Coin icon URL
    let imageUrl: String?
}

// Segments
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
    
    // Favorites
    private let favoritesKey = "favoriteCoinSymbols"
    
    init() {
        // 1) Show fallback coins instantly
        loadFallbackCoins()
        applyAllFiltersAndSort()
        
        // 2) Attempt background fetch for real data
        fetchRealCoinsFromCoinGecko()
    }
    
    // MARK: - 20 Fallback Coins
    private func loadFallbackCoins() {
        coins = [
            // 1
            MarketCoin(
                symbol: "BTC", name: "Bitcoin", price: 27950.0, dailyChange: -2.15, volume: 450_000_000,
                sparklineData: [27900, 27880, 27850, 27820, 27810, 27800, 27790],
                imageUrl: "https://assets.coingecko.com/coins/images/1/large/bitcoin.png"
            ),
            // 2
            MarketCoin(
                symbol: "ETH", name: "Ethereum", price: 1800.25, dailyChange: 3.44, volume: 210_000_000,
                sparklineData: [1790, 1795, 1802, 1808, 1805, 1810, 1807],
                imageUrl: "https://assets.coingecko.com/coins/images/279/large/ethereum.png"
            ),
            // 3
            MarketCoin(
                symbol: "BNB", name: "BNB", price: 320.0, dailyChange: -1.12, volume: 90_000_000,
                sparklineData: [320, 319, 318, 316, 315, 317, 316],
                imageUrl: "https://assets.coingecko.com/coins/images/825/large/bnb_icon2_2x.png"
            ),
            // 4
            MarketCoin(
                symbol: "XRP", name: "XRP", price: 0.46, dailyChange: 0.25, volume: 120_000_000,
                sparklineData: [0.45, 0.46, 0.465, 0.467, 0.463, 0.460, 0.461],
                imageUrl: "https://assets.coingecko.com/coins/images/44/large/xrp-symbol-white-128.png"
            ),
            // 5
            MarketCoin(
                symbol: "DOGE", name: "Dogecoin", price: 0.08, dailyChange: -0.56, volume: 50_000_000,
                sparklineData: [0.081, 0.080, 0.079, 0.078, 0.077, 0.078, 0.079],
                imageUrl: "https://assets.coingecko.com/coins/images/5/large/dogecoin.png"
            ),
            // 6
            MarketCoin(
                symbol: "ADA", name: "Cardano", price: 0.39, dailyChange: 2.14, volume: 65_000_000,
                sparklineData: [0.38, 0.385, 0.390, 0.395, 0.392, 0.388, 0.389],
                imageUrl: "https://assets.coingecko.com/coins/images/975/large/cardano.png"
            ),
            // 7
            MarketCoin(
                symbol: "MATIC", name: "Polygon", price: 1.15, dailyChange: 1.25, volume: 80_000_000,
                sparklineData: [1.10, 1.12, 1.14, 1.16, 1.17, 1.15, 1.14],
                imageUrl: "https://assets.coingecko.com/coins/images/4713/large/matic-token-icon.png"
            ),
            // 8
            MarketCoin(
                symbol: "SOL", name: "Solana", price: 22.0, dailyChange: -3.0, volume: 95_000_000,
                sparklineData: [23.0, 22.8, 22.5, 22.3, 22.2, 22.1, 22.0],
                imageUrl: "https://assets.coingecko.com/coins/images/4128/large/solana.png"
            ),
            // 9
            MarketCoin(
                symbol: "DOT", name: "Polkadot", price: 6.2, dailyChange: 0.5, volume: 40_000_000,
                sparklineData: [6.1, 6.15, 6.2, 6.25, 6.22, 6.18, 6.19],
                imageUrl: "https://assets.coingecko.com/coins/images/12171/large/polkadot.png"
            ),
            // 10
            MarketCoin(
                symbol: "LTC", name: "Litecoin", price: 90.0, dailyChange: 1.75, volume: 75_000_000,
                sparklineData: [88.0, 88.5, 89.0, 89.5, 90.2, 90.0, 89.8],
                imageUrl: "https://assets.coingecko.com/coins/images/2/large/litecoin.png"
            ),
            // 11
            MarketCoin(
                symbol: "TRX", name: "TRON", price: 0.06, dailyChange: -0.44, volume: 30_000_000,
                sparklineData: [0.061, 0.0605, 0.0602, 0.0598, 0.060, 0.0603, 0.0601],
                imageUrl: "https://assets.coingecko.com/coins/images/1094/large/tron-logo.png"
            ),
            // 12
            MarketCoin(
                symbol: "SHIB", name: "Shiba Inu", price: 0.000011, dailyChange: 2.0, volume: 100_000_000,
                sparklineData: [0.000010, 0.0000105, 0.000011, 0.0000112, 0.000011, 0.0000108, 0.000011],
                imageUrl: "https://assets.coingecko.com/coins/images/11939/large/shiba.png"
            ),
            // 13
            MarketCoin(
                symbol: "UNI", name: "Uniswap", price: 6.3, dailyChange: 1.1, volume: 25_000_000,
                sparklineData: [6.2, 6.25, 6.3, 6.35, 6.33, 6.28, 6.29],
                imageUrl: "https://assets.coingecko.com/coins/images/12504/large/uniswap-uni.png"
            ),
            // 14
            MarketCoin(
                symbol: "AVAX", name: "Avalanche", price: 17.0, dailyChange: -1.4, volume: 28_000_000,
                sparklineData: [17.5, 17.3, 17.1, 17.0, 16.9, 16.95, 17.0],
                imageUrl: "https://assets.coingecko.com/coins/images/12559/large/coin-round-red.png"
            ),
            // 15
            MarketCoin(
                symbol: "LINK", name: "Chainlink", price: 7.4, dailyChange: 2.5, volume: 45_000_000,
                sparklineData: [7.0, 7.1, 7.2, 7.3, 7.35, 7.4, 7.38],
                imageUrl: "https://assets.coingecko.com/coins/images/877/large/chainlink-new-logo.png"
            ),
            // 16
            MarketCoin(
                symbol: "ATOM", name: "Cosmos", price: 12.2, dailyChange: 0.8, volume: 22_000_000,
                sparklineData: [12.0, 12.1, 12.2, 12.25, 12.2, 12.15, 12.18],
                imageUrl: "https://assets.coingecko.com/coins/images/1481/large/cosmos_hub.png"
            ),
            // 17
            MarketCoin(
                symbol: "NEAR", name: "NEAR Protocol", price: 2.1, dailyChange: -0.66, volume: 18_000_000,
                sparklineData: [2.2, 2.18, 2.15, 2.12, 2.10, 2.09, 2.08],
                imageUrl: "https://assets.coingecko.com/coins/images/10365/large/near.jpg"
            ),
            // 18
            MarketCoin(
                symbol: "FTM", name: "Fantom", price: 0.45, dailyChange: 1.2, volume: 12_000_000,
                sparklineData: [0.44, 0.445, 0.45, 0.46, 0.455, 0.453, 0.452],
                imageUrl: "https://assets.coingecko.com/coins/images/4001/large/Fantom.png"
            ),
            // 19
            MarketCoin(
                symbol: "APE", name: "ApeCoin", price: 4.3, dailyChange: -2.1, volume: 14_000_000,
                sparklineData: [4.5, 4.4, 4.35, 4.3, 4.28, 4.25, 4.2],
                imageUrl: "https://assets.coingecko.com/coins/images/24383/large/apecoin.jpg"
            ),
            // 20
            MarketCoin(
                symbol: "SAND", name: "The Sandbox", price: 0.66, dailyChange: 1.0, volume: 9_000_000,
                sparklineData: [0.64, 0.65, 0.66, 0.67, 0.66, 0.655, 0.66],
                imageUrl: "https://assets.coingecko.com/coins/images/12129/large/sandbox_logo.jpg"
            )
        ]
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
    
    // Filter & Sort
    func applyAllFiltersAndSort() {
        var result = coins
        
        let lowerSearch = searchText.lowercased()
        if !lowerSearch.isEmpty {
            result = result.filter {
                $0.symbol.lowercased().contains(lowerSearch) ||
                $0.name.lowercased().contains(lowerSearch)
            }
        }
        
        switch selectedSegment {
        case .all: break
        case .favorites:
            result = result.filter { $0.isFavorite }
        case .gainers:
            result = result.filter { $0.dailyChange > 0 }
        case .losers:
            result = result.filter { $0.dailyChange < 0 }
        }
        
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
    
    // MARK: - CoinGecko fetch in background
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
        print("DEBUG: Attempting background fetch from CoinGecko (top 20, sparkline=true).")
        
        let urlString = """
        https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=20&page=1&sparkline=true
        """
        guard let url = URL(string: urlString) else {
            print("DEBUG: Invalid URL—keeping fallback.")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("DEBUG: Network error:", error.localizedDescription)
                // do nothing—keep fallback
                return
            }
            
            if let httpResp = response as? HTTPURLResponse {
                print("DEBUG: HTTP status code:", httpResp.statusCode)
                if !(200...299).contains(httpResp.statusCode) {
                    print("DEBUG: Non-2xx code—keeping fallback.")
                    return
                }
            }
            
            guard let data = data else {
                print("DEBUG: No data returned—keeping fallback.")
                return
            }
            
            guard let decoded = try? JSONDecoder().decode([CoinGeckoAPIResponse].self, from: data) else {
                print("DEBUG: Decoding error—keeping fallback.")
                return
            }
            
            let newCoins: [MarketCoin] = decoded.map { item in
                MarketCoin(
                    symbol: item.symbol.uppercased(),
                    name: item.name,
                    price: item.current_price,
                    dailyChange: item.price_change_percentage_24h ?? 0.0,
                    volume: item.total_volume ?? 0.0,
                    sparklineData: item.sparkline_in_7d?.price ?? [],
                    imageUrl: item.image
                )
            }
            
            DispatchQueue.main.async {
                print("DEBUG: Successfully fetched real top 20 coins—replacing fallback.")
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
    
    private let coinWidth: CGFloat   = 140
    private let priceWidth: CGFloat  = 70
    private let dailyWidth: CGFloat  = 50
    private let volumeWidth: CGFloat = 70
    private let starWidth: CGFloat   = 40
    
    var body: some View {
        NavigationView {
            // No indefinite spinner— fallback is shown immediately
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
                            if vm.filteredCoins.isEmpty {
                                VStack {
                                    Text(vm.searchText.isEmpty
                                         ? "No coins available."
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
                    // Pull-to-refresh tries to fetch real data again
                    .refreshable {
                        try? await Task.sleep(nanoseconds: 1_000_000_000)
                        vm.fetchRealCoinsFromCoinGecko()
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
            Button {
                withAnimation {
                    vm.showSearchBar.toggle()
                }
            } label: {
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
                    Button {
                        vm.updateSegment(seg)
                    } label: {
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
                .onChange(of: vm.searchText) { _ in
                    vm.applyAllFiltersAndSort()
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
            // Left side: icon + name
            HStack(spacing: 8) {
                if let urlStr = coin.imageUrl, let url = URL(string: urlStr) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
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
            
            // Sparkline in a 50×30 container for more vertical space
            if #available(iOS 16, *) {
                ZStack(alignment: .center) {
                    Rectangle().fill(Color.clear)
                    sparkline(coin.sparklineData, dailyChange: coin.dailyChange)
                }
                .frame(width: 50, height: 30)
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
    
    // Sparkline colored by dailyChange
    @ViewBuilder
    private func sparkline(_ data: [Double], dailyChange: Double) -> some View {
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
                    // color by 24h dailyChange
                    .foregroundStyle(dailyChange >= 0 ? Color.green : Color.red)
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

struct MarketView_Previews: PreviewProvider {
    static var previews: some View {
        MarketView()
            .preferredColorScheme(.dark)
    }
}
