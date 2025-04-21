import SwiftUI
import Charts
import WebKit
import Combine

// Subtle pressed-state opacity style
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.6 : 1.0)
    }
}

// MARK: - TradeSide / OrderType
enum TradeSide: String, CaseIterable {
    case buy, sell
}

enum OrderType: String, CaseIterable {
    case market
    case limit
    case stopLimit = "stop-limit"
    case trailingStop = "trailing stop"
}

// ------------------------------------------------------------------------
// REMOVED local PaymentMethod struct from here to avoid conflict with
// PaymentMethodsView.swift
// ------------------------------------------------------------------------

// MARK: - TradeView
struct TradeView: View {
    
    // The symbol to trade (default "BTC")
    @State private var symbol: String
    
    // Whether to show a "Back" button
    private let showBackButton: Bool
    
    // Main ViewModels
    @StateObject private var vm = TradeViewModel()
    @StateObject private var orderBookVM = OrderBookViewModel()
    @StateObject private var priceVM: PriceViewModel
    
    // UI states
    // Removed selectedChartType and chart toggle since TradingView is not used currently.
    @State private var selectedInterval: ChartInterval = .oneHour
    @State private var selectedSide: TradeSide = .buy
    @State private var orderType: OrderType = .market
    
    @State private var quantity: String = "0.0"
    @State private var limitPrice: String = ""
    @State private var stopPrice: String = ""
    
    // Slider from 0..1 so user can pick a fraction of “balance”
    @State private var sliderValue: Double = 0.0
    
    // Coin picker
    @State private var isCoinPickerPresented = false
    @State private var isOrderBookModalPresented: Bool = false
    
    // Removed Payment Method selection since it's no longer needed.
    // @State private var selectedPaymentMethod: PaymentMethod = PaymentMethod(name: "Coinbase", details: "Coinbase Exchange")
    // @State private var isPaymentMethodPickerPresented = false
    
    // NEW: State for presenting the Trading Bot view
    @State private var isTradingBotPresented: Bool = false
    @State private var isShowingErrorBanner: Bool = false
    @State private var showSlippageDialog: Bool = false
    @State private var slippageTolerance: Double = 0.5
    // Track whether the trading bot is running
    @State private var isBotRunning: Bool = false
    // Access horizontal size class for compact layout
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    // MARK: - Init
    init(symbol: String = "BTC", showBackButton: Bool = false) {
        _symbol = State(initialValue: symbol.uppercased())
        self.showBackButton = showBackButton
        _priceVM = StateObject(wrappedValue: PriceViewModel(symbol: symbol.uppercased()))
    }
    
    var body: some View {
    VStack(spacing: 0) {
            
            // 1) Nav Bar (with coin picker + Trading Bot button)
            navBar
            
            
            // 2) Live Price row
            priceRow
            
            // 3) Chart
            chartSection
                .id(symbol) // Force rebuild when symbol changes
                .zIndex(1)  // Chart behind the interval picker
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 16)
            
            // 4) Interval Picker
            intervalPicker
                .zIndex(999) // On top so taps always register
                .padding(.vertical, 2)
            
            // 5) Buy/Sell UI
            tradeForm
    .padding(.top, 8)
                .disabled(isShowingErrorBanner)
                .opacity(isShowingErrorBanner ? 0.6 : 1.0)
            
            // 6) Order Book
            orderBookSection
            
        }
        // Use dynamic theme background.
        .background(FuturisticBackground().ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .onAppear {
            vm.currentSymbol = symbol
            vm.fetchBalance(for: symbol)
            priceVM.updateSymbol(symbol)
            orderBookVM.startFetchingOrderBook(for: symbol)
        }
        .onChange(of: symbol) { newSymbol in
            symbol = newSymbol
            vm.currentSymbol = newSymbol
            priceVM.updateSymbol(newSymbol)
            orderBookVM.startFetchingOrderBook(for: newSymbol)
            vm.fetchBalance(for: newSymbol)
        }
        .onDisappear {
            orderBookVM.stopFetching()
        }
        .onChange(of: priceVM.currentPrice) { newPrice in
            if newPrice == -1 {
                isShowingErrorBanner = true
            }
        }
        .onChange(of: orderBookVM.errorMessage) { newErr in
            if newErr != nil {
                isShowingErrorBanner = true
            }
        }
        // Show coin picker as a sheet
        .sheet(isPresented: $isCoinPickerPresented) {
            EnhancedCoinPickerView(currentSymbol: $symbol) { newCoin in
                symbol = newCoin
                vm.currentSymbol = newCoin
                priceVM.updateSymbol(newCoin)
                orderBookVM.startFetchingOrderBook(for: newCoin)
            }
        }
        
        // NEW: Present TradingBotView as a sheet, passing in current trade parameters
        .sheet(isPresented: $isTradingBotPresented, onDismiss: {
            isBotRunning = false
        }) {
            TradingBotView(
                side: selectedSide,
                orderType: orderType,
                quantity: Double(quantity) ?? 0.0,
                slippage: slippageTolerance
            )
        }
        .presentationDragIndicator(.hidden)
        .sheet(isPresented: $isOrderBookModalPresented) {
            VStack {
                HStack {
                    Text("Order Book")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.white)
                    Spacer()
                    Button("Close") {
                        isOrderBookModalPresented = false
                    }
                    .foregroundColor(.yellow)
                }
                .padding()

                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                        VStack(alignment: .leading) {
                                Text("Bids")
                                    .font(.headline)
                                    .foregroundColor(.green)
                                ForEach(orderBookVM.bids, id: \.price) { bid in
                                    Text("\(bid.price) | \(bid.qty)")
                                        .foregroundColor(.white)
                                        .font(.caption)
                                }
                            }
                            Spacer()
                            VStack(alignment: .leading) {
                                Text("Asks")
                                    .font(.headline)
                                    .foregroundColor(.red)
                                ForEach(orderBookVM.asks, id: \.price) { ask in
                                    Text("\(ask.price) | \(ask.qty)")
                                        .foregroundColor(.white)
                                        .font(.caption)
                                }
                            }
                        }
                    }
                    .padding()
                }
                .background(Color.black)
            }
        .background(Color.black.ignoresSafeArea())
        }
        .presentationDragIndicator(.hidden)
    }
    
    // MARK: - Nav Bar
