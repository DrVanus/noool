import SwiftUI

/// Displays detailed info about a single coin.
/// Relies on the same MarketCoin struct from MarketView.
struct CoinDetailView: View {
    let coin: MarketCoin
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
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
                    // No image URL
                    Circle()
                        .fill(Color.gray.opacity(0.6))
                        .frame(width: 80, height: 80)
                }
                
                Text(coin.name)
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .padding(.top, 8)
                
                Text(coin.symbol.uppercased())
                    .font(.headline)
                    .foregroundColor(.gray)
                
                // Price
                Text(String(format: "$%.2f", coin.price))
                    .font(.title2)
                    .foregroundColor(.white)
                
                // 24h change
                Text(String(format: "%.2f%% (24h)", coin.dailyChange))
                    .font(.body)
                    .foregroundColor(coin.dailyChange >= 0 ? .green : .red)
                
                // Volume
                Text("Volume: \(shortVolume(coin.volume))")
                    .foregroundColor(.white)
                
                // If you had a 7-day sparkline in coin.sparklineData, you could display it here, etc.
            }
            .padding()
        }
        .background(Color.black.ignoresSafeArea())
        .navigationTitle(coin.name)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // Same shortVolume function from MarketView
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

struct CoinDetailView_Previews: PreviewProvider {
    static var previews: some View {
        // Minimal mock coin
        CoinDetailView(coin: MarketCoin(
            symbol: "BTC",
            name: "Bitcoin",
            price: 28000.0,
            dailyChange: 1.23,
            volume: 450_000_000,
            sparklineData: [],
            imageUrl: "https://assets.coingecko.com/coins/images/1/large/bitcoin.png"
        ))
    }
}
