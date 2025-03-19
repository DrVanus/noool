//
//  PortfolioView.swift
//  CSAI1
//
//  Main Portfolio screen: custom top bar, mini performance chart,
//  stats, a search bar, a time range picker, and color-coded rows.
//

import SwiftUI

// MARK: - BasicLineChart
struct BasicLineChart: View {
    let data: [Double]
    
    var body: some View {
        GeometryReader { geo in
            if data.count > 1,
               let minVal = data.min(),
               let maxVal = data.max(),
               maxVal > minVal {
                
                let range = maxVal - minVal
                
                // Main chart line
                Path { path in
                    for (index, value) in data.enumerated() {
                        let xPos = geo.size.width * CGFloat(index) / CGFloat(data.count - 1)
                        let yPos = geo.size.height * (1 - CGFloat((value - minVal) / range))
                        index == 0
                            ? path.move(to: CGPoint(x: xPos, y: yPos))
                            : path.addLine(to: CGPoint(x: xPos, y: yPos))
                    }
                }
                .stroke(Color.green, lineWidth: 2)
                
                // Fill under line
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
    let holding: Holding
    
    var body: some View {
        // Color the background based on P/L
        let rowPL = holding.profitLoss
        return HStack {
            Image(systemName: "bitcoinsign.circle")
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(holding.coinName) (\(holding.coinSymbol))")
                    .font(.headline)
                Text("Qty: \(holding.quantity, specifier: "%.2f")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
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
        .padding(.vertical, 4)
        .background(rowPL >= 0 ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        .cornerRadius(6)
    }
}

// MARK: - AddHoldingView
struct AddHoldingView: View {
    @ObservedObject var viewModel: PortfolioViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var coinName: String = ""
    @State private var coinSymbol: String = ""
    @State private var quantity: String = ""
    @State private var currentPrice: String = ""
    @State private var costBasis: String = ""
    @State private var imageUrl: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Coin Info")) {
                    TextField("Coin Name", text: $coinName)
                    TextField("Coin Symbol", text: $coinSymbol)
                    TextField("Image URL (optional)", text: $imageUrl)
                }
                
                Section(header: Text("Holding Details")) {
                    TextField("Quantity", text: $quantity)
                        .keyboardType(.decimalPad)
                    TextField("Current Price", text: $currentPrice)
                        .keyboardType(.decimalPad)
                    TextField("Total Cost Basis", text: $costBasis)
                        .keyboardType(.decimalPad)
                }
                
                Button("Add Holding") {
                    guard let qty = Double(quantity),
                          let price = Double(currentPrice),
                          let basis = Double(costBasis) else {
                        return // invalid input
                    }
                    let trimmedUrl = imageUrl.trimmingCharacters(in: .whitespacesAndNewlines)
                    let finalUrl = trimmedUrl.isEmpty ? nil : trimmedUrl
                    
                    viewModel.addHolding(
                        coinName: coinName,
                        coinSymbol: coinSymbol,
                        quantity: qty,
                        currentPrice: price,
                        costBasis: basis,
                        imageUrl: finalUrl
                    )
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .navigationBarTitle("Add Holding", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// MARK: - Main PortfolioView
struct PortfolioView: View {
    @StateObject var viewModel = PortfolioViewModel()
    
    // For the time range picker
    @State private var selectedRange: ChartTimeRange = .week
    
    // For the search bar
    @State private var searchTerm: String = ""
    
    @State private var showAddSheet = false
    @State private var showSettingsSheet = false
    
    /// Filter holdings by coinName or coinSymbol
    private var filteredHoldings: [Holding] {
        if searchTerm.isEmpty {
            return viewModel.holdings
        } else {
            return viewModel.holdings.filter { holding in
                holding.coinName.lowercased().contains(searchTerm.lowercased()) ||
                holding.coinSymbol.lowercased().contains(searchTerm.lowercased())
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Custom top bar
                HStack {
                    Text("Your Portfolio")
                        .font(.title)
                        .fontWeight(.bold)
                    Spacer()
                    
                    // Settings
                    Button(action: {
                        showSettingsSheet = true
                    }) {
                        Image(systemName: "gear")
                            .font(.title2)
                            .padding(.trailing, 12)
                    }
                    
                    // Add
                    Button(action: {
                        showAddSheet = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                
                // Time range picker
                Picker("Time Range", selection: $selectedRange) {
                    Text("1W").tag(ChartTimeRange.week)
                    Text("1M").tag(ChartTimeRange.month)
                    Text("1Y").tag(ChartTimeRange.year)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .onChange(of: selectedRange) { newRange in
                    viewModel.generatePerformanceData(for: newRange)
                }
                
                // Performance chart
                VStack(alignment: .leading) {
                    Text("Performance")
                        .font(.headline)
                        .padding(.horizontal)
                    ZStack {
                        Rectangle()
                            .fill(Color(.systemGray6))
                        BasicLineChart(data: viewModel.performanceData)
                            .padding(8)
                    }
                    .frame(height: 150)
                    .padding(.horizontal)
                }
                .padding(.bottom, 8)
                
                // Stats area: total value & P/L
                VStack(spacing: 4) {
                    Text("Total Value")
                        .font(.headline)
                    Text("$\(viewModel.totalValue, specifier: "%.2f")")
                        .font(.largeTitle)
                    
                    let pl = viewModel.totalProfitLoss
                    Text(String(format: "Total P/L: $%.2f", pl))
                        .foregroundColor(pl >= 0 ? .green : .red)
                        .font(.headline)
                }
                .padding(.vertical, 12)
                
                Divider().padding(.horizontal)
                
                // Search bar
                TextField("Search Holdings...", text: $searchTerm)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                Text("Holdings")
                    .font(.headline)
                    .padding(.top, 8)
                
                // Filtered holdings
                VStack(spacing: 0) {
                    ForEach(filteredHoldings) { holding in
                        PortfolioCoinRow(holding: holding)
                        Divider()
                    }
                }
                .padding(.horizontal)
                .padding(.top, 4)
            }
        }
        // Sheet for adding a new holding
        .sheet(isPresented: $showAddSheet) {
            AddHoldingView(viewModel: viewModel)
        }
        // Sheet for the separate SettingsView file
        .sheet(isPresented: $showSettingsSheet) {
            SettingsView()
        }
    }
}

// MARK: - Preview
struct PortfolioView_Previews: PreviewProvider {
    static var previews: some View {
        PortfolioView()
    }
}