private var navBar: some View {
    HStack(alignment: .center) {
        if showBackButton {
            Button {
                presentationMode.wrappedValue.dismiss()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.yellow)
                    Text("Back")
                        .foregroundColor(.yellow)
                }
            }
        }
        
        Spacer()
        
        HStack(spacing: 8) {
            Text(symbol.uppercased())
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            Button {
                isCoinPickerPresented = true
            } label: {
                Image(systemName: "chevron.down")
                    .foregroundColor(.white)
            }
            
        }
        
        Spacer()
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 4)
    .background(Color.black.opacity(0.2)) // subtle background for visual separation
}
    
    // MARK: - Price Row
    private var priceRow: some View {
        HStack {
            switch priceVM.currentPrice {
            case 0:
                Text("Loading...")
                    .foregroundColor(.yellow)
                    .font(.system(size: 20, weight: .bold))
            case -1:
                Text("--")
                    .foregroundColor(.gray)
                    .font(.system(size: 20, weight: .bold))
            default:
                Text(formatPriceWithCommas(priceVM.currentPrice))
                    .foregroundColor(.yellow)
                    .font(.system(size: 20, weight: .bold))
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 16)
        .background(Color.white.opacity(0.05))
    }
    
    // A comma-based price formatter
    private func formatPriceWithCommas(_ value: Double) -> String {
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
    
    // MARK: - Chart
    @ViewBuilder
    private var chartSection: some View {
        // Always show CryptoSage AI chart (TradingView branch removed)
        TradeCustomChart(symbol: symbol, interval: selectedInterval)
    }
    
    // MARK: - Interval Picker
    private var intervalPicker: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ChartInterval.allCases, id: \.self) { interval in
                        Button {
                            withAnimation(.easeInOut) {
                                selectedInterval = interval
                            }
                        } label: {
                            Text(interval.rawValue)
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedInterval == interval
                                              ? Color.yellow
                                              : Color(.darkGray))
                                )
                                .foregroundColor(selectedInterval == interval ? .black : .white)
                        }
                        .id(interval)
                    }
                }
                .padding(.horizontal, 12)
            }
            .frame(height: 44)
            .onChange(of: selectedInterval) { newInterval in
                withAnimation(.easeInOut) {
                    proxy.scrollTo(newInterval, anchor: .center)
                }
            }
        }
    }
    
    // MARK: - Chart Type Toggle
    // REMOVED: Chart type toggle has been removed.
    
    // MARK: - Trade Form (Buy/Sell UI)
    private var tradeForm: some View {
    VStack(spacing: 8) {
            let qtyVal = Double(quantity) ?? 0
            let tradeAmount = qtyVal * priceVM.currentPrice
            let fee = tradeAmount * 0.001 // 0.1% fee
            let totalCost = tradeAmount + fee

            // Fee + Buy/Sell controls
            HStack(alignment: .top, spacing: 16) {
                // Estimated fee & Total cost
                VStack(spacing: 4) {
                    HStack {
                        Text("Estimated fee:")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                        Text(formatPriceWithCommas(fee))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Text("Total cost:")
                            .font(.caption)
                            .foregroundColor(.white)
                        Spacer()
                        Text(formatPriceWithCommas(totalCost))
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }
                
                Spacer()
                
                // Buy/Sell Toggle (compact)
                HStack(spacing: 2) {
                    Button {
                        selectedSide = .buy
                    } label: {
                        Text("Buy")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(selectedSide == .buy ? .black : .white)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                            .background(selectedSide == .buy ? Color.yellow : Color.white.opacity(0.15))
                            .cornerRadius(10)
                    }
                    
                    Button {
                        selectedSide = .sell
                    } label: {
                        Text("Sell")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                            .background(selectedSide == .sell ? Color.red : Color.white.opacity(0.15))
                            .cornerRadius(10)
                    }
                }
            }
            .padding(.horizontal, 12)
            .confirmationDialog("Select Slippage", isPresented: $showSlippageDialog, titleVisibility: .visible) {
                ForEach([0.1, 0.5, 1.0, 2.0], id: \.self) { pct in
                    Button("\(Int(pct * 100))%") { slippageTolerance = pct }
                }
            }
            
            // Order Type
            Picker("Order Type", selection: $orderType) {
                ForEach(OrderType.allCases, id: \.self) { type in
                    Text(type.rawValue.capitalized).tag(type)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 12)
            
            if orderType == .limit {
                HStack(spacing: 8) {
                    Text("Limit:")
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .fixedSize()
                    TextField("0.0", text: $limitPrice)
                        .keyboardType(.decimalPad)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                        .frame(width: 80)
                }
                .padding(.horizontal, 12)
            } else if orderType == .stopLimit {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Text("Stop:")
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .fixedSize()
                        TextField("0.0", text: $stopPrice)
                            .keyboardType(.decimalPad)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                            .frame(width: 80)
                    }
                    HStack(spacing: 8) {
                        Text("Limit:")
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .fixedSize()
                        TextField("0.0", text: $limitPrice)
                            .keyboardType(.decimalPad)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                            .frame(width: 80)
                    }
                }
                .padding(.horizontal, 12)
            }
            
            HStack(spacing: 8) {
                Text("Quantity:")
                    .foregroundColor(.white)
                    .fixedSize()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Button { vm.decrementQuantity(&quantity) } label: { Image(systemName: "minus.circle") }
                    .foregroundColor(.white)
                    .padding(6)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(8)
                    .buttonStyle(PressableButtonStyle())
                TextField("0.0", text: $quantity)
                    .keyboardType(.decimalPad)
                    .foregroundColor(.white)
                    .frame(width: 60)
                    .padding(6)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                Button { vm.incrementQuantity(&quantity) } label: { Image(systemName: "plus.circle") }
                    .foregroundColor(.white)
                    .padding(6)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(8)
                    .fixedSize()
                    .buttonStyle(PressableButtonStyle())
                ForEach([25, 50, 75, 100], id: \.self) { pct in
                    Button("\(pct)%") {
                        quantity = vm.fillQuantity(forPercent: pct)
                    }
                    .foregroundColor(.white)
                    .font(.caption2)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(8)
                    .fixedSize()
                    .buttonStyle(PressableButtonStyle())
                }
                Spacer()
            }
            .padding(.horizontal, 12)
            
            
            
            // User balance and USD equivalent
            let balanceCrypto = vm.balance
            let balanceUSD = balanceCrypto * priceVM.currentPrice
            
            // User balance, Slippage & Trading Bot
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(format: "Balance: %.4f %@", balanceCrypto, symbol.uppercased()))
                        .font(.caption)
                        .foregroundColor(.white)
                    Text("≈ \(formatPriceWithCommas(balanceUSD))")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                Spacer()
                Button {
                    showSlippageDialog = true
                } label: {
                    Label("\(Int(slippageTolerance * 100))%", systemImage: "gearshape.fill")
                        .font(.caption2)
                        .foregroundColor(.white)
                }
                .confirmationDialog("Select Slippage", isPresented: $showSlippageDialog, titleVisibility: .visible) {
                    ForEach([0.1, 0.5, 1.0, 2.0], id: \.self) { pct in
                        Button("\(Int(pct * 100))%") { slippageTolerance = pct }
                    }
                }
                .padding(6)
                .background(Capsule().fill(Color.white.opacity(0.15)))
                .buttonStyle(PressableButtonStyle())
                
                Button {
                    isBotRunning.toggle()
                    isTradingBotPresented = true
                } label: {
                    Label("Trading Bot", systemImage: "cpu.fill")
                        .font(.caption2)
                        .foregroundColor(.black)
                }
                .padding(6)
                .background(Capsule().fill(isBotRunning ? Color.yellow.opacity(0.8) : Color.yellow))
                .buttonStyle(PressableButtonStyle())
            }
            .padding(.horizontal, 12)
            
            // Slider row
            HStack {
                Slider(value: $sliderValue, in: 0...1, step: 0.01) {
                    Text("Amount Slider")
                }
                .accentColor(.yellow)
                .onChange(of: sliderValue) { newVal, _ in
                    let pct = Int(newVal * 100)
                    quantity = vm.fillQuantity(forPercent: pct)
                }
            }
            .padding(.horizontal, 12)
            
            // Big Submit button
            Button {
                vm.executeTrade(side: selectedSide, symbol: symbol, orderType: orderType, quantity: quantity)
            } label: {
                Text("\(selectedSide.rawValue.capitalized) \(symbol.uppercased())")
                    .font(.headline)
                    .foregroundColor(selectedSide == .sell ? .white : .black)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(selectedSide == .sell ? Color.red : Color.yellow)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .disabled(
                quantity == "0.0"
                || (orderType == .limit && limitPrice.isEmpty)
                || (orderType == .stopLimit && (stopPrice.isEmpty || limitPrice.isEmpty))
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.2))
        )
        .padding(.horizontal, 12)
    }
    
    // MARK: - Order Book Section
    private var orderBookSection: some View {
    VStack(spacing: 0) {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                   // Toggle order book modal
                   Button {
                       // Toggle the order book sheet open/closed
                       isOrderBookModalPresented.toggle()
                   } label: {
                       HStack {
                           Text("Order Book (Live Depth)")
                               .font(.headline)
                               .foregroundColor(.white)
                           Spacer()
                       Image(systemName: isOrderBookModalPresented ? "chevron.down" : "chevron.up")
                           .foregroundColor(.white)
                       }
                   }
                    if orderBookVM.isLoading {
                        ProgressView("Loading order book...")
                            .foregroundColor(.white)
                    } else if let err = orderBookVM.errorMessage {
                        Text("Error: \(err)")
                            .foregroundColor(.red)
                            .font(.caption)
                    } else {
                        HStack(alignment: .top, spacing: 16) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Bids")
                                    .font(.subheadline)
                                    .foregroundColor(.green)
                                ForEach(orderBookVM.bids.prefix(5), id: \.price) { bid in
                                    Text("\(bid.price) | \(bid.qty)")
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.white)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Asks")
                                    .font(.subheadline)
                                    .foregroundColor(.red)
                                ForEach(orderBookVM.asks.prefix(5), id: \.price) { ask in
                                    Text("\(ask.price) | \(ask.qty)")
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.white)
                        }
                    }
                }
                .padding(8)
                .background(Color.white.opacity(0.05))
                .cornerRadius(8)
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            }
            .frame(height: 140)
            
            // Top & Bottom gradient masks
            VStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.black.opacity(0.6), .clear]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 16)
                
                Spacer()
                
                LinearGradient(
                    gradient: Gradient(colors: [.clear, Color.black.opacity(0.6)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 16)
            }
            .allowsHitTesting(false)
        }
    }
    }
}

