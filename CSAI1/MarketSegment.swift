//
//  MarketSegment.swift
//  CSAI1
//
//  Created by DM on 4/1/25.
//


//
//  MarketViewModel.swift
//  CSAI1
//
//  Created by ChatGPT on 4/1/25
//

import SwiftUI

// MARK: - Segment & Sort

enum MarketSegment: String, CaseIterable {
    case all = "All"
    case favorites = "Favorites"
    case gainers = "Gainers"
    case losers  = "Losers"
}

enum SortField: String {
    case coin, price, dailyChange, volume, marketCap, none
}

enum SortDirection {
    case asc, desc
}

// MARK: - Global Data

struct GlobalMarketDataResponse: Codable {
    let data: GlobalMarketData
}

struct GlobalMarketData: Codable {
    let active_cryptocurrencies: Int?
    let markets: Int?
    let total_market_cap: [String: Double]?
    let total_volume: [String: Double]?
    let market_cap_percentage: [String: Double]?
    let market_cap_change_percentage_24h_usd: Double?
}

// MARK: - Cache Managers

class MarketCacheManager {
    static let shared = MarketCacheManager()
    private let fileName = "cachedMarketData.json"
    private init() {}
    
    func saveCoinsToDisk(_ coins: [CoinGeckoMarketData]) {
        do {
            let data = try JSONEncoder().encode(coins)
            let url = try cacheFileURL()
            try data.write(to: url, options: .atomic)
        } catch {
            print("Failed to save coin data: \(error)")
        }
    }
    
    func loadCoinsFromDisk() -> [CoinGeckoMarketData]? {
        do {
            let url = try cacheFileURL()
            guard FileManager.default.fileExists(atPath: url.path) else { return nil }
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([CoinGeckoMarketData].self, from: data)
        } catch {
            print("Failed to load cached data: \(error)")
            return nil
        }
    }
    
    private func cacheFileURL() throws -> URL {
        guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw URLError(.fileDoesNotExist)
        }
        return docs.appendingPathComponent(fileName)
    }
}

class GlobalCacheManager {
    static let shared = GlobalCacheManager()
    private let fileName = "cachedGlobalData.json"
    private init() {}
    
    func saveGlobalData(_ data: GlobalMarketData) {
        do {
            let encoded = try JSONEncoder().encode(data)
            let url = try cacheFileURL()
            try encoded.write(to: url, options: .atomic)
        } catch {
            print("Failed to save global data: \(error)")
        }
    }
    
    func loadGlobalData() -> GlobalMarketData? {
        do {
            let url = try cacheFileURL()
            guard FileManager.default.fileExists(atPath: url.path) else { return nil }
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(GlobalMarketData.self, from: data)
        } catch {
            print("Failed to load cached global data: \(error)")
            return nil
        }
    }
    
    private func cacheFileURL() throws -> URL {
        guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw URLError(.fileDoesNotExist)
        }
        return docs.appendingPathComponent(fileName)
    }
}

// MARK: - Helper for Explicit Async Timeouts

func withTimeout<T>(seconds: Double, operation: @escaping () async throws -> T) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            return try await operation()
        }
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw URLError(.timedOut)
        }
        guard let result = try await group.next() else {
            throw URLError(.timedOut)
        }
        group.cancelAll()
        return result
    }
}

// MARK: - MarketViewModel

@MainActor
class MarketViewModel: ObservableObject {
    @Published var coins: [MarketCoin] = []
    @Published var filteredCoins: [MarketCoin] = []
    @Published var globalData: GlobalMarketData?
    @Published var isLoading: Bool = false
    
    @Published var selectedSegment: MarketSegment = .all
    @Published var showSearchBar: Bool = false
    @Published var searchText: String = ""
    
    @Published var sortField: SortField = .marketCap
    @Published var sortDirection: SortDirection = .desc
    
    @Published var coinError: String?
    @Published var globalError: String?
    
    private let favoritesKey = "favoriteCoinSymbols"
    private var coinRefreshTask: Task<Void, Never>?
    private var globalRefreshTask: Task<Void, Never>?
    
    private let pinnedCoins = ["BTC", "ETH", "BNB", "XRP", "ADA", "DOGE", "MATIC", "SOL", "DOT", "LTC", "SHIB", "TRX", "AVAX", "LINK", "UNI", "BCH"]
    
