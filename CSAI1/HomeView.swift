import SwiftUI

// MARK: - Gradient Button Style

/// A versatile gradient button style (white text by default).
struct GradientButtonStyle: ButtonStyle {
    var gradient: Gradient
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .foregroundColor(.white)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(
                LinearGradient(gradient: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(), value: configuration.isPressed)
    }
}

// MARK: - Gold Button Style

/// A gold button style with black text, to stand out on a dark background.
struct GoldButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .foregroundColor(.black)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red:1.0, green:0.84, blue:0.0), // bright gold
                        Color.orange
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(8)
            .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 2)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(), value: configuration.isPressed)
    }
}

// MARK: - Time Range Enum

enum HomeTimeRange: String, CaseIterable {
    case day = "1D"
    case week = "1W"
    case month = "1M"
    case threeMonth = "3M"
    case year = "1Y"
    case all = "ALL"
}

// MARK: - Line Chart

struct HomeLineChart: View {
    let data: [Double]
    
    var body: some View {
        GeometryReader { geo in
            if data.count > 1,
               let minVal = data.min(),
               let maxVal = data.max(),
               maxVal > minVal {
                
                let range = maxVal - minVal
                Path { path in
                    for (index, value) in data.enumerated() {
                        let xPos = geo.size.width * CGFloat(index) / CGFloat(data.count - 1)
                        let yPos = geo.size.height * (1 - CGFloat((value - minVal) / range))
                        if index == 0 {
                            path.move(to: CGPoint(x: xPos, y: yPos))
                        } else {
                            path.addLine(to: CGPoint(x: xPos, y: yPos))
                        }
                    }
                }
                .stroke(Color.green, lineWidth: 2)
                
                Path { path in
                    for (index, value) in data.enumerated() {
                        let xPos = geo.size.width * CGFloat(index) / CGFloat(data.count - 1)
                        let yPos = geo.size.height * (1 - CGFloat((value - minVal) / range))
                        if index == 0 {
                            path.move(to: CGPoint(x: xPos, y: geo.size.height))
                            path.addLine(to: CGPoint(x: xPos, y: yPos))
                        } else {
                            path.addLine(to: CGPoint(x: xPos, y: yPos))
                        }
                    }
                    path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                    path.closeSubpath()
                }
                .fill(Color.green.opacity(0.2))
            } else {
                Text("No Chart Data")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

// MARK: - Home View

struct HomeView: View {
    @State private var selectedRange: HomeTimeRange = .week
    @State private var portfolioData: [Double] = [1, 2, 3, 2.5, 4, 3.7]
    
    @State private var watchlistCoins: [MarketCoin] = [
        MarketCoin(symbol: "BTC", name: "Bitcoin", price: 28000, dailyChange: 2.12, volume: 22000000, sparklineData: [], imageUrl: nil),
        MarketCoin(symbol: "ETH", name: "Ethereum", price: 1800, dailyChange: -1.01, volume: 10500000, sparklineData: [], imageUrl: nil),
        MarketCoin(symbol: "SOL", name: "Solana", price: 20.50, dailyChange: 0.43, volume: 850000, sparklineData: [], imageUrl: nil)
    ]
    @State private var showAllWatchlist = false
    
    @State private var trendingCoins: [MarketCoin] = [
        MarketCoin(symbol: "XRP", name: "XRP", price: 0.460, dailyChange: -3.16, volume: 2500000, sparklineData: [], imageUrl: nil),
        MarketCoin(symbol: "DOGE", name: "Dogecoin", price: 0.082, dailyChange: -2.42, volume: 1200000, sparklineData: [], imageUrl: nil),
        MarketCoin(symbol: "ADA", name: "Cardano", price: 0.36, dailyChange: -1.25, volume: 980000, sparklineData: [], imageUrl: nil)
    ]
    
    @State private var topGainers: [MarketCoin] = [
        MarketCoin(symbol: "FARTCOIN", name: "FARTCOIN", price: 0.30, dailyChange: 23.93, volume: 10000, sparklineData: [], imageUrl: nil),
        MarketCoin(symbol: "VIRTUAL", name: "Virtual", price: 19.88, dailyChange: 12.76, volume: 60000, sparklineData: [], imageUrl: nil),
        MarketCoin(symbol: "HYPE", name: "Hype", price: 14.70, dailyChange: 12.05, volume: 40000, sparklineData: [], imageUrl: nil)
    ]
    
    @State private var topLosers: [MarketCoin] = [
        MarketCoin(symbol: "LOSERCOIN", name: "LoserCoin", price: 0.002, dailyChange: -14.56, volume: 12000, sparklineData: [], imageUrl: nil),
        MarketCoin(symbol: "BEAR", name: "Bear", price: 1.45, dailyChange: -9.88, volume: 22000, sparklineData: [], imageUrl: nil),
        MarketCoin(symbol: "DROPS", name: "Drops", price: 1.94, dailyChange: -8.14, volume: 5000, sparklineData: [], imageUrl: nil)
    ]
    
    // For a hypothetical Fear & Greed gauge
    @State private var fearGreedValue: Double = 54
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color.gray.opacity(0.25)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            NavigationView {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        greetingSection
                        portfolioSummarySection
                        watchlistSection
                            .animation(.spring(), value: showAllWatchlist)
                        marketStatsSection
                        fearGreedSection
                        aiAndInviteSection
                        trendingSection
                        topMoversSection
                        arbitrageSection
                        eventsSection
                        exploreSection
                        newsSection
                        transactionsSection
                        communitySection
                        footer
                    }
                    .padding(.horizontal)
                    .padding(.top)
                }
                .navigationTitle("Home")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {}) {
                            Image(systemName: "line.3.horizontal")
                                .foregroundColor(.white)
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {}) {
                            Image(systemName: "bell")
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
}

// MARK: - Extensions

extension HomeView {
    
    // MARK: Section Heading
    private func sectionHeading(_ text: String, iconName: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                if let icon = iconName {
                    Image(systemName: icon)
                        .foregroundColor(.yellow)
                }
                Text(text)
                    .font(.title3).bold()
                    .foregroundColor(.white)
            }
            Divider()
                .background(Color.white.opacity(0.15))
        }
    }
    
    // MARK: Greeting
    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Hello, User!")
                .font(.title2).bold()
                .foregroundColor(.white)
            Text("Level 3 Trader")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 2)
    }
    
    // MARK: Portfolio
    private var portfolioSummarySection: some View {
        VStack(spacing: 12) {
            sectionHeading("Your Portfolio Summary", iconName: "briefcase.fill")
            
            // Portfolio Value
            Text("$65,000.00")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
            Text("24h Change: 2.34%")
                .font(.subheadline)
                .foregroundColor(.green)
            
            // Chart
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.05))
                HomeLineChart(data: portfolioData)
                    .padding(10)
            }
            .frame(height: 150)
            
            // Time Range Picker (moved below chart)
            Picker("", selection: $selectedRange) {
                ForEach(HomeTimeRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(width: 280)
            .onChange(of: selectedRange) { newRange in
                withAnimation {
                    generatePortfolioData(for: newRange)
                }
            }
            
            // AI Insight
            VStack(spacing: 4) {
                Text("AI Insight")
                    .font(.subheadline)
                    .foregroundColor(.white)
                Text("Your portfolio rose 2.3% in the last 24 hours. Tap below for deeper AI analysis.")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                // Use the gold button style for better visibility
                Button("View Full Analysis") {}
                    .buttonStyle(GoldButtonStyle())
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: Watchlist
    private var watchlistSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeading("Your Watchlist", iconName: "eye")
            
            let coinsToShow = showAllWatchlist ? watchlistCoins : Array(watchlistCoins.prefix(3))
            ForEach(coinsToShow) { coin in
                NavigationLink(destination: CoinDetailView(coin: coin)) {
                    HStack {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 24, height: 24)
                        Text(coin.symbol)
                            .font(.subheadline)
                            .foregroundColor(.white)
                        Spacer()
                        Text("$\(coin.price, specifier: "%.2f")")
                            .foregroundColor(.white)
                        Text("\(coin.dailyChange, specifier: "%.2f")%")
                            .foregroundColor(coin.dailyChange >= 0 ? .green : .red)
                    }
                    .padding(.vertical, 4)
                }
            }
            if watchlistCoins.count > 3 {
                Button(showAllWatchlist ? "Show Less" : "Show More") {
                    showAllWatchlist.toggle()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: Market Stats
    private var marketStatsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeading("Market Stats", iconName: "chart.bar")
            
            let columns = [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ]
            LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                statCell(title: "Global Market Cap", value: "$1.2T", icon: "globe")
                statCell(title: "24h Volume", value: "$63.8B", icon: "clock")
                statCell(title: "BTC Dominance", value: "46.3%", icon: "bitcoinsign.circle")
                statCell(title: "ETH Dominance", value: "19.1%", icon: "chart.bar.xaxis")
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
        )
    }
    
    private func statCell(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.white)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
        }
    }
    
    // MARK: Fear & Greed
    private var fearGreedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeading("Market Sentiment", iconName: "exclamationmark.triangle")
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 10)
                        .frame(width: 60, height: 60)
                    Circle()
                        .trim(from: 0, to: CGFloat(fearGreedValue / 100))
                        .stroke(Color.yellow, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                    Text("\(Int(fearGreedValue))")
                        .font(.subheadline).bold()
                        .foregroundColor(.yellow)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Fear & Greed Index: \(Int(fearGreedValue)) (Neutral)")
                        .font(.subheadline)
                        .foregroundColor(.yellow)
                    Text("Data from alternative.me")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: AI & Invite
    private var aiAndInviteSection: some View {
        HStack(spacing: 12) {
            // "AI Risk Scan" Card
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "exclamationmark.shield")
                        .foregroundColor(.green)
                    Text("AI Risk Scan")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                Text("Quickly analyze your portfolio risk.")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Button("Scan Now") {
                    // ...
                }
                .buttonStyle(
                    GradientButtonStyle(
                        gradient: Gradient(colors: [Color.green, Color.blue])
                    )
                )
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.05))
                    .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
            )
            
            // "Invite & Earn BTC" Card
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "gift")
                        .foregroundColor(.blue)
                    Text("Invite & Earn BTC")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                Text("Refer friends, get rewards.")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Button("Invite Now") {
                    // ...
                }
                .buttonStyle(
                    GradientButtonStyle(
                        gradient: Gradient(colors: [Color.blue, Color.purple])
                    )
                )
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.05))
                    .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
            )
        }
    }
    
    // MARK: Trending
    private var trendingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeading("Trending", iconName: "flame")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(trendingCoins) { coin in
                        NavigationLink(destination: CoinDetailView(coin: coin)) {
                            VStack(spacing: 4) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.title3)
                                    .foregroundColor(.white.opacity(0.8))
                                Text(coin.symbol)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text("$\(coin.price, specifier: "%.3f")")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                Text("\(coin.dailyChange, specifier: "%.2f")%")
                                    .font(.caption)
                                    .foregroundColor(coin.dailyChange >= 0 ? .green : .red)
                            }
                            .frame(width: 80, height: 90)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(10)
                        }
                    }
                }
                .padding(.vertical, 6)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: Top Movers
    private var topMoversSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeading("Top Gainers", iconName: "arrow.up.right")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(topGainers) { coin in
                        NavigationLink(destination: CoinDetailView(coin: coin)) {
                            VStack(spacing: 4) {
                                Image(systemName: "arrow.up.right.circle")
                                    .foregroundColor(.green)
                                Text(coin.symbol)
                                    .font(.caption)
                                    .foregroundColor(.white)
                                Text("$\(coin.price, specifier: "%.2f")")
                                    .font(.caption2)
                                    .foregroundColor(.white)
                                Text("\(coin.dailyChange, specifier: "%.2f")%")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                            }
                            .frame(width: 70, height: 75)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(8)
                        }
                    }
                }
            }
            
            sectionHeading("Top Losers", iconName: "arrow.down.right")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(topLosers) { coin in
                        NavigationLink(destination: CoinDetailView(coin: coin)) {
                            VStack(spacing: 4) {
                                Image(systemName: "arrow.down.right.circle")
                                    .foregroundColor(.red)
                                Text(coin.symbol)
                                    .font(.caption)
                                    .foregroundColor(.white)
                                Text("$\(coin.price, specifier: "%.2f")")
                                    .font(.caption2)
                                    .foregroundColor(.white)
                                Text("\(coin.dailyChange, specifier: "%.2f")%")
                                    .font(.caption2)
                                    .foregroundColor(.red)
                            }
                            .frame(width: 70, height: 75)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: Arbitrage
    private var arbitrageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeading("Arbitrage Opportunities", iconName: "arrow.left.and.right.circle")
            Text("Find price differences across exchanges for potential profit.")
                .font(.caption)
                .foregroundColor(.gray)
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("BTC/USDT")
                        .foregroundColor(.white)
                    Text("Ex A: $65,000\nEx B: $66,200\nPotential: $1,200")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                Spacer()
                VStack(alignment: .leading, spacing: 4) {
                    Text("ETH/USDT")
                        .foregroundColor(.white)
                    Text("Ex A: $1,800\nEx B: $1,805\nProfit: $5")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: Events
    private var eventsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeading("Events Calendar", iconName: "calendar")
            Text("Stay updated on upcoming crypto events.")
                .font(.caption)
                .foregroundColor(.gray)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("• ETH2 Hard Fork")
                    .foregroundColor(.white)
                Text("May 30 • Upgrade to reduce fees")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("• DOGE Conference")
                    .foregroundColor(.white)
                Text("June 10 • Global doge event")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("• SOL Hackathon")
                    .foregroundColor(.white)
                Text("June 15 • Dev grants for new apps")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: Explore
    private var exploreSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeading("Explore", iconName: "magnifyingglass")
            Text("Discover advanced AI and market features.")
                .font(.caption)
                .foregroundColor(.gray)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Market Scan")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    Text("Scan market signals, patterns.")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                Spacer()
                VStack(alignment: .leading, spacing: 4) {
                    Text("DeFi Analytics")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    Text("Monitor yields, track TVL.")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                Spacer()
                VStack(alignment: .leading, spacing: 4) {
                    Text("NFT Explorer")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    Text("Browse trending collections.")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: News
    private var newsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeading("Latest Crypto News", iconName: "newspaper")
            newsRow(title: "BTC Approaches $100K")
            newsRow(title: "XRP Gains Legal Clarity")
            newsRow(title: "ETH2 Merge Update")
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
        )
    }
    
    private func newsRow(title: String) -> some View {
        HStack {
            Circle()
                .fill(Color.blue.opacity(0.4))
                .frame(width: 8, height: 8)
            Text(title)
                .foregroundColor(.white)
            Spacer()
            Button(action: {}) {
                HStack(spacing: 4) {
                    Text("Read more...")
                        .font(.caption)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
            }
            .foregroundColor(.blue)
        }
    }
    
    // MARK: Transactions
    private var transactionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeading("Recent Transactions", iconName: "clock.arrow.circlepath")
            transactionRow(action: "Buy BTC", change: "+0.012 BTC", value: "$350", time: "3h ago")
            transactionRow(action: "Sell ETH", change: "-0.05 ETH", value: "$90", time: "1d ago")
            transactionRow(action: "Stake SOL", change: "+10 SOL", value: "", time: "2d ago")
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
        )
    }
    
    private func transactionRow(action: String, change: String, value: String, time: String) -> some View {
        HStack {
            Text(action)
                .foregroundColor(.white)
            Spacer()
            VStack(alignment: .trailing) {
                Text(change)
                    .foregroundColor(change.hasPrefix("-") ? .red : .green)
                if !value.isEmpty {
                    Text(value)
                        .foregroundColor(.gray)
                }
            }
            Text(time)
                .foregroundColor(.gray)
                .font(.caption)
                .frame(width: 50, alignment: .trailing)
        }
    }
    
    // MARK: Community
    private var communitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeading("Community & Social", iconName: "person.3.fill")
            Text("Join our Discord, follow us on Twitter, or vote on community proposals.")
                .font(.caption)
                .foregroundColor(.gray)
            
            HStack(spacing: 16) {
                VStack {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                    Text("Discord")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                VStack {
                    Image(systemName: "bird")
                        .font(.title3)
                        .foregroundColor(.white)
                    Text("Twitter")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                VStack {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                    Text("Governance")
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: Footer
    private var footer: some View {
        VStack(spacing: 4) {
            Text("CryptoSage AI v1.0.0 (Beta)")
                .font(.footnote)
                .foregroundColor(.white.opacity(0.6))
            Text("All information is provided as-is and is not guaranteed to be accurate. Final decisions are your own responsibility.")
                .font(.caption2)
                .foregroundColor(.gray.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: Generate Data
    private func generatePortfolioData(for range: HomeTimeRange) {
        switch range {
        case .day:
            portfolioData = [1, 1.2, 1.1, 1.4, 1.8, 2.0]
        case .week:
            portfolioData = [1, 2, 3, 2.5, 4, 3.7]
        case .month:
            portfolioData = [3, 2, 5, 4, 6, 5]
        case .threeMonth:
            portfolioData = [2, 3, 5, 4, 6, 7, 6, 8]
        case .year:
            portfolioData = [10, 8, 12, 15, 11, 13]
        case .all:
            portfolioData = [1,2,3,2,4,3,5,4,6,5,8,7,9,8,10,9,11,10,12,11]
        }
    }
}

// MARK: - Preview

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .preferredColorScheme(.dark)
    }
}