// MARK: - EnhancedCoinPickerView
struct EnhancedCoinPickerView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @Binding var currentSymbol: String
    var onSelect: (String) -> Void
    
    @State private var allCoins: [Coin] = [
        Coin(symbol: "BTC", name: "Bitcoin"),
        Coin(symbol: "ETH", name: "Ethereum"),
        Coin(symbol: "SOL", name: "Solana"),
        Coin(symbol: "ADA", name: "Cardano"),
        Coin(symbol: "XRP", name: "XRP"),
        Coin(symbol: "BNB", name: "Binance Coin"),
        Coin(symbol: "MATIC", name: "Polygon"),
        Coin(symbol: "DOT", name: "Polkadot"),
        Coin(symbol: "DOGE", name: "Dogecoin"),
        Coin(symbol: "SHIB", name: "Shiba Inu"),
        Coin(symbol: "RLC", name: "iExec RLC")
    ]
    
    @State private var searchText: String = ""
    
    var filteredCoins: [Coin] {
        if searchText.isEmpty { return allCoins }
        return allCoins.filter {
            $0.symbol.localizedCaseInsensitiveContains(searchText)
            || $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search coins", text: $searchText)
                            .foregroundColor(.white)
                    }
                    .padding(8)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // List of coins
                    List {
                        ForEach(filteredCoins) { coin in
                            Button {
                                currentSymbol = coin.symbol
                                onSelect(coin.symbol)
                                presentationMode.wrappedValue.dismiss()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(coin.symbol)
                                            .foregroundColor(.white)
                                            .font(.headline)
                                        Text(coin.name)
                                            .foregroundColor(.gray)
                                            .font(.caption)
                                    }
                                    Spacer()
                                    if coin.symbol == currentSymbol {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.yellow)
                                    }
                                }
                            }
                            .listRowBackground(Color.clear)
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Select Coin")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.yellow)
                }
            }
        }
        .accentColor(.yellow)
    }
}

