//
//  PortfolioView.swift
//  CSAI1
//

import SwiftUI
import Charts

// Example brand accent color usage.
// If you don’t have "BrandAccent" in your Assets, replace with a system color.
private let brandAccent = Color("BrandAccent")

// MARK: - PaymentMethodsView Stub
struct PaymentMethodsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Connect Exchanges & Wallets")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            Text("Add or link your crypto exchange accounts and wallets here to trade directly from the app.")
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

// MARK: - ScaleButtonStyle (for enhanced feedback)
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - PortfolioPieChartView (iOS 16+)
struct PortfolioPieChartView: View {
    let holdings: [Holding]
    
    var body: some View {
        if #available(iOS 16.0, *) {
            Chart(holdings) { holding in
                let qty = holding.quantity ?? 1.0
                SectorMark(
                    angle: .value("Value", holding.currentPrice * qty),
                    innerRadius: .ratio(0.6),
                    outerRadius: .ratio(0.95)
                )
                .foregroundStyle(by: .value("Coin", holding.coinSymbol))
            }
            .chartLegend(.hidden)
        } else {
            Text("Pie chart requires iOS 16+.")
                .foregroundColor(.gray)
        }
    }
}

// MARK: - PortfolioCoinRow
struct PortfolioCoinRow: View {
    @ObservedObject var viewModel: PortfolioViewModel
    let holding: Holding
    
