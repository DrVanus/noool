//
//  HomeView.swift
//  CSAI1
//
//  Created by ChatGPT on 3/27/25
//

import SwiftUI
import SafariServices
import Combine


/// A reusable heading with optional icon.
struct SectionHeading: View {
    let text: String
    let iconName: String?

    var body: some View {
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
}


// MARK: - Crypto News ViewModel
// (Old CoinStats news VM removed; use CryptoNewsFeedViewModel instead)

// MARK: - News Models
// NewsArticle and NewsPreviewRow are likely replaced by RSS model/row elsewhere.

// MARK: - Gold Button Style
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
                        Color(red: 1.0, green: 0.84, blue: 0.0),
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

 

// MARK: - (Optional) HomeLineChart
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

// MARK: - CoinCardView
struct CoinCardView: View {
    let coin: MarketCoin

    var body: some View {
        VStack(spacing: 6) {
            coinIconView(for: coin, size: 32)

            Text(coin.symbol.uppercased())
                .font(.headline)
                .foregroundColor(.white)
                .lineLimit(1)

            Text(formatPrice(coin.price))
                .font(.subheadline)
                .foregroundColor(.white)
                .lineLimit(1)

            Text("\(coin.dailyChange, specifier: "%.2f")%")
                .font(.caption)
                .foregroundColor(coin.dailyChange >= 0 ? .green : .red)
        }
        .frame(width: 90, height: 120)
        .padding(6)
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
    }

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

    private func formatPrice(_ value: Double) -> String {
        guard value > 0 else { return "$0.00" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        if value < 1.0 {
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 8
        } else {
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 2
        }
        return "$" + (formatter.string(from: NSNumber(value: value)) ?? "0.00")
    }
}

// MARK: - HomeView
struct HomeView: View {
    @StateObject private var notificationsManager = NotificationsManager.shared
    @StateObject private var homeVM = HomeViewModel()
    @StateObject private var newsVM = CryptoNewsFeedViewModel()

    @State private var showSettings = false
    @State private var showNotifications = false
    @State private var isEditingWatchlist = false  // For reordering

    @State private var selected: HeatMapTile?

    var body: some View {
        NavigationView {
            ZStack {
                FuturisticBackground()
                    .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    homeContentStack
                }
                .background(Color.black)
                .scrollContentBackground(.hidden)
            }
            .background(Color.black)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .accentColor(.white)
        
        .onAppear {
            homeVM.newsVM.loadPreview()
            newsVM.loadPreview()
        }
        .sheet(isPresented: $showNotifications) {
            NotificationsView()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }

    @ViewBuilder
    private var contentScrollView: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                homeContentStack
            }
        }
        .background(Color.black)
        .scrollContentBackground(.hidden)
    }

    @ViewBuilder
    private var homeContentStack: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Portfolio summary / chart
            ZStack(alignment: .topTrailing) {
                PortfolioChartView(portfolioVM: homeVM.portfolioVM)
                HStack(spacing: 20) {
                    Button(action: { showNotifications = true }) {
                        Image(systemName: "bell")
                            .foregroundColor(.white)
                    }
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape")
                            .foregroundColor(.white)
                    }
                }
                .padding(12)
            }

            // All the existing section subviews in order:
            aiInsightSection
            WatchlistSectionView(isEditingWatchlist: $isEditingWatchlist)
                .environmentObject(homeVM.marketVM)
            marketStatsSection
            MarketSentimentView().frame(maxWidth: .infinity)
            MarketHeatMapSection()
                .padding(.horizontal, 16)
            aiAndInviteSection
            trendingSection
            topMoversSection
            arbitrageSection
            eventsSection
            exploreSection

            // MARK: - Latest Crypto News Preview
            SectionHeading(text: "Latest Crypto News", iconName: "newspaper")
                .padding(.horizontal, 16)

            VStack(spacing: 8) {
                if newsVM.displayedArticles.isEmpty {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                } else {
                    ForEach(newsVM.displayedArticles.prefix(3)) { article in
                        CryptoNewsRow(article: article)
                            .environmentObject(newsVM)
                            .onTapGesture { openSafari(article.url) }
                    }
                }
            }
            .environmentObject(newsVM)
            .padding(.horizontal, 16)

            HStack {
                NavigationLink(destination: AllCryptoNewsView().environmentObject(newsVM)) {
                    Text("See All News")
                        .font(.body)
                        .foregroundColor(.yellow)
                }
                Spacer()
            }
            .padding(.horizontal, 16)

            transactionsSection
            communitySection
            footer
        }
    }

}