// MARK: - Coin Model
struct Coin: Identifiable {
    let id = UUID()
    let symbol: String
    let name: String
}

// --------------------------------------------------------------------------
// REMOVED local RenamePaymentMethodView to avoid conflict with PaymentMethodsView.swift
// --------------------------------------------------------------------------

// MARK: - TradeViewModel
class TradeViewModel: ObservableObject {
    @Published var currentSymbol: String = "BTC"
    @Published var balance: Double = 0.0
    private var cancellables = Set<AnyCancellable>()

    init() {
        ThreeCommasService.shared.$balance
            .receive(on: DispatchQueue.main)
            .assign(to: \.balance, on: self)
            .store(in: &cancellables)
    }
    
    func incrementQuantity(_ quantity: inout String) {
        if let val = Double(quantity) {
            quantity = String(val + 1.0)
        }
    }
    
    func decrementQuantity(_ quantity: inout String) {
        if let val = Double(quantity), val > 0 {
            quantity = String(max(0, val - 1.0))
        }
    }
    
    func fillQuantity(forPercent pct: Int) -> String {
        let fraction = Double(pct) / 100.0
        let result = self.balance * fraction
        return String(format: "%.4f", result)
    }
    
    
    // Removed stubGetBalance method

    func getBalance(for symbol: String) -> Double {
        return balance
    }
    
