//
//  PortfolioView.swift
//  CSAI1
//
//  A fresh layout: bigger top bar, a smaller card for total, refined chart,
//  and a more competitor-like look in dark mode.
//

import SwiftUI

// MARK: - BasicLineChart (same as before)
struct BasicLineChart: View {
    let data: [Double]
    
    var body: some View {
        GeometryReader { geo in
            if data.count > 1,
               let minVal = data.min(),
               let maxVal = data.max(),
               maxVal > minVal {
                
                let range = maxVal - minVal
                // Main line
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
                
                // Fill under the line
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

// MARK: - PortfolioCoinRow
struct PortfolioCoinRow: View {
    @ObservedObject var viewModel: PortfolioViewModel
    let holding: Holding
    
    var body: some View {
        let rowPL = holding.profitLoss
        HStack(spacing: 12) {
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
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(holding.coinName) (\(holding.coinSymbol))")
                        .font(.headline)
                    Button {
                        viewModel.toggleFavorite(holding)
                    } label: {
                        Image(systemName: holding.isFavorite ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                    }
                    .buttonStyle(.plain)
                }
                Text(String(format: "24h: %.2f%%", holding.dailyChange))
                    .foregroundColor(holding.dailyChange >= 0 ? .green : .red)
                    .font(.caption)
            }
            Spacer()
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

// MARK: - TransactionsRow (Placeholder)
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
            VStack(alignment: .trailing) {
                Text("\(quantity, specifier: "%.2f") @ $\(price, specifier: "%.2f")")
                    .font(.subheadline)
            }
        }
        .padding(.vertical, 6)
    }
}

struct PortfolioView: View {
    @StateObject var viewModel = PortfolioViewModel()
    
    // For the two top tabs: Overview vs. Transactions
    @State private var selectedTab: Int = 0
    
    // For chart time range
    @State private var selectedRange: ChartTimeRange = .week
    
    // For searching holdings
    @State private var searchTerm: String = ""
    
    // Sheets
    @State private var showAddSheet = false
    @State private var showSettingsSheet = false
    
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
    
    // Placeholder transactions
    private var sampleTransactions: [String] {
        ["Bought BTC", "Sold ETH", "Bought ETH"]
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 1) Enhanced top bar
                topBar
                
                // 2) Big total & P/L
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
                
                // 3) Tab bar
                tabBar
                
                // 4) Tab content
                if selectedTab == 0 {
                    overviewTab
                } else {
                    transactionsTab
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddHoldingView(viewModel: viewModel)
        }
        .sheet(isPresented: $showSettingsSheet) {
            SettingsView()
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Enhanced top bar
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
    
    // MARK: - Tab bar
    private var tabBar: some View {
        HStack {
            Button(action: { selectedTab = 0 }) {
                Text("Overview")
                    .font(.headline)
                    .foregroundColor(selectedTab == 0 ? .white : .gray)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(selectedTab == 0 ? Color.gray.opacity(0.3) : Color.clear)
                    .cornerRadius(8)
            }
            Button(action: { selectedTab = 1 }) {
                Text("Transactions")
                    .font(.headline)
                    .foregroundColor(selectedTab == 1 ? .white : .gray)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(selectedTab == 1 ? Color.gray.opacity(0.3) : Color.clear)
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    // MARK: - Overview tab
    private var overviewTab: some View {
        VStack(spacing: 0) {
            // Performance chart
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Performance")
                        .foregroundColor(.white)
                        .font(.headline)
                    Spacer()
                    Picker("", selection: $selectedRange) {
                        ForEach(ChartTimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 150)
                    .onChange(of: selectedRange) { newRange in
                        withAnimation {
                            viewModel.generatePerformanceData(for: newRange)
                        }
                    }
                }
                
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.2)))
                    BasicLineChart(data: viewModel.performanceData)
                        .padding(8)
                }
                .frame(height: 130)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search Holdings...", text: $searchTerm)
                    .foregroundColor(.white)
            }
            .padding(10)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(8)
            .padding(.horizontal)
            .padding(.top, 8)
            
            // Holdings label
            HStack {
                Text("Holdings")
                    .foregroundColor(.white)
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            // Scrollable holdings
            ScrollView {
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
        }
    }
    
    // MARK: - Transactions tab
    private var transactionsTab: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                TransactionsRow(symbol: "BTC", quantity: 0.5, price: 20000, date: Date(timeIntervalSinceNow: -86400), isBuy: true)
                TransactionsRow(symbol: "ETH", quantity: 2.0, price: 1500, date: Date(timeIntervalSinceNow: -172800), isBuy: true)
                TransactionsRow(symbol: "BTC", quantity: 0.2, price: 22000, date: Date(), isBuy: false)
            }
            .padding(.horizontal)
            .padding(.top, 16)
        }
    }
}