// MARK: - HomeView Subviews (Extension)
extension HomeView {

    // AI Insight block
    private var aiInsightSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeading(text: "AI Insight", iconName: "brain.head.profile")
            Text("Your portfolio is trending upward, with BTC leading gains. Consider reviewing your ETH exposure.")
                .font(.body)
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
            Button(action: {
                // Action to view full AI analysis
            }) {
                Text("View Full Analysis")
            }
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

    // Market Stats Section
    private var marketStatsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeading(text: "Market Stats", iconName: "chart.bar")
            let columns = [
                GridItem(.adaptive(minimum: 120), spacing: 16)
            ]
            LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                statCell(title: "Global Market Cap", value: homeVM.marketVM.globalMarketCapFormatted, icon: "globe")
                statCell(title: "24h Volume", value: homeVM.marketVM.volume24hFormatted, icon: "clock")
                statCell(title: "BTC Dominance", value: homeVM.marketVM.btcDominanceFormatted, icon: "bitcoinsign.circle")
                statCell(title: "ETH Dominance", value: homeVM.marketVM.ethDominanceFormatted, icon: "chart.bar.xaxis")
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

    // AI & Invite Section
    private var aiAndInviteSection: some View {
        HStack(spacing: 12) {
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

    // Trending Section
    private var trendingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeading(text: "Trending", iconName: "flame")
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(homeVM.liveTrending) { coin in
                        NavigationLink(destination: CoinDetailView(coin: coin)) {
                            CoinCardView(coin: coin)
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

    // Top Movers Section
    private var topMoversSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeading(text: "Top Gainers", iconName: "arrow.up.right")
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(homeVM.liveTopGainers) { coin in
                        NavigationLink(destination: CoinDetailView(coin: coin)) {
                            CoinCardView(coin: coin)
                        }
                    }
                }
                .padding(.vertical, 6)
            }

            SectionHeading(text: "Top Losers", iconName: "arrow.down.right")
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(homeVM.liveTopLosers) { coin in
                        NavigationLink(destination: CoinDetailView(coin: coin)) {
                            CoinCardView(coin: coin)
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

    // Arbitrage Section
    private var arbitrageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeading(text: "Arbitrage Opportunities", iconName: "arrow.left.and.right.circle")
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

    // Events Section
    private var eventsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeading(text: "Events Calendar", iconName: "calendar")
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

    // Explore Section
    private var exploreSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeading(text: "Explore", iconName: "magnifyingglass")
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


    // Transactions Section
    private var transactionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeading(text: "Recent Transactions", iconName: "clock.arrow.circlepath")
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

    // Community Section
    private var communitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeading(text: "Community & Social", iconName: "person.3.fill")
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

    // Footer
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


    // Stat Cell Helper
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


    // Format Price Helper
    private func formatPrice(_ value: Double) -> String {
        guard value > 0 else { return "$0.00" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        if value < 1.0 {
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 8
        } else {
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 2
        }
        return "$" + (formatter.string(from: NSNumber(value: value)) ?? "0.00")
    }
}








    /// Present a SFSafariViewController over the root window.
    private func openSafari(_ url: URL) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else {
            return
        }
        let safari = SFSafariViewController(url: url)
        safari.modalPresentationStyle = .fullScreen
        root.present(safari, animated: true)
    }