    func fetchBalance(for symbol: String) {
        ThreeCommasService.shared.fetchBalance(for: symbol)
    }

    func executeTrade(side: TradeSide, symbol: String, orderType: OrderType, quantity: String) {
        // Your trade logic here
        print("Execute \(side.rawValue) on \(symbol) with \(orderType.rawValue), qty=\(quantity)")
    }
}

// MARK: - OrderBookViewModel
class OrderBookViewModel: ObservableObject {
    struct OrderBookEntry: Equatable {
        let price: String
        let qty: String
    }
    
    @Published var bids: [OrderBookEntry] = []
    @Published var asks: [OrderBookEntry] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private var timer: Timer?
    
    func startFetchingOrderBook(for symbol: String) {
        let pair = symbol.uppercased() + "-USD"
        fetchOrderBook(pair: pair)
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            self.fetchOrderBook(pair: pair)
        }
    }
    
    func stopFetching() {
        timer?.invalidate()
        timer = nil
    }
    
    private func fetchOrderBook(pair: String) {
        let urlString = "https://api.exchange.coinbase.com/products/\(pair)/book?level=2"
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async {
                self.errorMessage = "Invalid order book URL."
            }
            return
        }
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async { self.isLoading = false }
            if let error = error {
                print("Coinbase order book error:", error.localizedDescription)
                self.fallbackFetchOrderBook(pair: pair)
                return
            }
            guard let data = data else {
                print("No data from Coinbase order book.")
                self.fallbackFetchOrderBook(pair: pair)
                return
            }
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let bidsArr = json["bids"] as? [[Any]],
                   let asksArr = json["asks"] as? [[Any]] {
                    
                    let parsedBids = bidsArr.map { arr -> OrderBookEntry in
                        let price = arr[0] as? String ?? "0"
                        let qty   = arr[1] as? String ?? "0"
                        return OrderBookEntry(price: price, qty: qty)
                    }
                    let parsedAsks = asksArr.map { arr -> OrderBookEntry in
                        let price = arr[0] as? String ?? "0"
                        let qty   = arr[1] as? String ?? "0"
                        return OrderBookEntry(price: price, qty: qty)
                    }
                    DispatchQueue.main.async {
                        self.bids = parsedBids
                        self.asks = parsedAsks
                    }
                } else {
                    print("Coinbase order book parse error, falling back.")
                    self.fallbackFetchOrderBook(pair: pair)
                }
            } catch {
                print("Coinbase order book JSON parse error:", error.localizedDescription)
                self.fallbackFetchOrderBook(pair: pair)
            }
        }.resume()
    }
    
    private func fallbackFetchOrderBook(pair: String) {
        // Convert pair "BTC-USD" to Binance symbol, e.g. "BTCUSDT"
        let binanceSymbol = pair.replacingOccurrences(of: "-USD", with: "") + "USDT"
        let urlString = "https://api.binance.com/api/v3/depth?symbol=\(binanceSymbol)&limit=5"
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async { self.errorMessage = "Invalid Binance order book URL." }
            return
        }
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("Binance order book fetch error:", error.localizedDescription)
                DispatchQueue.main.async {
                    self.errorMessage = "Binance order book error: \(error.localizedDescription)"
                }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async {
                    self.errorMessage = "No data from Binance order book."
                }
                return
            }
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let bidsArr = json["bids"] as? [[Any]],
                   let asksArr = json["asks"] as? [[Any]] {
                    
                    let parsedBids = bidsArr.map { arr -> OrderBookEntry in
                        let price = arr[0] as? String ?? "0"
                        let qty   = arr[1] as? String ?? "0"
                        return OrderBookEntry(price: price, qty: qty)
                    }
                    let parsedAsks = asksArr.map { arr -> OrderBookEntry in
                        let price = arr[0] as? String ?? "0"
                        let qty   = arr[1] as? String ?? "0"
                        return OrderBookEntry(price: price, qty: qty)
                    }
                    DispatchQueue.main.async {
                        self.bids = parsedBids
                        self.asks = parsedAsks
                    }
                } else {
                    DispatchQueue.main.async {
                        self.errorMessage = "Binance order book parse error."
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Binance JSON parse error: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
}

// MARK: - PriceViewModel
class PriceViewModel: ObservableObject {
    @Published var currentPrice: Double = 0.0
    
    private var timer: Timer?
    private var symbol: String
    
    init(symbol: String) {
        self.symbol = symbol.uppercased()
        fetchPrice()
        
        // Update price every 10 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
            self.fetchPrice()
        }
    }
    
    deinit {
        timer?.invalidate()
    }
    
    func updateSymbol(_ newSymbol: String) {
        self.symbol = newSymbol.uppercased()
        currentPrice = 0
        fetchPrice()
    }
    
    private func fetchPrice() {
        let pair = symbol.uppercased() + "-USD"
        let urlStr = "https://api.exchange.coinbase.com/products/\(pair)/ticker"
        
        guard let url = URL(string: urlStr) else {
            DispatchQueue.main.async {
                self.currentPrice = -1
            }
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("Coinbase price fetch error:", error.localizedDescription)
                self.fallbackFetchPrice() // Fallback using Binance
                return
            }
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let priceStr = json["price"] as? String,
                  let priceDbl = Double(priceStr) else {
                print("Coinbase price fetch parse error")
                self.fallbackFetchPrice()
                return
            }
            DispatchQueue.main.async { self.currentPrice = priceDbl }
        }.resume()
    }
    
    private func fallbackFetchPrice() {
        // Fallback using Binance API
        let binanceSymbol = symbol.uppercased() + "USDT"
        let urlStr = "https://api.binance.com/api/v3/ticker/price?symbol=\(binanceSymbol)"
        guard let url = URL(string: urlStr) else {
            DispatchQueue.main.async { self.currentPrice = -1 }
            return
        }
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("Binance price fetch error:", error.localizedDescription)
                DispatchQueue.main.async { self.currentPrice = -1 }
                return
            }
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let priceStr = json["price"] as? String,
                  let priceDbl = Double(priceStr) else {
                DispatchQueue.main.async { self.currentPrice = -1 }
                return
            }
            DispatchQueue.main.async { self.currentPrice = priceDbl }
        }.resume()
    }
}

