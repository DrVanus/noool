import SwiftUI

// MARK: - TradingBotView
struct TradingBotView: View {
    let side: TradeSide
    let orderType: OrderType
    let quantity: Double
    let slippage: Double
    init(
        side: TradeSide,
        orderType: OrderType,
        quantity: Double,
        slippage: Double
    ) {
        self.side = side
        self.orderType = orderType
        self.quantity = quantity
        self.slippage = slippage
    }
    // MARK: - Bot Creation Modes
    enum BotCreationMode: String, CaseIterable {
        case aiChat = "AI Chat"
        case dcaBot = "DCA Bot"
        case gridBot = "Grid Bot"
        case signalBot = "Signal Bot"
    }
    
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss

    // MARK: - State Variables
    @State private var selectedMode: BotCreationMode = .aiChat
    
    // MARK: - For AI Chat – using your AI chat view model
    @StateObject private var aiChatVM = AiChatViewModel()
    
    // MARK: - DCA Bot State
    @State private var botName: String = ""
    @State private var selectedExchange: String = "Binance"
    @State private var selectedDirection: String = "Long"
    @State private var selectedBotType: String = "Single-pair"
    @State private var selectedProfitCurrency: String = "Quote"
    @State private var selectedTradingPairDCA: String = "BTC_USDT"
    
    @State private var baseOrderSize: String = ""
    @State private var selectedStartOrderType: String = "Market"
    @State private var selectedTradeCondition: String = "RSI"
    
    @State private var averagingOrderSize: String = ""
    @State private var priceDeviation: String = ""
    @State private var maxAveragingOrders: String = ""
    @State private var averagingOrderStepMultiplier: String = ""
    
    @State private var takeProfit: String = ""
    @State private var selectedTakeProfitType: String = "Single Target"
    @State private var trailingEnabled: Bool = false
    @State private var revertProfit: Bool = false
    @State private var stopLossEnabled: Bool = false
    @State private var stopLossValue: String = ""
    @State private var maxHoldPeriod: String = ""
    
    @State private var isAdvancedViewExpanded: Bool = false
    @State private var balanceInfo: String = "0.00 USDT"
    @State private var maxAmountForBotUsage: String = ""
    @State private var maxAveragingPriceDeviation: String = ""
    
    // MARK: - Grid Bot State
    @State private var gridBotName: String = ""
    @State private var gridSelectedExchange: String = "Binance"
    @State private var gridSelectedTradingPair: String = "BTC_USDT"
    @State private var gridLowerPrice: String = ""
    @State private var gridUpperPrice: String = ""
    @State private var gridLevels: String = ""
    @State private var gridOrderVolume: String = ""
    @State private var gridTakeProfit: String = ""
    @State private var gridStopLossEnabled: Bool = false
    @State private var gridStopLossValue: String = ""
    
    // MARK: - Signal Bot State
    @State private var signalBotName: String = ""
    @State private var signalSelectedExchange: String = "Binance"
    @State private var signalSelectedPairs: String = "BTC_USDT"
    @State private var signalMaxUsage: String = ""
    @State private var signalPriceDeviation: String = ""
    @State private var signalEntriesLimit: String = ""
    @State private var signalTakeProfit: String = ""
    @State private var signalStopLossEnabled: Bool = false
    @State private var signalStopLossValue: String = ""
    @State private var isRunning: Bool = false
    @State private var statusMessage: String = "Idle"
    
    // MARK: - Option Arrays for Pickers
    private let exchangeOptions = ["Binance", "Coinbase", "KuCoin", "Bitfinex"]
    private let directionOptions = ["Long", "Short", "Neutral"]
    private let botTypeOptions = ["Single-pair", "Multi-pair"]
    private let profitCurrencyOptions = ["Quote", "Base"]
    private let tradingPairsOptions = ["BTC_USDT", "ETH_USDT", "SOL_USDT", "ADA_USDT"]
    
    private let startOrderTypes = ["Market", "Limit", "Stop", "Stop-Limit"]
    private let tradeConditions = ["RSI", "QFL", "MACD", "Custom Condition"]
    private let takeProfitTypes = ["Single Target", "Multiple Targets", "Trailing TP"]
    