    init() {
        if let cached = MarketCacheManager.shared.loadCoinsFromDisk() {
            self.coins = cached.map {
                MarketCoin(
                    id: UUID(),
                    symbol: $0.symbol.uppercased(),
                    name: $0.name,
                    price: $0.current_price,
                    dailyChange: $0.price_change_percentage_24h ?? 0,
                    hourlyChange: $0.price_change_percentage_1h_in_currency ?? 0,
                    volume: $0.total_volume,
                    marketCap: $0.market_cap ?? 0,
                    isFavorite: false,
                    sparklineData: $0.sparkline_in_7d?.price ?? [],
                    imageUrl: $0.image,
                    finalImageUrl: nil
                )
            }
            self.coins.sort { $0.marketCap > $1.marketCap }
        } else {
            loadFallbackCoins()
        }
        
        if let cachedGlobal = GlobalCacheManager.shared.loadGlobalData() {
            self.globalData = cachedGlobal
        }
        
        loadFavorites()
        applyAllFiltersAndSort()
        
        Task {
            await fetchMarketDataMulti()
            await fetchGlobalMarketDataMulti()
        }
        
        startAutoRefresh()
    }
    
    deinit {
        coinRefreshTask?.cancel()
        globalRefreshTask?.cancel()
    }
    
    // MARK: - Fetching Coin Data
    
    private func fetchCoinGecko() async throws -> [CoinGeckoMarketData] {
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 15
        sessionConfig.waitsForConnectivity = false
        let session = URLSession(configuration: sessionConfig)
        
        return try await withThrowingTaskGroup(of: [CoinGeckoMarketData].self) { group in
            for page in 1...3 {
                group.addTask {
                    let urlString = """
                    https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd\
                    &order=market_cap_desc&per_page=100&page=\(page)&sparkline=true\
                    &price_change_percentage=1h,24h
                    """
                    guard let url = URL(string: urlString) else { throw URLError(.badURL) }
                    let data = try await withTimeout(seconds: 15) {
                        let (d, response) = try await session.data(from: url)
                        if let httpResp = response as? HTTPURLResponse, httpResp.statusCode != 200 {
                            throw URLError(.badServerResponse)
                        }
                        return d
                    }
                    return try JSONDecoder().decode([CoinGeckoMarketData].self, from: data)
                }
            }
            var allCoins: [CoinGeckoMarketData] = []
            for try await pageCoins in group {
                allCoins.append(contentsOf: pageCoins)
            }
            return allCoins
        }
    }
    
    private func fetchCoinGeckoWithRetry(retries: Int = 1) async throws -> [CoinGeckoMarketData] {
        var lastError: Error?
        for attempt in 0...retries {
            do {
                return try await fetchCoinGecko()
            } catch {
                lastError = error
                if attempt < retries {
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                }
            }
        }
        throw lastError ?? URLError(.cannotLoadFromNetwork)
    }
    
