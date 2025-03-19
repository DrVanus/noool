//
//  HomeView.swift
//  CRYPTOSAI
//
//  ~1000 lines, with 7 timeframes (24H, 1W, 1M, 3M, 6M, 1Y, ALL)
//  plus a polished AI Analysis sheet.
//
//  IMPORTANT: This file defines `LocalCoinItem` for top gainers/losers placeholders.
//  Ensure you do NOT have another `CoinItem` struct in HomeViewModel or Models.swift.
//

import SwiftUI
import Charts  // iOS 16+ for sparkline

// MARK: - Sparkline Model
struct SparklinePoint: Identifiable {
    let id = UUID()
    let day: Int
    let price: Double
}

// MARK: - Extended Timeframe enum
enum Timeframe: String, CaseIterable {
    case day24 = "24H"
    case week1 = "1W"
    case month1 = "1M"
    case month3 = "3M"
    case month6 = "6M"
    case year1  = "1Y"
    case all    = "ALL"
}

// MARK: - LocalCoinItem (renamed to avoid conflicts)
struct LocalCoinItem: Identifiable {
    let id = UUID()
    let symbol: String
    let price: Double
    let change24h: Double
}

// MARK: - Main HomeView
struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    
    // MARK: Sparkline placeholders for each timeframe
    private let day24Data: [SparklinePoint] = [
        .init(day: 1, price: 108),
        .init(day: 2, price: 109),
        .init(day: 3, price: 110)
    ]
    private let week1Data: [SparklinePoint] = [
        .init(day: 1, price: 100),
        .init(day: 2, price: 104),
        .init(day: 3, price: 102),
        .init(day: 4, price: 107),
        .init(day: 5, price: 103),
        .init(day: 6, price: 110),
        .init(day: 7, price: 108)
    ]
    private let month1Data: [SparklinePoint] = [
        .init(day: 1, price: 95),
        .init(day: 2, price: 97),
        .init(day: 3, price: 100),
        .init(day: 4, price: 102),
        .init(day: 5, price: 99),
        .init(day: 6, price: 105),
        .init(day: 7, price: 107),
        .init(day: 8, price: 108),
        .init(day: 9, price: 110)
    ]
    private let month3Data: [SparklinePoint] = [
        .init(day: 1,  price: 80),
        .init(day: 10, price: 85),
        .init(day: 20, price: 90),
        .init(day: 30, price: 92),
        .init(day: 40, price: 95),
        .init(day: 50, price: 88),
        .init(day: 60, price: 96),
        .init(day: 70, price: 104),
        .init(day: 80, price: 100),
        .init(day: 90, price: 108)
    ]
    private let month6Data: [SparklinePoint] = [
        .init(day: 1,   price: 70),
        .init(day: 30,  price: 75),
        .init(day: 60,  price: 82),
        .init(day: 90,  price: 78),
        .init(day: 120, price: 85),
        .init(day: 150, price: 92),
        .init(day: 180, price: 98)
    ]
    private let year1Data: [SparklinePoint] = [
        .init(day: 1,   price: 60),
        .init(day: 50,  price: 65),
        .init(day: 100, price: 70),
        .init(day: 150, price: 90),
        .init(day: 200, price: 85),
        .init(day: 250, price: 95),
        .init(day: 300, price: 105),
        .init(day: 365, price: 102)
    ]
    private let allData: [SparklinePoint] = [
        .init(day: 1,   price: 30),
        .init(day: 50,  price: 45),
        .init(day: 100, price: 60),
        .init(day: 150, price: 55),
        .init(day: 200, price: 80),
        .init(day: 250, price: 75),
        .init(day: 300, price: 100),
        .init(day: 350, price: 120),
        .init(day: 400, price: 110),
        .init(day: 450, price: 130)
    ]
    
    // Current timeframe selection
    @State private var selectedTimeframe: Timeframe = .week1
    
    // AI analysis bullet points
    private let aiAnalysisPoints = [
        "BTC is ~60% of your portfolio; consider rebalancing.",
        "ETH staking yields ~5% APY.",
        "SOL might be volatile short-term.",
        "Consider a 5% stop-loss below current prices.",
        "Portfolio risk: Moderate."
    ]
    
    // Toggle search bar
    @State private var showSearchBar = false
    
    // Toggle AI analysis sheet
    @State private var showAnalysisSheet = false
    
    // Reordered promo banners
    private let promoBanners = [
        "New AI Feature: Portfolio Risk Scan",
        "Invite Friends & Get Bonus",
        "Spring Event: Earn Double Rewards"
    ]
    
    // Market stats placeholders
    private let marketStats: [(title: String, value: String)] = [
        ("Global Market Cap", "$1.24T"),
        ("24h Volume", "$63.8B"),
        ("BTC Dominance", "46.3%"),
        ("ETH Dominance", "19.1%")
    ]
    
    // Example top losers
    private let topLosers: [LocalCoinItem] = [
        LocalCoinItem(symbol: "LOSERCOIN", price: 0.023, change24h: -14.56),
        LocalCoinItem(symbol: "BEAR",      price: 1.45,  change24h: -9.88),
        LocalCoinItem(symbol: "DROPS",     price: 0.78,  change24h: -8.33)
    ]
    
    // Example top gainers
    private let sampleTopGainers: [LocalCoinItem] = [
        LocalCoinItem(symbol: "FARTCOIN", price: 0.303, change24h: 23.93),
        LocalCoinItem(symbol: "VIRTUAL",  price: 19.88, change24h: 14.76),
        LocalCoinItem(symbol: "HYPE",     price: 14.70, change24h: 12.05)
    ]
    
    // Arbitrage placeholders
    private let arbitrageData = [
        ("BTC/USDT", "Exchange A: $65,000", "Exchange B: $65,200", "Profit: $200"),
        ("ETH/USDT", "Exchange C: $1,800", "Exchange D: $1,805", "Profit: $5")
    ]
    
    // Events placeholders
    private let events = [
        ("ETH2 Hard Fork", "May 30", "Upgrade to reduce fees"),
        ("DOGE Conference", "Jun 10", "Global doge event"),
        ("SOL Hackathon",   "Jun 15", "Devs gather for new apps")
    ]
    
    // Featured articles placeholders
    private let featuredArticles = [
        ("Why BTC might hit $100K", "A deep analysis by AI"),
        ("DeFi 2.0: The Next Wave", "New protocols leading the charge"),
        ("Metaverse or Hype?",      "Exploring real utility of NFTs")
    ]
    
    // Example recent transactions
    private let recentTransactions = [
        ("Buy BTC",   "+0.012 BTC", "$350", "1h ago"),
        ("Sell ETH",  "-0.05 ETH",  "$90",  "3h ago"),
        ("Stake SOL", "+10 SOL",    "N/A",  "6h ago")
    ]
    
    // Computed sparkline data
    private var currentSparklineData: [SparklinePoint] {
        switch selectedTimeframe {
        case .day24:  return day24Data
        case .week1:  return week1Data
        case .month1: return month1Data
        case .month3: return month3Data
        case .month6: return month6Data
        case .year1:  return year1Data
        case .all:    return allData
        }
    }
    
    var body: some View {
        ZStack {
            // Dark background
            Color.black.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 24) {
                    
                    // 0. Optional search bar
                    if showSearchBar {
                        searchBar
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // 1. Profile bar
                    userProfileBar
                    
                    // 2. Banners
                    promotionalBannerCarousel
                    
                    // 3. Portfolio container (timeframe chips + sparkline + AI)
                    portfolioContainer
                    
                    // 4. Market Stats
                    marketStatsContainer
                    
                    // 5. Quick Actions
                    quickActionsRow
                    
                    // 6. Trending
                    trendingSection
                    
                    // 7. Watchlist
                    watchlistSection
                    
                    // 8. Top Gainers
                    topGainersSection
                    
                    // 9. Top Losers
                    topLosersSection
                    
                    // 10. Arbitrage
                    arbitrageSection
                    
                    // 11. Events
                    eventsSection
                    
                    // 12. Explore
                    exploreSection
                    
                    // 13. Featured Articles
                    featuredArticlesSection
                    
                    // 14. Recent Transactions
                    recentTransactionsSection
                    
                    // 15. News
                    newsSection
                    
                    // 16. Social
                    socialSection
                    
                    // 17. Disclaimers footer
                    footerDisclaimer
                }
                .padding(.top, 20)
                .padding(.bottom, 40)
                .animation(.easeInOut, value: showSearchBar)
                .onAppear {
                    viewModel.fetchData()
                }
            }
        }
        .navigationBarHidden(true)
        // AI analysis sheet with custom detents
        .sheet(isPresented: $showAnalysisSheet) {
            aiAnalysisSheet
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Subviews
extension HomeView {
    
    // MARK: 0. Search bar
    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Search coins, news...", text: .constant(""))
                .foregroundColor(.white)
        }
        .padding(8)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
        .padding(.horizontal, 16)
    }
    
    // MARK: 1. Profile bar
    private var userProfileBar: some View {
        HStack(spacing: 12) {
            // Placeholder avatar
            Circle()
                .fill(Color.gray)
                .frame(width: 36, height: 36)
                .overlay(Text("U").foregroundColor(.white))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Hello, User!")
                    .font(.subheadline)
                    .foregroundColor(.white)
                Text("Level 3 Trader")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
            
            // Toggle search
            Button(action: {
                withAnimation {
                    showSearchBar.toggle()
                }
            }) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white)
            }
            
            // Notifications
            Button(action: {
                // open notifications
            }) {
                Image(systemName: "bell.fill")
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: 2. Banners
    private var promotionalBannerCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(promoBanners, id: \.self) { bannerText in
                    promoBannerCard(text: bannerText)
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    private func promoBannerCard(text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(text)
                .font(.subheadline)
                .bold()
                .foregroundColor(.white)
            Text("Tap to learn more")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(width: 220, height: 80, alignment: .topLeading)
        .padding(12)
        .background(Color.blue.opacity(0.2))
        .cornerRadius(10)
    }
    
    // MARK: 3. Portfolio container
    private var portfolioContainer: some View {
        VStack(spacing: 16) {
            // Timeframe row
            timeframeChipRow
            
            portfolioSummary
            sparklineView
            
            // AI short insight
            aiInsightSection
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
        .padding(.horizontal, 16)
    }
    
    private var timeframeChipRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Timeframe.allCases, id: \.self) { tf in
                    Button(action: {
                        selectedTimeframe = tf
                    }) {
                        Text(tf.rawValue)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(selectedTimeframe == tf ? .black : .white)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(
                                selectedTimeframe == tf
                                ? Color.white
                                : Color.white.opacity(0.1)
                            )
                            .cornerRadius(16)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
    
    private var portfolioSummary: some View {
        VStack(spacing: 6) {
            Text("Your Portfolio Summary")
                .foregroundColor(.white)
                .font(.headline)
            
            Text("$\(viewModel.portfolioValue, specifier: "%.2f")")
                .foregroundColor(.white)
                .font(.system(size: 36, weight: .bold))
            
            Text("24h Change: \(viewModel.dailyChangePercentage, specifier: "%.2f")%")
                .foregroundColor(viewModel.dailyChangePercentage >= 0 ? .green : .red)
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
    }
    
    @ViewBuilder
    private var sparklineView: some View {
        if #available(iOS 16, *) {
            let color = viewModel.dailyChangePercentage >= 0 ? Color.green : Color.red
            Chart {
                // Area fill
                ForEach(currentSparklineData) { point in
                    AreaMark(
                        x: .value("Day", point.day),
                        y: .value("Price", point.price)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [color.opacity(0.3), color.opacity(0.0)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                // Line on top
                ForEach(currentSparklineData) { point in
                    LineMark(
                        x: .value("Day", point.day),
                        y: .value("Price", point.price)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(color)
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: 80)
        } else {
            Text("Sparkline requires iOS 16+")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
    
    private var aiInsightSection: some View {
        VStack(spacing: 6) {
            Text("AI Insight")
                .foregroundColor(.white)
                .font(.headline)
            
            Text("Your portfolio rose 2.3% in the last 24 hours. Tap below for a deeper AI analysis.")
                .foregroundColor(.white.opacity(0.9))
                .font(.subheadline)
                .multilineTextAlignment(.center)
            
            Button(action: {
                showAnalysisSheet = true
            }) {
                Text("View Full Analysis")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
    }
    
    // AI analysis sheet
    private var aiAnalysisSheet: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                // handle at top
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.gray)
                    .frame(width: 40, height: 4)
                    .padding(.top, 8)
                    .padding(.bottom, 6)
                
                Text("AI Portfolio Analysis")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Divider().background(Color.white.opacity(0.2))
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(aiAnalysisPoints, id: \.self) { point in
                            HStack(alignment: .top, spacing: 6) {
                                Text("•")
                                    .foregroundColor(.white)
                                Text(point)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                    }
                    .padding()
                }
                
                Spacer()
            }
        }
        .presentationDragIndicator(.visible)
    }
    
    // MARK: 4. Market Stats
    private var marketStatsContainer: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Market Stats")
                .foregroundColor(.white)
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(marketStats, id: \.title) { stat in
                    VStack(spacing: 4) {
                        Text(stat.title)
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(stat.value)
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(8)
                }
            }
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: 5. Quick Actions
    private var quickActionsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                quickActionButton(label: "Connect", icon: "link.circle") {}
                quickActionButton(label: "Trade",   icon: "arrow.left.arrow.right.circle") {}
                quickActionButton(label: "AI Chat", icon: "bubble.left.and.bubble.right.fill") {}
                quickActionButton(label: "Swap",    icon: "arrow.2.squarepath") {}
                quickActionButton(label: "Staking", icon: "lock.shield") {}
            }
            .padding(.horizontal, 16)
        }
    }
    
    private func quickActionButton(label: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.white)
                Text(label)
                    .font(.caption)
                    .foregroundColor(.white)
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(8)
        }
    }
    
    // MARK: 6. Trending
    private var trendingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Trending")
                .foregroundColor(.white)
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    // In real usage, you'd have actual coin data from viewModel
                    ForEach(viewModel.trending, id: \.self) { coinName in
                        trendingCoinCard(coinName: coinName)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(.horizontal, 16)
    }
    
    private func trendingCoinCard(coinName: String) -> some View {
        // Hardcode or map real data if needed
        let details = (0.46, -3.16)
        return VStack(alignment: .leading, spacing: 6) {
            Circle()
                .fill(Color.blue)
                .frame(width: 24, height: 24)
            
            Text(coinName)
                .font(.subheadline)
                .bold()
                .foregroundColor(.white)
            Text("$\(details.0, specifier: "%.3f")")
                .font(.caption)
                .foregroundColor(.white)
            Text("\(details.1, specifier: "%.2f")%")
                .font(.caption2)
                .foregroundColor(details.1 >= 0 ? .green : .red)
        }
        .frame(width: 90, height: 100, alignment: .topLeading)
        .padding(8)
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: 7. Watchlist (strings from viewModel)
    private var watchlistSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Watchlist")
                .foregroundColor(.white)
                .font(.headline)
            
            VStack(spacing: 0) {
                ForEach(viewModel.watchlist, id: \.self) { coin in
                    watchlistRow(coin: coin)
                    Divider().background(Color.white.opacity(0.1))
                }
            }
            .background(Color.white.opacity(0.05))
            .cornerRadius(8)
        }
        .padding(.horizontal, 16)
    }
    
    private func watchlistRow(coin: String) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.gray)
                .frame(width: 24, height: 24)
            
            Text(coin)
                .font(.subheadline)
                .bold()
                .foregroundColor(.white)
            
            Spacer()
            // Price placeholder
            Text("...")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }
    
    // MARK: 8. Top Gainers
    private var topGainersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Gainers")
                .foregroundColor(.white)
                .font(.headline)
            
            VStack(spacing: 0) {
                ForEach(sampleTopGainers) { coin in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.purple)
                            .frame(width: 24, height: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(coin.symbol)
                                .font(.subheadline)
                                .bold()
                                .foregroundColor(.white)
                            Rectangle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 50, height: 8)
                                .cornerRadius(4)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("$\(coin.price, specifier: "%.2f")")
                                .font(.subheadline)
                                .foregroundColor(.white)
                            Text("\(coin.change24h, specifier: "%.2f")%")
                                .font(.caption)
                                .foregroundColor(coin.change24h >= 0 ? .green : .red)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    Divider().background(Color.white.opacity(0.1))
                }
            }
            .background(Color.white.opacity(0.05))
            .cornerRadius(8)
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: 9. Top Losers
    private var topLosersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Losers")
                .foregroundColor(.white)
                .font(.headline)
            
            VStack(spacing: 0) {
                ForEach(topLosers) { coin in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 24, height: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(coin.symbol)
                                .font(.subheadline)
                                .bold()
                                .foregroundColor(.white)
                            Rectangle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 50, height: 8)
                                .cornerRadius(4)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("$\(coin.price, specifier: "%.2f")")
                                .font(.subheadline)
                                .foregroundColor(.white)
                            Text("\(coin.change24h, specifier: "%.2f")%")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    Divider().background(Color.white.opacity(0.1))
                }
            }
            .background(Color.white.opacity(0.05))
            .cornerRadius(8)
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: 10. Arbitrage
    private var arbitrageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Arbitrage Opportunities")
                .foregroundColor(.white)
                .font(.headline)
            
            Text("Find price differences across exchanges for potential profit.")
                .foregroundColor(.white.opacity(0.9))
                .font(.subheadline)
            
            VStack(spacing: 0) {
                ForEach(arbitrageData, id: \.0) { (pair, exA, exB, profit) in
                    HStack(spacing: 8) {
                        Text(pair)
                            .font(.subheadline)
                            .foregroundColor(.white)
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(exA)
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text(exB)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Text(profit)
                            .font(.subheadline)
                            .foregroundColor(.green)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    Divider().background(Color.white.opacity(0.1))
                }
            }
            .background(Color.white.opacity(0.05))
            .cornerRadius(8)
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: 11. Events
    private var eventsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Events Calendar")
                .foregroundColor(.white)
                .font(.headline)
            
            Text("Stay updated on upcoming crypto events.")
                .foregroundColor(.white.opacity(0.9))
                .font(.subheadline)
            
            VStack(spacing: 0) {
                ForEach(events, id: \.0) { (title, date, desc) in
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .foregroundColor(.white)
                            .font(.caption)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(title)
                                .font(.subheadline)
                                .foregroundColor(.white)
                            Text("\(date) - \(desc)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    Divider().background(Color.white.opacity(0.1))
                }
            }
            .background(Color.white.opacity(0.05))
            .cornerRadius(8)
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: 12. Explore
    private var exploreSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Explore")
                .foregroundColor(.white)
                .font(.headline)
            
            Text("Discover advanced AI and market features.")
                .foregroundColor(.white.opacity(0.9))
                .font(.subheadline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    exploreCard(title: "AI Market Scan", description: "Find top altcoins with potential.")
                    exploreCard(title: "DeFi Analytics", description: "Monitor yields, track TVL.")
                    exploreCard(title: "NFT Explorer", description: "Discover trending collections.")
                    exploreCard(title: "AI Signals", description: "Real-time buy/sell signals.")
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(.horizontal, 16)
    }
    
    private func exploreCard(title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .bold()
                .foregroundColor(.white)
            Text(description)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(2)
        }
        .frame(width: 140, height: 80, alignment: .topLeading)
        .padding(8)
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: 13. Featured Articles
    private var featuredArticlesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Featured Articles")
                .foregroundColor(.white)
                .font(.headline)
            
            Text("Deep dives into the crypto world.")
                .foregroundColor(.white.opacity(0.9))
                .font(.subheadline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    featuredArticleCard(title: "Why BTC might hit $100K", subtitle: "A deep analysis by AI")
                    featuredArticleCard(title: "DeFi 2.0: The Next Wave", subtitle: "New protocols leading the charge")
                    featuredArticleCard(title: "Metaverse or Hype?", subtitle: "Exploring real utility of NFTs")
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(.horizontal, 16)
    }
    
    private func featuredArticleCard(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 200, height: 100)
                .cornerRadius(8)
            
            Text(title)
                .font(.subheadline)
                .bold()
                .foregroundColor(.white)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(2)
        }
        .frame(width: 200)
        .padding(8)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
    
    // MARK: 14. Recent Transactions
    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Transactions")
                .foregroundColor(.white)
                .font(.headline)
            
            VStack(spacing: 0) {
                ForEach(recentTransactions, id: \.0) { (title, amount, fiat, time) in
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.up.arrow.down")
                            .foregroundColor(.white)
                            .font(.caption)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(title)
                                .font(.subheadline)
                                .foregroundColor(.white)
                            Text(time)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(amount)
                                .font(.subheadline)
                                .foregroundColor(.white)
                            if fiat != "N/A" {
                                Text(fiat)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    Divider().background(Color.white.opacity(0.1))
                }
            }
            .background(Color.white.opacity(0.05))
            .cornerRadius(8)
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: 15. News
    private var newsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Latest Crypto News")
                .foregroundColor(.white)
                .font(.headline)
            
            VStack(spacing: 0) {
                ForEach(viewModel.newsHeadlines.indices, id: \.self) { index in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "circle.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                            .padding(.top, 6)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            // optional image placeholder
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 60, height: 40)
                                .cornerRadius(4)
                            
                            Text(viewModel.newsHeadlines[index])
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                            Button(action: {
                                // open news detail
                            }) {
                                Text("Read more...")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    Divider().background(Color.white.opacity(0.1))
                }
            }
            .background(Color.white.opacity(0.05))
            .cornerRadius(8)
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: 16. Social
    private var socialSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Community & Social")
                .foregroundColor(.white)
                .font(.headline)
            
            Text("Join our Discord, follow us on Twitter, or vote on community proposals.")
                .foregroundColor(.white.opacity(0.9))
                .font(.subheadline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    socialCard(title: "Discord", icon: "bubble.left.and.bubble.right.fill", description: "Chat with the community.")
                    socialCard(title: "Twitter", icon: "bird.fill", description: "Follow for updates.")
                    socialCard(title: "Governance", icon: "checkmark.seal.fill", description: "Vote on proposals.")
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(.horizontal, 16)
    }
    
    private func socialCard(title: String, icon: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundColor(.white)
            Text(title)
                .font(.subheadline)
                .bold()
                .foregroundColor(.white)
            Text(description)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(2)
        }
        .frame(width: 120, height: 80, alignment: .topLeading)
        .padding(8)
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: 17. Footer disclaimers
    private var footerDisclaimer: some View {
        VStack(alignment: .center, spacing: 6) {
            Text("CryptoSage AI v1.0.0 (Beta)")
                .font(.caption2)
                .foregroundColor(.gray)
            Text("All information is provided as-is and not guaranteed to be accurate. Not financial advice.")
                .font(.caption2)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(.bottom, 30)
    }
}