    var body: some View {
        VStack(spacing: 0) {
            customNavBar
            Divider()
            Group {
                switch selectedMode {
                case .aiChat:
                    AiChatTabView(viewModel: aiChatVM)
                case .dcaBot:
                    dcaBotView
                case .gridBot:
                    gridBotView
                case .signalBot:
                    signalBotView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(UIColor.systemBackground).edgesIgnoringSafeArea(.bottom))
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Custom Navigation Bar (Without Manage Button)
extension TradingBotView {
    private var customNavBar: some View {
        VStack(spacing: 0) {
            // Top row: Custom back button, centered title, invisible icon for symmetry.
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.yellow)
                }
                Spacer()
                Text("Trading Bot")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                // Invisible duplicate for symmetric spacing
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .opacity(0)
            }
            .padding(.horizontal)
            .padding(.top, 12)
            
            // Segmented control for mode selection
            Picker("", selection: $selectedMode) {
                ForEach(TradingBotView.BotCreationMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.black)
            .overlay(
                Rectangle()
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 1),
                alignment: .bottom
            )
        }
        .background(Color.black)
    }
    
    // A helper function to dismiss the view.
    private func dismissView() {
        // If this view was presented modally, dismiss it.
        // Otherwise, if it was pushed on a NavigationView, you might use
        // the environment's presentationMode (or use a dedicated NavigationStack/PresentationLink).
        #if os(iOS)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }
}

// MARK: - AI Chat View & Models
struct AiChatTabView: View {
    @ObservedObject var viewModel: AiChatViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(viewModel.messages) { message in
                        AiChatBubble(message: message)
                    }
                }
                .padding(.top, 12)
                .padding(.horizontal, 16)
            }
            .background(Color.black)
            
            Button(action: {
                print("Generate Bot Config tapped")
            }) {
                Text("Generate Bot Config")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundColor(.black)
                    .background(Color.yellow)
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
            }
            .padding(.top, 8)
            
            MyAIChatInputBar(text: $viewModel.userInput, onSend: { text in
                viewModel.sendMessage(text)
            })
        }
        .background(Color.black)
        .onAppear {
            viewModel.fetchInitialMessageIfNeeded()
        }
    }
}

class AiChatViewModel: ObservableObject {
    @Published var messages: [AiChatMessage] = []
    @Published var userInput: String = ""
    
    func fetchInitialMessageIfNeeded() {
        if messages.isEmpty {
            let initial = AiChatMessage(
                text: "Hello! I'm your AI trading assistant. Would you like to configure a DCA Bot, a Grid Bot, or something else?",
                isUser: false,
                timestamp: Date()
            )
            messages.append(initial)
        }
    }
    
    func sendMessage(_ text: String) {
        let userMsg = AiChatMessage(text: text, isUser: true, timestamp: Date())
        messages.append(userMsg)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let aiMsg = AiChatMessage(text: "AI response: \(text)", isUser: false, timestamp: Date())
            self.messages.append(aiMsg)
        }
    }
}

struct AiChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let timestamp: Date
}

struct AiChatBubble: View {
    let message: AiChatMessage
    