    var body: some View {
        let rowPL = holding.profitLoss
        HStack(spacing: 12) {
            // Coin image or fallback icon
            if let urlStr = holding.imageUrl, let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Image(systemName: "bitcoinsign.circle")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36, height: 36)
                            .foregroundColor(.gray)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36, height: 36)
                    case .failure:
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36, height: 36)
                            .foregroundColor(.gray)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Image(systemName: "bitcoinsign.circle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
                    .foregroundColor(.gray)
            }
            
            // Coin name, symbol, favorite toggle, daily change
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(holding.coinName) (\(holding.coinSymbol))")
                        .font(.headline)
                    Button {
                        viewModel.toggleFavorite(holding)
                    } label: {
                        Image(systemName: holding.isFavorite ? "star.fill" : "star")
                            .foregroundColor(holding.isFavorite ? .yellow : .gray)
                    }
                    .buttonStyle(.plain)
                }
                Text(String(format: "24h: %.2f%%", holding.dailyChange))
                    .foregroundColor(holding.dailyChange >= 0 ? .green : .red)
                    .font(.caption)
            }
            
            Spacer()
            
            // Current price & P/L
            VStack(alignment: .trailing, spacing: 2) {
                Text("$\(holding.currentPrice, specifier: "%.2f")")
                    .font(.headline)
                Text(String(format: "P/L: $%.2f", rowPL))
                    .foregroundColor(rowPL >= 0 ? .green : .red)
                    .font(.subheadline)
            }
        }
        .padding(.vertical, 8)
        .background(rowPL >= 0 ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - TransactionsRow
struct TransactionsRow: View {
    let symbol: String
    let quantity: Double
    let price: Double
    let date: Date
    let isBuy: Bool
    
    var body: some View {
        HStack {
            Image(systemName: isBuy ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                .foregroundColor(isBuy ? .green : .red)
            VStack(alignment: .leading) {
                Text("\(isBuy ? "Buy" : "Sell") \(symbol)")
                    .font(.headline)
                Text(date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text("\(quantity, specifier: "%.2f") @ $\(price, specifier: "%.2f")")
                .font(.subheadline)
        }
        .padding(.vertical, 6)
    }
}

// MARK: - PortfolioView
struct PortfolioView: View {
    @StateObject var viewModel = PortfolioViewModel()
    
    // Top tabs: Overview vs. Transactions
    @State private var selectedTab: Int = 0
    
    // For searching holdings
    @State private var searchTerm: String = ""
    @State private var showSearchBar: Bool = true  // toggles the search bar
    
    // Sheets for add, settings, connect view
    @State private var showAddSheet = false
    @State private var showSettingsSheet = false
    @State private var showPaymentMethodsSheet = false
    
    // Quick action/tooltip
    @State private var showTooltip = false
    
    private var displayedHoldings: [Holding] {
        let base = viewModel.displayedHoldings
        if searchTerm.isEmpty {
            return base
        } else {
            return base.filter {
                $0.coinName.lowercased().contains(searchTerm.lowercased()) ||
                $0.coinSymbol.lowercased().contains(searchTerm.lowercased())
            }
        }
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                totalsSection
                tabBar
                if selectedTab == 0 {
                    overviewTab
                } else {
                    transactionsTab
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            // Make sure AddHoldingView exists in your project
            AddHoldingView(viewModel: viewModel)
        }
        .sheet(isPresented: $showSettingsSheet) {
            // Make sure SettingsView exists in your project
            SettingsView()
        }
        .sheet(isPresented: $showPaymentMethodsSheet) {
            PaymentMethodsView()
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Portfolio")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Text("Track your assets & P/L")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
            
            // Toggle search bar
            Button {
                withAnimation {
                    showSearchBar.toggle()
                }
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.title3)
                    .foregroundColor(.white)
            }
            .padding(.trailing, 16)
            
            Button {
                showSettingsSheet = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.title3)
                    .foregroundColor(.white)
            }
            .padding(.trailing, 16)
            
            Button {
                showAddSheet = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal)
        .padding(.top, 12)
    }
    
    // MARK: - Totals Section
    private var totalsSection: some View {
        VStack(spacing: 2) {
            Text("$\(viewModel.totalValue, specifier: "%.2f")")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
            let pl = viewModel.totalProfitLoss
            Text(String(format: "Total P/L: $%.2f", pl))
                .foregroundColor(pl >= 0 ? .green : .red)
                .font(.subheadline)
        }
        .padding(.vertical, 12)
    }
    
    // MARK: - Tab Bar
    private var tabBar: some View {
        HStack(spacing: 0) {
            Button(action: { withAnimation { selectedTab = 0 }}) {
                Text("Overview")
                    .font(.headline)
                    .foregroundColor(selectedTab == 0 ? .white : .gray)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(selectedTab == 0 ? brandAccent.opacity(0.3) : Color.clear)
                    .cornerRadius(8)
            }
            .buttonStyle(ScaleButtonStyle())
            
            Button(action: { withAnimation { selectedTab = 1 }}) {
                Text("Transactions")
                    .font(.headline)
                    .foregroundColor(selectedTab == 1 ? .white : .gray)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(selectedTab == 1 ? brandAccent.opacity(0.3) : Color.clear)
                    .cornerRadius(8)
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    // MARK: - Overview Tab
    private var overviewTab: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // Main chart container with a full‑width gradient background.
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.gray.opacity(0.2),
                                    Color.black.opacity(0.4)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)
                    
                    // Chart view placed directly over the gradient.
                    // Make sure PortfolioChartView is defined in your project.
                    PortfolioChartView()
                        .frame(height: 240)
                        .padding(.top, 30)  // so chart labels aren’t clipped
                        .padding(.bottom, 16)
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                // Pie Chart (centered, smaller)
                if #available(iOS 16.0, *) {
                    HStack {
                        Spacer()
                        PortfolioPieChartView(holdings: displayedHoldings)
                            .frame(width: 180, height: 180)
                        Spacer()
                    }
                    .padding(.horizontal)
                }
                
                // Search Bar
                if showSearchBar {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            TextField("Search Holdings...", text: $searchTerm)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(brandAccent.opacity(0.5), lineWidth: 1)
                        )
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                        .transition(.slide)
                    }
                    .padding(.horizontal)
                }
                
                // Holdings Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Holdings")
                        .foregroundColor(.white)
                        .font(.headline)
                        .padding(.horizontal)
                    
                    LazyVStack(spacing: 8) {
                        ForEach(displayedHoldings) { holding in
                            PortfolioCoinRow(viewModel: viewModel, holding: holding)
                                .padding(.horizontal)
                        }
                        .onDelete { indexSet in
                            viewModel.removeHolding(at: indexSet)
                        }
                    }
                    .padding(.top, 8)
                }
                
                // Connect Exchanges & Wallets Button with Tooltip
                HStack(spacing: 8) {
                    Button {
                        showPaymentMethodsSheet = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "link.circle.fill")
                            Text("Connect Exchanges & Wallets")
                                .fontWeight(.medium)
                        }
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(brandAccent.opacity(0.3))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    Button {
                        showTooltip.toggle()
                    } label: {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(.white)
                            .font(.title3)
                    }
                    .popover(isPresented: $showTooltip) {
                        Text("Link your accounts to trade seamlessly.\nThis is a quick info popover!")
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.black)
                            .cornerRadius(8)
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
        }
    }
    
    // MARK: - Transactions Tab
    private var transactionsTab: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                TransactionsRow(symbol: "BTC", quantity: 0.5, price: 20000,
                                date: Date(timeIntervalSinceNow: -86400), isBuy: true)
                TransactionsRow(symbol: "ETH", quantity: 2.0, price: 1500,
                                date: Date(timeIntervalSinceNow: -172800), isBuy: true)
                TransactionsRow(symbol: "BTC", quantity: 0.2, price: 22000,
                                date: Date(), isBuy: false)
            }
            .padding(.horizontal)
            .padding(.top, 16)
        }
    }
}

struct PortfolioView_Previews: PreviewProvider {
    static var previews: some View {
        PortfolioView()
            .preferredColorScheme(.dark)
    }
}
