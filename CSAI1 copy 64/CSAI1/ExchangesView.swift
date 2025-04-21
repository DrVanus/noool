import SwiftUI
import UIKit

// MARK: - ExchangeItem Model
struct ExchangeItem: Identifiable {
    let id = UUID()
    let name: String
}

// MARK: - Sample Data
private let sampleExchanges: [ExchangeItem] = [
    ExchangeItem(name: "Binance"),
    ExchangeItem(name: "Binance US"),
    ExchangeItem(name: "Coinbase Pro"),
    ExchangeItem(name: "Kraken"),
    ExchangeItem(name: "KuCoin"),
    ExchangeItem(name: "Bitstamp"),
    ExchangeItem(name: "Poloniex"),
    ExchangeItem(name: "Bittrex"),
    ExchangeItem(name: "OKX"),
    ExchangeItem(name: "Huobi"),
    ExchangeItem(name: "Gemini"),
    ExchangeItem(name: "Gate.io"),
    ExchangeItem(name: "BitMEX"),
    ExchangeItem(name: "Bybit"),
    ExchangeItem(name: "Deribit"),
    ExchangeItem(name: "Binance Futures")
]

private let sampleWallets: [ExchangeItem] = [
    ExchangeItem(name: "MetaMask"),
    ExchangeItem(name: "Trust Wallet"),
    ExchangeItem(name: "Rainbow"),
    ExchangeItem(name: "Exodus"),
    ExchangeItem(name: "Ledger Live"),
    ExchangeItem(name: "Trezor")
]

// MARK: - Logo Maps
private let brandLogoMap: [String: String] = [
    "Binance": "binanceLogo",
    "Binance US": "binanceUSLogo",
    "Coinbase Pro": "coinbaseProLogo",
    "Kraken": "krakenLogo",
    "KuCoin": "kucoinLogo",
    "Bitstamp": "bitstampLogo",
    "Poloniex": "poloniexLogo",
    "Bittrex": "bittrexLogo",
    "OKX": "okxLogo",
    "Huobi": "huobiLogo",
    "Gemini": "geminiLogo",
    "Gate.io": "gateLogo",
    "BitMEX": "bitmexLogo",
    "Bybit": "bybitLogo",
    "Deribit": "deribitLogo",
    "Binance Futures": "binanceFuturesLogo"
]

private let walletLogoMap: [String: String] = [
    "MetaMask": "metamaskLogo",
    "Trust Wallet": "trustWalletLogo",
    "Rainbow": "rainbowLogo",
    "Exodus": "exodusLogo",
    "Ledger Live": "ledgerLiveLogo",
    "Trezor": "trezorLogo"
]

// MARK: - ExchangesView
struct ExchangesView: View {
    @Environment(\.presentationMode) var presentationMode
    
    // Toggle search bar visibility and hold search text
    @State private var showSearch = false
    @State private var searchText = ""
    
    // Two-column grid layout with comfortable spacing
    private let columns = [
        GridItem(.flexible(minimum: 140), spacing: 20),
        GridItem(.flexible(minimum: 140), spacing: 20)
    ]
    
    // Filtered lists
    private var filteredExchanges: [ExchangeItem] {
        sampleExchanges.filter {
            searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var filteredWallets: [ExchangeItem] {
        sampleWallets.filter {
            searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        ZStack {
            // Your futuristic background or gradient
            FuturisticBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Custom Top Bar (single title)
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("Exchanges & Wallets")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            showSearch.toggle()
                            if !showSearch { searchText = "" }
                        }
                    }) {
                        Image(systemName: showSearch ? "xmark.circle.fill" : "magnifyingglass")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                // Simple background instead of blur
                .background(Color.black.opacity(0.2))
                
                // MARK: - Search Bar
                if showSearch {
                    HStack {
                        TextField("Search", text: $searchText)
                            .padding(10)
                            .foregroundColor(.white)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                            .overlay(
                                HStack {
                                    Spacer()
                                    if !searchText.isEmpty {
                                        Button(action: { searchText = "" }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.white.opacity(0.7))
                                                .padding(.trailing, 8)
                                        }
                                    }
                                }
                            )
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // MARK: - Main Scroll Content
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // Exchanges Section
                        Text("Exchanges")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.leading, 16)
                            .padding(.top, 16)
                        
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(filteredExchanges) { exchange in
                                ExchangeGridCard(
                                    name: exchange.name,
                                    logo: brandLogoMap[exchange.name]
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        // Wallets Section
                        Text("Wallets")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.leading, 16)
                            .padding(.top, 16)
                        
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(filteredWallets) { wallet in
                                ExchangeGridCard(
                                    name: wallet.name,
                                    logo: walletLogoMap[wallet.name]
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        // Hide default navigation bar so no second title appears
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - ExchangeGridCard
struct ExchangeGridCard: View {
    let name: String
    let logo: String?
    
    var body: some View {
        ZStack {
            // Card background (same gradient style as in your other screens)
            LinearGradient(
                gradient: Gradient(colors: [
                    Color("BrandPrimary").opacity(0.5),
                    Color("BrandSecondary").opacity(0.5)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 8) {
                // Display logo or fallback icon
                if let logoName = logo, !logoName.isEmpty {
                    Image(logoName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                } else {
                    Image(systemName: "questionmark.circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Text(name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Spacer()
                
                // Navigate to your ExchangeConnectionView
                HStack {
                    Spacer()
                    NavigationLink(destination: ExchangeConnectionView()) {
                        Text("Connect")
                            .font(.footnote)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.35))
                            .cornerRadius(8)
                    }
                }
            }
            .padding(12)
        }
        .frame(height: 130)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 4)
        .scaleEffect(0.98)
        .animation(.easeInOut, value: name)
    }
}

// MARK: - Preview
struct ExchangesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ExchangesView()
        }
    }
}
