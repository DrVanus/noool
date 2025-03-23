import SwiftUI

// MARK: - Gold Button Style

/// A unified gold button style with black text, used for primary CTAs.
struct CSGoldButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .foregroundColor(.black)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
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
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.25), radius: 3, x: 0, y: 2)
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

// MARK: - Home Line Chart

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
                
                // Filled area under the chart
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
                // Fallback when data is empty or not enough to chart
                Text("No Chart Data")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

// MARK: - Home View

/**
 NOTE:
 This file creates its own MarketViewModel instance via `@StateObject private var marketVM`.
 If your Market page is also creating a different MarketViewModel or using @EnvironmentObject,
 changes to favorites on the Market page won't appear in this watchlist.
 
 To share favorites, remove this local instance and reference the same model (e.g. @EnvironmentObject).
 */
struct HomeView: View {
    @State private var selectedRange: HomeTimeRange = .week
    @State private var portfolioData: [Double] = [1, 2, 3, 2.5, 4, 3.7]
    
    // This is a local instance. Not shared with the Market page.
    @StateObject private var marketVM = MarketViewModel()
    @State private var showAllWatchlist = false
    
    // For a hypothetical Fear & Greed gauge:
    @State private var fearGreedValue: Double = 54
    
    // Computed live data subsets:
    private var liveWatchlist: [MarketCoin] {
        marketVM.coins.filter { $0.isFavorite }
    }
    
    private var liveTrending: [MarketCoin] {
        Array(marketVM.coins.sorted { $0.volume > $1.volume }.prefix(3))
    }
    
    private var liveTopGainers: [MarketCoin] {
        Array(marketVM.coins.sorted { $0.dailyChange > $1.dailyChange }.prefix(3))
    }
    
    private var liveTopLosers: [MarketCoin] {
        Array(marketVM.coins.sorted { $0.dailyChange < $1.dailyChange }.prefix(3))
    }
    
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
    
    // Helper for loading a coin’s icon from its URL.
    private func coinIconView(for coin: MarketCoin, size: CGFloat) -> some View {
        Group {
            if let imageUrl = coin.imageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable()
                             .scaledToFill()
                             .frame(width: size, height: size)
                             .clipShape(Circle())
                    } else if phase.error != nil {
                        Circle().fill(Color.gray.opacity(0.3))
                            .frame(width: size, height: size)
                    } else {
                        ProgressView().frame(width: size, height: size)
                    }
                }
            } else {
                Circle().fill(Color.gray.opacity(0.3))
                    .frame(width: size, height: size)
            }
        }
    }
    
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
    
    // MARK: Portfolio Summary
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
            
            // Time Range Picker
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
                
                Button("View Full Analysis") {
                    // Action here
                }
                .buttonStyle(CSGoldButtonStyle())
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
    
    // MARK: Watchlist Section
    private var watchlistSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeading("Your Watchlist", iconName: "eye")
            
            let coinsToShow = showAllWatchlist ? liveWatchlist : Array(liveWatchlist.prefix(3))
            ForEach(coinsToShow) { coin in
                NavigationLink(destination: CoinDetailView(coin: coin)) {
                    HStack {
                        coinIconView(for: coin, size: 24)
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
            if liveWatchlist.count > 3 {
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
    
    // MARK: Market Stats Section
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
    
    // MARK: Fear & Greed Section
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
    
    // MARK: AI & Invite Section
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
                Button("Scan Now") {}
                    .buttonStyle(CSGoldButtonStyle())
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
                        .foregroundColor(.yellow)
                    Text("Invite & Earn BTC")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                Text("Refer friends, get rewards.")
                    .font(.caption)
                    .foregroundColor(.gray)
                Button("Invite Now") {}
                    .buttonStyle(CSGoldButtonStyle())
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
    
    // MARK: Trending Section
    private var trendingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeading("Trending", iconName: "flame")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(liveTrending) { coin in
                        NavigationLink(destination: CoinDetailView(coin: coin)) {
                            VStack(spacing: 4) {
                                coinIconView(for: coin, size: 32)
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
    
    // MARK: Top Movers Section
    private var topMoversSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeading("Top Gainers", iconName: "arrow.up.right")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(liveTopGainers) { coin in
                        NavigationLink(destination: CoinDetailView(coin: coin)) {
                            VStack(spacing: 4) {
                                coinIconView(for: coin, size: 24)
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
                    ForEach(liveTopLosers) { coin in
                        NavigationLink(destination: CoinDetailView(coin: coin)) {
                            VStack(spacing: 4) {
                                coinIconView(for: coin, size: 24)
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
    
    // MARK: Arbitrage Section
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
    
    // MARK: Events Section
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
    
    // MARK: Explore Section
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
    
    // MARK: News Section
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
    
    // MARK: Transactions Section
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
    
    // MARK: Community Section
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
    
    // MARK: Footer Section
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
    
    // MARK: Generate Portfolio Data
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
        // Using a local MarketViewModel in the preview, matching the real view
        HomeView()
            .preferredColorScheme(.dark)
    }
}