    var body: some View {
        VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
            Text(message.text)
                .padding()
                .foregroundColor(message.isUser ? .black : .white)
                .background(message.isUser ? Color.yellow : Color.clear)
                .cornerRadius(12)
            
            if !message.isUser {
                Text(formattedTimestamp(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(.leading, message.isUser ? 0 : 8)
                    .padding(.trailing, message.isUser ? 8 : 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: message.isUser ? .trailing : .leading)
        .padding(message.isUser ? .leading : .trailing, 40)
        .padding(.vertical, 2)
    }
    
    private func formattedTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct MyAIChatInputBar: View {
    @Binding var text: String
    var onSend: (String) -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            TextField("Enter your strategy...", text: $text)
                .padding(.vertical, 12)
                .padding(.horizontal, 12)
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
                .foregroundColor(.white)
            Button(action: {
                guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                onSend(text)
                text = ""
            }) {
                Text("Send")
                    .font(.system(size: 16, weight: .semibold))
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
                    .background(Color.yellow)
                    .foregroundColor(.black)
                    .cornerRadius(12)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.black)
    }
}

// MARK: - DCA Bot View
extension TradingBotView {
    private var dcaBotView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    sectionHeader("Main")
                    textFieldRow(title: "Bot Name", text: $botName)
                    labelPickerRow(title: "Exchange", selection: $selectedExchange, options: exchangeOptions)
                    HStack(spacing: 20) {
                        labelPickerRow(title: "Direction", selection: $selectedDirection, options: directionOptions)
                        labelPickerRow(title: "Bot Type", selection: $selectedBotType, options: botTypeOptions)
                    }
                    HStack(spacing: 20) {
                        labelPickerRow(title: "Trading Pairs", selection: $selectedTradingPairDCA, options: tradingPairsOptions)
                        labelPickerRow(title: "Profit Currency", selection: $selectedProfitCurrency, options: profitCurrencyOptions)
                    }
                }
                Group {
                    sectionHeader("Entry Order")
                    textFieldRow(title: "Base Order Size", text: $baseOrderSize)
                    labelPickerRow(title: "Start Order Type", selection: $selectedStartOrderType, options: startOrderTypes)
                    labelPickerRow(title: "Trade Start Condition", selection: $selectedTradeCondition, options: tradeConditions)
                }
                Group {
                    sectionHeader("Averaging Order")
                    textFieldRow(title: "Averaging Order Size", text: $averagingOrderSize)
                    textFieldRow(title: "Price Deviation", text: $priceDeviation)
                    textFieldRow(title: "Max Averaging Orders", text: $maxAveragingOrders)
                    textFieldRow(title: "Averaging Order Step Multiplier", text: $averagingOrderStepMultiplier)
                }
                Group {
                    sectionHeader("Exit Order")
                    textFieldRow(title: "Take Profit (%)", text: $takeProfit)
                    labelPickerRow(title: "Take Profit Type", selection: $selectedTakeProfitType, options: takeProfitTypes)
                    Toggle(isOn: $trailingEnabled) {
                        Text("Trailing").foregroundColor(.white)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: Color.yellow))
                    Toggle(isOn: $revertProfit) {
                        Text("Reinvert Profit").foregroundColor(.white)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: Color.yellow))
                    Toggle(isOn: $stopLossEnabled) {
                        Text("Stop Loss").foregroundColor(.white)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: Color.yellow))
                    if stopLossEnabled {
                        textFieldRow(title: "Stop Loss (%)", text: $stopLossValue)
                        textFieldRow(title: "Max Hold Period (days)", text: $maxHoldPeriod)
                    }
                }
                Group {
                    sectionHeader("Advanced")
                    DisclosureGroup(isExpanded: $isAdvancedViewExpanded) {
                        textFieldRow(title: "Balance", text: $balanceInfo, disabled: true)
                        textFieldRow(title: "Max Amount for Bot Usage", text: $maxAmountForBotUsage)
                        textFieldRow(title: "Max Averaging Price Deviation", text: $maxAveragingPriceDeviation)
                    } label: {
                        Text("Advanced Settings")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.yellow)
                    }
                    .accentColor(.yellow)
                }
                Group {
                    sectionHeader("Summary")
                    VStack(spacing: 6) {
                        Text("Balance: \(balanceInfo)").foregroundColor(.white)
                        Text("Max for bot usage: \(maxAmountForBotUsage.isEmpty ? "N/A" : maxAmountForBotUsage)")
                            .foregroundColor(.white)
                        Text("Price deviation: \(maxAveragingPriceDeviation.isEmpty ? "N/A" : maxAveragingPriceDeviation)")
                            .foregroundColor(.white)
                    }
                }
                Button {
                    createDcaBot()
                } label: {
                    Text("Create DCA Bot")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundColor(.white)
                        .background(Color.green)
                        .cornerRadius(12)
                }
                .padding(.top, 10)
                Spacer(minLength: 30)
            }
            .padding(16)
        }
        .background(Color.black)
    }
    
    private func createDcaBot() {
        print("DCA Bot created: \(botName), Exchange: \(selectedExchange), Direction: \(selectedDirection), Pair: \(selectedTradingPairDCA)")
    }
}

