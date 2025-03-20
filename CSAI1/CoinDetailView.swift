//
//  CoinDetailView.swift
//  CRYPTOSAI
//
//  A robust coin detail page referencing `MarketCoin` from MarketView.
//  Uses Swift Charts for a time-frame chart (placeholder data). iOS 16+ or comment out the chart code.
//

import SwiftUI
import Charts // comment out if targeting < iOS 16

struct CoinDetailView: View {
    let coin: MarketCoin
    
    // For the time-frame chart
    @State private var chartData: [PricePoint] = []
    @State private var selectedTimeFrame: TimeFrame = .day
    @State private var isLoadingChart: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                
                // MARK: - Header (Icon, Name, Price)
                headerSection
                
                // MARK: - Chart Section (Time frames)
                chartSection
                
                // MARK: - Basic Stats
                basicStatsSection
                
                // MARK: - Additional Stats
                additionalStatsSection
                
                // MARK: - News / AI Insights
                newsSection
                
                // MARK: - Trade Button
                tradeButton
            }
            .padding()
        }
        .background(Color.black.ignoresSafeArea())
        // Show the coin's symbol in the nav title
        .navigationBarTitle(coin.symbol.uppercased(), displayMode: .inline)
        .onAppear {
            // Load placeholder chart data for the default timeframe
            loadChartData(for: selectedTimeFrame)
        }
    }
}

// MARK: - Subviews
extension CoinDetailView {
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 6) {
            
            // Coin Icon
            if let urlStr = coin.imageUrl, let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                    case .failure(_):
                        Circle()
                            .fill(Color.gray.opacity(0.6))
                            .frame(width: 80, height: 80)
                    case .empty:
                        ProgressView()
                            .frame(width: 80, height: 80)
                    @unknown default:
                        Circle()
                            .fill(Color.gray.opacity(0.6))
                            .frame(width: 80, height: 80)
                    }
                }
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.6))
                    .frame(width: 80, height: 80)
            }
            
            // Coin Name
            Text(coin.name)
                .font(.title3)
                .foregroundColor(.white.opacity(0.8))
            
            // Price
            Text("$\(coin.price, specifier: "%.2f")")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
            
            // 24h Change
            Text("\(coin.dailyChange, specifier: "%.2f")% (24h)")
                .font(.headline)
                .foregroundColor(coin.dailyChange >= 0 ? .green : .red)
        }
    }
    
    // MARK: - Chart Section
    private var chartSection: some View {
        VStack(spacing: 12) {
            // Time Frame Buttons
            HStack {
                ForEach(TimeFrame.allCases, id: \.self) { tf in
                    Button(action: {
                        selectedTimeFrame = tf
                        loadChartData(for: tf)
                    }) {
                        Text(tf.rawValue)
                            .font(.caption)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(selectedTimeFrame == tf ? Color.white : Color.white.opacity(0.1))
                            .foregroundColor(selectedTimeFrame == tf ? .black : .white)
                            .cornerRadius(8)
                    }
                }
            }
            
            // The chart itself
            if isLoadingChart {
                ProgressView("Loading chart...")
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .frame(height: 200)
            } else {
                if #available(iOS 16.0, *) {
                    Chart {
                        ForEach(chartData) { point in
                            AreaMark(
                                x: .value("Index", point.index),
                                y: .value("Price", point.price)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [chartColor.opacity(0.3), chartColor.opacity(0.0)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            
                            LineMark(
                                x: .value("Index", point.index),
                                y: .value("Price", point.price)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(chartColor)
                        }
                    }
                    .chartXAxis(.hidden)
                    .chartYAxis(.hidden)
                    .frame(height: 200)
                } else {
                    Text("Charts require iOS 16+")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(height: 200)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
    
    // MARK: - Basic Stats
    private var basicStatsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Basic Stats")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack {
                Text("Volume (24h):")
                    .foregroundColor(.gray)
                Spacer()
                Text(shortVolume(coin.volume))
                    .foregroundColor(.white)
            }
            
            // The next lines are placeholders referencing coin.price +/- random amounts
            // Adjust or remove if you want real open/high/low from the API
            HStack {
                Text("Open (24h):")
                    .foregroundColor(.gray)
                Spacer()
                Text("$\(coin.price - 2, specifier: "%.2f")")
                    .foregroundColor(.white)
            }
            HStack {
                Text("High (24h):")
                    .foregroundColor(.gray)
                Spacer()
                Text("$\(coin.price + 5, specifier: "%.2f")")
                    .foregroundColor(.white)
            }
            HStack {
                Text("Low (24h):")
                    .foregroundColor(.gray)
                Spacer()
                Text("$\(coin.price - 3, specifier: "%.2f")")
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
    
    // MARK: - Additional Stats
    private var additionalStatsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Additional Stats")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("• Market cap, fully diluted valuation, supply, etc.\n• Possibly on-chain metrics.\n• AI-driven fundamental analysis (coming soon).")
                .font(.caption)
                .foregroundColor(.white.opacity(0.9))
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
    
    // MARK: - News / AI Insights
    private var newsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("AI / On-Chain Insights")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("• Potential AI analysis or signals.\n• On-chain metrics, derivatives data, etc.\n• Possibly a news feed or curated headlines.")
                .font(.caption)
                .foregroundColor(.white.opacity(0.9))
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
    
    // MARK: - Trade Button
    private var tradeButton: some View {
        Button {
            // e.g. present a TradeView(coin: coin)
            print("Trade \(coin.symbol) tapped.")
        } label: {
            Text("Trade \(coin.symbol.uppercased())")
                .font(.headline)
                .foregroundColor(.black)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green)
                .cornerRadius(8)
        }
        .padding(.top, 8)
    }
    
    // MARK: - Chart Helpers
    private var chartColor: Color {
        coin.dailyChange >= 0 ? .green : .red
    }
    
    /// Simulates chart data load for the selected timeframe
    private func loadChartData(for tf: TimeFrame) {
        isLoadingChart = true
        // Simulate a 1-second network call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            // Randomly generate 10 points near coin.price
            chartData = (1...10).map { idx in
                PricePoint(index: idx, price: coin.price + Double.random(in: -5...5))
            }
            isLoadingChart = false
        }
    }
    
    // Format volumes
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

// MARK: - Supporting Types
struct PricePoint: Identifiable {
    let id = UUID()
    let index: Int
    let price: Double
}

enum TimeFrame: String, CaseIterable {
    case day = "24H"
    case week = "1W"
    case month = "1M"
    case threeMonth = "3M"
    case sixMonth = "6M"
    case year = "1Y"
    case all = "ALL"
}

// MARK: - Preview
struct CoinDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleCoin = MarketCoin(
            symbol: "BTC",
            name: "Bitcoin",
            price: 27950.0,
            dailyChange: 1.24,
            volume: 450_000_000,
            sparklineData: [27900, 28000, 27880, 28100, 27910, 28050, 28100],
            imageUrl: "https://assets.coingecko.com/coins/images/1/large/bitcoin.png"
        )
        
        NavigationView {
            CoinDetailView(coin: sampleCoin)
        }
        .preferredColorScheme(.dark)
    }
}