// MARK: - TradeCustomChart
/// Your original chart code with candlesticks, crosshair, intervals, etc.
struct TradeCustomChart: View {
    let symbol: String
    let interval: ChartInterval
    
    @StateObject private var vm = CoinDetailChartViewModel()
    @State private var crosshairValue: ChartDataPoint? = nil
    @State private var showCrosshair: Bool = false
    
    var body: some View {
        ZStack {
            // Base content: error, initial loading, no data, or chart
            if let errorMsg = vm.errorMessage {
                errorView(errorMsg)
            } else if vm.dataPoints.isEmpty {
                if vm.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("No chart data")
                        .foregroundColor(.gray)
                }
            } else {
                if #available(iOS 16.0, *) {
                    chartContent
                        .id(interval)
                        .transition(.opacity)
                } else {
                    Text("iOS 16 Chart not available.")
                        .foregroundColor(.yellow)
                }
            }

        }
        .animation(.easeInOut(duration: 0.3), value: interval)
        .onAppear {
            vm.fetchBinanceData(symbol: symbol,
                                interval: interval.binanceInterval,
                                limit: interval.binanceLimit)
        }
        .onChange(of: symbol) { _, _ in
            vm.fetchBinanceData(symbol: symbol,
                                interval: interval.binanceInterval,
                                limit: interval.binanceLimit)
        }
        .onChange(of: interval) { _, newVal in
            vm.fetchBinanceData(symbol: symbol,
                                interval: newVal.binanceInterval,
                                limit: newVal.binanceLimit)
        }
    }
    
    @ViewBuilder
    @available(iOS 16.0, *)
    private var chartContent: some View {
        let minClose = vm.dataPoints.map { $0.close }.min() ?? 0
        let maxClose = vm.dataPoints.map { $0.close }.max() ?? 1
        
        let topMargin = (maxClose - minClose) * 0.03
        let clampedLowerBound = max(0, minClose)
        let upperBound = maxClose + topMargin
        
        let firstDate = vm.dataPoints.first?.date ?? Date()
        let lastDate  = vm.dataPoints.last?.date ?? Date()
        
        let axisLabelCount: Int = {
            switch interval {
            case .oneMin, .fiveMin: return 6
            case .oneYear, .threeYear, .all: return 3
            default: return 4
            }
        }()
        
        Chart {
            ForEach(vm.dataPoints) { point in
                LineMark(
                    x: .value("Time", point.date),
                    y: .value("Close", point.close)
                )
                .foregroundStyle(.yellow)
                
                AreaMark(
                    x: .value("Time", point.date),
                    yStart: .value("Close", clampedLowerBound),
                    yEnd: .value("Close", point.close)
                )
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            .yellow.opacity(0.3),
                            .yellow.opacity(0.15),
                            .yellow.opacity(0.05),
                            .clear
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            
            if showCrosshair, let cVal = crosshairValue {
                // Vertical crosshair line
                RuleMark(x: .value("Crosshair Time", cVal.date))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                    .foregroundStyle(Color.white.opacity(0.7))
                    .annotation(position: .top, alignment: .center) {
                        VStack(spacing: 4) {
                            Text(cVal.date, format: .dateTime.hour().minute())
                                .font(.caption2)
                                .foregroundColor(.white)
                            Text(formatWithCommas(cVal.close))
                                .font(.caption2)
                                .foregroundColor(.white)
                        }
                        .padding(6)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.black.opacity(0.8))
                        )
                    }
                
                // Horizontal crosshair line
                RuleMark(y: .value("Crosshair Price", cVal.close))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                    .foregroundStyle(Color.white.opacity(0.7))
                
            }
        }
        .chartYScale(domain: clampedLowerBound...upperBound)
        .chartXScale(domain: firstDate...lastDate)
        .chartXScale(range: 0.05...0.95)
        .chartPlotStyle { plotArea in
                    plotArea
                        .background(Color.black.opacity(0.05))
                }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: axisLabelCount)) { value in
                AxisGridLine()
                    .foregroundStyle(.white.opacity(0.2))
                
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(formatAxisDate(date))
                            .font(.system(size: 10))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) {
                AxisGridLine()
                    .foregroundStyle(.white.opacity(0.2))
                
                AxisValueLabel()
                    .foregroundStyle(.white)
                    .font(.footnote)
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geo in
                Rectangle().fill(Color.clear).contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { drag in
                                showCrosshair = true
                                let location = drag.location
                                
                                if #available(iOS 17.0, *) {
                                    if let anchor = proxy.plotFrame {
                                        let origin = geo[anchor].origin
                                        let relativeX = location.x - origin.x
                                        if let date: Date = proxy.value(atX: relativeX) {
                                            if let closest = findClosest(date: date, in: vm.dataPoints) {
                                                crosshairValue = closest
                                            }
                                        }
                                    }
                                } else {
                                    let origin = geo[proxy.plotAreaFrame].origin
                                    let relativeX = location.x - origin.x
                                    if let date: Date = proxy.value(atX: relativeX) {
                                        if let closest = findClosest(date: date, in: vm.dataPoints) {
                                            crosshairValue = closest
                                        }
                                    }
                                }
                            }
                            .onEnded { _ in
                                showCrosshair = false
                            }
                    )
            }
        }
        .overlay(
            LinearGradient(gradient: Gradient(colors: [.clear, .black.opacity(0.5)]),
                           startPoint: .top,
                           endPoint: .bottom)
                .frame(height: 40)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .allowsHitTesting(false)
        )
    }
    
    private func errorView(_ errorMsg: String) -> some View {
        VStack(spacing: 10) {
            Text("Error loading chart")
                .foregroundColor(.red)
                .font(.headline)
            Text(errorMsg)
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Button("Retry") {
                vm.fetchBinanceData(symbol: symbol,
                                    interval: interval.binanceInterval,
                                    limit: interval.binanceLimit)
            }
            .foregroundColor(.black)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.yellow)
            .cornerRadius(8)
        }
        .padding()
    }
    
    private func formatAxisDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = .current
        
        switch interval {
        case .oneMin, .fiveMin:
            df.dateFormat = "h:mm a"
        case .fifteenMin, .thirtyMin, .oneHour, .fourHour:
            df.dateFormat = "ha"
        case .oneDay, .oneWeek, .oneMonth, .threeMonth:
            let day = Calendar.current.component(.day, from: date)
            df.dateFormat = (day == 1) ? "MMM" : "MMM d"
        default:
            df.dateFormat = "MMM yyyy"
        }
        return df.string(from: date)
    }
    
    private func formatTimeLocalHM(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = .current
        df.dateFormat = "h:mm a"
        return df.string(from: date)
    }
    
    private func formatTimeLocal(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = .current
        df.dateFormat = "ha"
        return df.string(from: date)
    }
    
    private func findClosest(date: Date, in points: [ChartDataPoint]) -> ChartDataPoint? {
        guard !points.isEmpty else { return nil }
        let sorted = points.sorted { $0.date < $1.date }
        if date <= sorted.first!.date { return sorted.first! }
        if date >= sorted.last!.date { return sorted.last! }
        
        var closest = sorted.first!
        var minDiff = abs(closest.date.timeIntervalSince(date))
        for point in sorted {
            let diff = abs(point.date.timeIntervalSince(date))
            if diff < minDiff {
                minDiff = diff
                closest = point
            }
        }
        return closest
    }
    
    private func formatWithCommas(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        if value < 1 {
            formatter.maximumFractionDigits = 4
        } else if value < 1000 {
            formatter.maximumFractionDigits = 2
        } else {
            formatter.maximumFractionDigits = 0
        }
        return "$" + (formatter.string(from: NSNumber(value: value)) ?? String(value))
    }
}