    private func fetchCoinPaprika() async throws -> [CoinPaprikaData] {
        let urlString = "https://api.coinpaprika.com/v1/tickers?quotes=USD&limit=100"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 15
        sessionConfig.waitsForConnectivity = false
        let session = URLSession(configuration: sessionConfig)
        
        let (data, response) = try await session.data(from: url)
        if let httpResp = response as? HTTPURLResponse, httpResp.statusCode != 200 {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode([CoinPaprikaData].self, from: data)
    }
    
    func fetchMarketDataMulti() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let geckoCoins = try await fetchCoinGeckoWithRetry(retries: 1)
            MarketCacheManager.shared.saveCoinsToDisk(geckoCoins)
            var updatedCoins = geckoCoins.map { raw in
                MarketCoin(
                    id: UUID(),
                    symbol: raw.symbol.uppercased(),
                    name: raw.name,
                    price: raw.current_price,
                    dailyChange: raw.price_change_percentage_24h ?? 0,
                    hourlyChange: raw.price_change_percentage_1h_in_currency ?? 0,
                    volume: raw.total_volume,
                    marketCap: raw.market_cap ?? 0,
                    isFavorite: false,
                    sparklineData: raw.sparkline_in_7d?.price ?? [],
                    imageUrl: raw.image,
                    finalImageUrl: nil
                )
            }
            updatedCoins = updatedCoins.filter { coin in
                let nameLC = coin.name.lowercased()
                return !(nameLC.contains("binance-peg") || nameLC.contains("bridged") || nameLC.contains("wormhole"))
            }
            var seenSymbols = Set<String>()
            updatedCoins = updatedCoins.filter { coin in
                let (inserted, _) = seenSymbols.insert(coin.symbol)
                return inserted
            }
            
            self.coins = updatedCoins
            
            if searchText.isEmpty && selectedSegment == .all && sortField == .marketCap && sortDirection == .desc {
                let pinnedCoinsList = coins.filter { pinnedCoins.contains($0.symbol) }
                let otherCoins = coins.filter { !pinnedCoins.contains($0.symbol) }
                self.coins = pinnedCoinsList.sorted { (a, b) in
                    let idxA = pinnedCoins.firstIndex(of: a.symbol) ?? Int.max
                    let idxB = pinnedCoins.firstIndex(of: b.symbol) ?? Int.max
                    return idxA < idxB
                } + otherCoins.sorted { $0.marketCap > $1.marketCap }
            } else {
                self.coins.sort { $0.marketCap > $1.marketCap }
            }
            
            coinError = nil
        } catch {
            do {
                let papCoins = try await fetchCoinPaprika()
                var updated: [MarketCoin] = []
                for pap in papCoins {
                    let price    = pap.quotes?["USD"]?.price ?? 0
                    let vol      = pap.quotes?["USD"]?.volume_24h ?? 0
                    let change24 = pap.quotes?["USD"]?.percent_change_24h ?? 0
                    let change1h = pap.quotes?["USD"]?.percent_change_1h ?? 0
                    let newCoin = MarketCoin(
                        id: UUID(),
                        symbol: pap.symbol.uppercased(),
                        name: pap.name,
                        price: price,
                        dailyChange: change24,
                        hourlyChange: change1h,
                        volume: vol,
                        marketCap: pap.quotes?["USD"]?.market_cap ?? 0,
                        isFavorite: false,
                        sparklineData: [],
                        imageUrl: nil,
                        finalImageUrl: nil
                    )
                    updated.append(newCoin)
                }
                updated = updated.filter {
                    let nameLC = $0.name.lowercased()
                    return !(nameLC.contains("binance-peg") || nameLC.contains("bridged") || nameLC.contains("wormhole"))
                }
                var seen = Set<String>()
                updated = updated.filter {
                    let (inserted, _) = seen.insert($0.symbol)
                    return inserted
                }
                
                self.coins = updated.sorted { $0.marketCap > $1.marketCap }
                coinError = nil
            } catch {
                coinError = "Failed to load market data. Please try again later."
            }
        }
        loadFavorites()
        applyAllFiltersAndSort()
    }
    
    // MARK: - Fetching Global Data
    
    private func fetchGlobalCoinGecko() async throws -> GlobalMarketData {
        let urlString = "https://api.coingecko.com/api/v3/global"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 15
        sessionConfig.waitsForConnectivity = false
        let session = URLSession(configuration: sessionConfig)
        let (data, response) = try await session.data(from: url)
        if let httpResp = response as? HTTPURLResponse, httpResp.statusCode != 200 {
            throw URLError(.badServerResponse)
        }
        let decoded = try JSONDecoder().decode(GlobalMarketDataResponse.self, from: data)
        return decoded.data
    }
    
    private func fetchGlobalPaprika() async throws -> GlobalMarketData {
        let urlString = "https://api.coinpaprika.com/v1/global"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 15
        sessionConfig.waitsForConnectivity = false
        let session = URLSession(configuration: sessionConfig)
        let (data, response) = try await session.data(from: url)
        if let httpResp = response as? HTTPURLResponse, httpResp.statusCode != 200 {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(GlobalMarketData.self, from: data)
    }
    
    func fetchGlobalMarketDataMulti() async {
        do {
            let gData = try await fetchGlobalCoinGecko()
            GlobalCacheManager.shared.saveGlobalData(gData)
            self.globalData = gData
            globalError = nil
        } catch {
            do {
                let fallback = try await fetchGlobalPaprika()
                GlobalCacheManager.shared.saveGlobalData(fallback)
                self.globalData = fallback
                globalError = "Using fallback aggregator for global data."
            } catch {
                globalError = "Global data error: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Fallback Local Data
    
    private func loadFallbackCoins() {
        self.coins = [
            MarketCoin(
                id: UUID(),
                symbol: "BTC",
                name: "Bitcoin",
                price: 28000,
                dailyChange: -2.15,
                hourlyChange: -0.30,
                volume: 450_000_000,
                marketCap: 500_000_000_000,
                isFavorite: false,
                sparklineData: [28000, 27950, 27980, 27890, 27850, 27820, 27800],
                imageUrl: "https://www.cryptocompare.com/media/19633/btc.png",
                finalImageUrl: nil
            ),
            MarketCoin(
                id: UUID(),
                symbol: "ETH",
                name: "Ethereum",
                price: 1800,
                dailyChange: 3.44,
                hourlyChange: 0.50,
                volume: 210_000_000,
                marketCap: 200_000_000_000,
                isFavorite: false,
                sparklineData: [1790, 1795, 1802, 1808, 1805, 1810, 1807],
                imageUrl: "https://www.cryptocompare.com/media/20646/eth.png",
                finalImageUrl: nil
            )
        ]
    }
    
    // MARK: - Favorites
    
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
    
    // MARK: - Sorting & Filtering
    
    @MainActor
    func updateSegment(_ seg: MarketSegment) {
        selectedSegment = seg
        applyAllFiltersAndSort()
    }
    
    @MainActor
    func updateSearch(_ query: String) {
        searchText = query
        applyAllFiltersAndSort()
    }
    
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
        
        let lowerSearch = searchText.lowercased()
        if !lowerSearch.isEmpty {
            result = result.filter {
                $0.symbol.lowercased().contains(lowerSearch) ||
                $0.name.lowercased().contains(lowerSearch)
            }
        }
        
        switch selectedSegment {
        case .favorites:
            result = result.filter { $0.isFavorite }
        case .gainers:
            result = result.filter { $0.dailyChange > 0 }
        case .losers:
            result = result.filter { $0.dailyChange < 0 }
        default:
            break
        }
        
        withAnimation {
            filteredCoins = sortCoins(result)
        }
    }
    
    private func sortCoins(_ arr: [MarketCoin]) -> [MarketCoin] {
        guard sortField != .none else { return arr }
        if searchText.isEmpty && selectedSegment == .all && sortField == .marketCap && sortDirection == .desc {
            let pinnedList = arr.filter { pinnedCoins.contains($0.symbol) }
            let nonPinned = arr.filter { !pinnedCoins.contains($0.symbol) }
            let sortedPinned = pinnedList.sorted {
                let idx0 = pinnedCoins.firstIndex(of: $0.symbol) ?? Int.max
                let idx1 = pinnedCoins.firstIndex(of: $1.symbol) ?? Int.max
                return idx0 < idx1
            }
            let sortedOthers = nonPinned.sorted { $0.marketCap > $1.marketCap }
            return sortedPinned + sortedOthers
        } else {
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
                case .marketCap:
                    return sortDirection == .asc ? (lhs.marketCap < rhs.marketCap) : (lhs.marketCap > rhs.marketCap)
                case .none:
                    return false
                }
            }
        }
    }
    
    // MARK: - Auto-Refresh
    
    private func startAutoRefresh() {
        coinRefreshTask = Task.detached { [weak self] in
            guard let self = self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 60_000_000_000)
                await self.fetchMarketDataMulti()
            }
        }
        
        globalRefreshTask = Task.detached { [weak self] in
            guard let self = self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 180_000_000_000)
                await self.fetchGlobalMarketDataMulti()
            }
        }
    }
    
    // MARK: - Optional: Live Prices from Coinbase/Binance
    
    func fetchLivePricesFromCoinbase() {
        let currentCoins = coins
        Task {
            var updates: [(symbol: String, newPrice: Double, newSpark: [Double])] = []
            for coin in currentCoins {
                if let newPrice = await CoinbaseService().fetchSpotPrice(coin: coin.symbol, fiat: "USD") {
                    let newSpark = await BinanceService.fetchSparkline(symbol: coin.symbol)
                    updates.append((symbol: coin.symbol, newPrice: newPrice, newSpark: newSpark))
                }
            }
            
            await MainActor.run {
                for update in updates {
                    if let idx = coins.firstIndex(where: { $0.symbol == update.symbol }) {
                        coins[idx].price = update.newPrice
                        if !update.newSpark.isEmpty {
                            coins[idx].sparklineData = update.newSpark
                        }
                    }
                }
                applyAllFiltersAndSort()
            }
        }
    }
}