// MARK: - Grid Bot View
extension TradingBotView {
    private var gridBotView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    sectionHeader("Main")
                    textFieldRow(title: "Grid Bot Name", text: $gridBotName)
                    labelPickerRow(title: "Exchange", selection: $gridSelectedExchange, options: exchangeOptions)
                    labelPickerRow(title: "Trading Pair", selection: $gridSelectedTradingPair, options: tradingPairsOptions)
                }
                Group {
                    sectionHeader("Grid Settings")
                    textFieldRow(title: "Lower Price", text: $gridLowerPrice, placeholder: "e.g. 30000")
                    textFieldRow(title: "Upper Price", text: $gridUpperPrice, placeholder: "e.g. 40000")
                    textFieldRow(title: "Grid Levels", text: $gridLevels, placeholder: "Number of grid levels")
                    textFieldRow(title: "Order Volume", text: $gridOrderVolume, placeholder: "Volume per grid order")
                }
                Group {
                    sectionHeader("Exit Settings")
                    textFieldRow(title: "Take Profit (%)", text: $gridTakeProfit)
                    Toggle(isOn: $gridStopLossEnabled) {
                        Text("Enable Stop Loss").foregroundColor(.white)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: Color.yellow))
                    if gridStopLossEnabled {
                        textFieldRow(title: "Stop Loss (%)", text: $gridStopLossValue)
                    }
                }
                Button {
                    createGridBot()
                } label: {
                    Text("Create Grid Bot")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundColor(.white)
                        .background(Color.green)
                        .cornerRadius(12)
                }
                .padding(.top, 10)
                Spacer(minLength: 30)
            }
            .padding(16)
        }
        .background(Color.black)
    }
    
    private func createGridBot() {
        print("Grid Bot created: \(gridBotName), Exchange: \(gridSelectedExchange), Pair: \(gridSelectedTradingPair)")
    }
}

// MARK: - Signal Bot View
extension TradingBotView {
    private var signalBotView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    sectionHeader("Main")
                    textFieldRow(title: "Signal Bot Name", text: $signalBotName)
                    labelPickerRow(title: "Exchange", selection: $signalSelectedExchange, options: exchangeOptions)
                    labelPickerRow(title: "Pairs", selection: $signalSelectedPairs, options: tradingPairsOptions)
                }
                Group {
                    sectionHeader("Settings")
                    textFieldRow(title: "Max Investment Usage", text: $signalMaxUsage, placeholder: "e.g. 500 USD")
                    textFieldRow(title: "Price Deviation", text: $signalPriceDeviation)
                    textFieldRow(title: "Max Entry Orders", text: $signalEntriesLimit, placeholder: "Number of entry orders")
                }
                Group {
                    sectionHeader("Exit Settings")
                    textFieldRow(title: "Take Profit (%)", text: $signalTakeProfit)
                    Toggle(isOn: $signalStopLossEnabled) {
                        Text("Stop Loss Enabled").foregroundColor(.white)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: Color.yellow))
                    if signalStopLossEnabled {
                        textFieldRow(title: "Stop Loss (%)", text: $signalStopLossValue)
                    }
                }
                Button {
                    createSignalBot()
                } label: {
                    Text("Create Signal Bot")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundColor(.white)
                        .background(Color.green)
                        .cornerRadius(12)
                }
                .padding(.top, 10)
                Spacer(minLength: 30)
            }
            .padding(16)
        }
        .background(Color.black)
    }
    
    private func createSignalBot() {
        print("Signal Bot created: \(signalBotName), Exchange: \(signalSelectedExchange), Pairs: \(signalSelectedPairs)")
    }
}

// MARK: - Shared Helpers
extension TradingBotView {
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.yellow)
    }
    
    private func textFieldRow(title: String,
                              text: Binding<String>,
                              placeholder: String? = nil,
                              disabled: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.white)
            TextField(placeholder ?? title, text: text)
                .disabled(disabled)
                .padding(12)
                .background(disabled ? Color.gray.opacity(0.3) : Color.white.opacity(0.1))
                .foregroundColor(.white)
                .cornerRadius(10)
        }
    }
    
    private func labelPickerRow(title: String,
                                selection: Binding<String>,
                                options: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.white)
            Picker(title, selection: selection) {
                ForEach(options, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .accentColor(.yellow)
            .padding(10)
            .background(Color.white.opacity(0.1))
            .cornerRadius(10)
        }
    }
}

// MARK: - Chat Message Model
extension TradingBotView {
    struct ChatMessage: Identifiable {
        let id = UUID()
        let text: String
        let isUser: Bool
    }
}

// MARK: - Preview
struct TradingBotView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TradingBotView(side: .buy,
                           orderType: .market,
                           quantity: 0.0,
                           slippage: 0.0)
        }
        .preferredColorScheme(.dark)
    }
}