// MARK: - TradeViewTradingWebView
struct TradeViewTradingWebView: UIViewRepresentable {
    let symbol: String
    let interval: String
    let theme: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        loadHTML(into: webView)
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        loadHTML(into: uiView)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    private func loadHTML(into webView: WKWebView) {
        let html = """
        <!DOCTYPE html>
        <html>
          <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
              html, body { margin: 0; padding: 0; height: 100%; background: transparent; }
              #tv_chart_container { width:100%; height:100%; }
            </style>
          </head>
          <body>
            <div id="tv_chart_container"></div>
            <script src="https://www.tradingview.com/tv.js"></script>
            <script>
              try {
                new TradingView.widget({
                  "container_id": "tv_chart_container",
                  "symbol": "\(symbol)",
                  "interval": "\(interval)",
                  "timezone": "Etc/UTC",
                  "theme": "\(theme)",
                  "style": "1",
                  "locale": "en",
                  "toolbar_bg": "#f1f3f6",
                  "enable_publishing": false,
                  "allow_symbol_change": true,
                  "autosize": true
                });
              } catch(e) {
                document.body.innerHTML = "<h3 style='color:yellow;text-align:center;margin-top:40px;'>TradingView is blocked in your region.</h3>";
              }
            </script>
          </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: URL(string: "https://www.tradingview.com"))
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView,
                     didFinish navigation: WKNavigation!) {
            print("TradingView content finished loading.")
        }
        
        func webView(_ webView: WKWebView,
                     didFail navigation: WKNavigation!,
                     withError error: Error) {
            fallbackMessage(in: webView)
        }
        
        func webView(_ webView: WKWebView,
                     didFailProvisionalNavigation navigation: WKNavigation!,
                     withError error: Error) {
            fallbackMessage(in: webView)
        }
        
        private func fallbackMessage(in webView: WKWebView) {
            let fallbackHTML = """
            <html><body style="background:transparent;color:yellow;text-align:center;padding-top:40px;">
            <h3>TradingView is blocked in your region or unavailable.</h3>
            <p>Try a VPN or different region.</p>
            </body></html>
            """
            webView.loadHTMLString(fallbackHTML, baseURL: nil)
        }
    }
}
