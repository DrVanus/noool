import SwiftUI

/// Official 3commas brand color (#14c9bc)
private let threeCommasColor = Color(red: 0.078, green: 0.784, blue: 0.737)

struct PortfolioPaymentMethodsView: View {
    @Environment(\.presentationMode) var presentationMode
    
    // Toggles the sheet for linking 3commas
    @State private var showLinkSheet = false
    
    // Toggles the collapsible info panel
    @State private var showInfoPanel = false
    
    // Toggles the hidden NavigationLink for “View All Exchanges & Wallets”
    @State private var showExchanges = false
    
    // Mock data for demonstration
    @State private var connectedExchanges: [ConnectedExchange] = [
        ConnectedExchange(name: "3commas (Binance)", isDefault: true),
        ConnectedExchange(name: "Coinbase", isDefault: false)
    ]
    
    // For deletion confirmation
    @State private var exchangeToRemove: ConnectedExchange?
    @State private var showRemoveConfirmation = false
    
    // For setting default confirmation
    @State private var exchangeToMakeDefault: ConnectedExchange?
    @State private var showMakeDefaultConfirmation = false
    
    // For renaming
    @State private var exchangeToRename: ConnectedExchange?
    @State private var renameText: String = ""
    @State private var showRenameSheet = false
    
    var body: some View {
        NavigationView {
            List {
                // PHANTOM ROW (fixes first-swipe glitch)
                Section {
                    PhantomSwipeRow()
                        .frame(height: 0.1)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
                
                // SECTION 1: Header Content
                Section {
                    ZStack {
                        // Subtle black accent circle behind the header text
                        Circle()
                            .fill(Color.black.opacity(0.3))
                            .frame(width: 300, height: 300)
                            .blur(radius: 30)
                            .offset(y: -180)
                            .scaleEffect(1.3)
                            .allowsHitTesting(false)
                        
                        VStack(spacing: 16) {
                            Text("Payment Methods")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.top, 20)
                            
                            // Main header
                            Text("Connect Your Exchanges & Wallets")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)
                            
                            // Subtitle
                            Text("Link your crypto exchange accounts and wallets to trade directly from within the app.")
                                .foregroundColor(.white.opacity(0.85))
                                .multilineTextAlignment(.center)
                                .lineLimit(3)
                                .minimumScaleFactor(0.85)
                                .padding(.horizontal, 20)
                            
                            // “Link Now (3commas)” button
                            Button {
                                showLinkSheet = true
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "link.circle.fill")
                                        .font(.title2)
                                    Text("Link Now (3commas)")
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(threeCommasColor)
                                .cornerRadius(12)
                                .shadow(color: threeCommasColor.opacity(0.4), radius: 6, x: 0, y: 4)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            .padding(.horizontal, 40)
                            
                            // “View All Exchanges & Wallets” button
                            Button {
                                showExchanges = true
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "link.circle.fill")
                                        .font(.title2)
                                    Text("View All Exchanges & Wallets")
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 4)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            .padding(.horizontal, 40)
                            
                            // Hidden NavigationLink
                            NavigationLink(
                                destination: ExchangesView(),
                                isActive: $showExchanges
                            ) {
                                EmptyView()
                            }
                            .frame(width: 0, height: 0)
                            .opacity(0)
                            
                            // “Show Info” button placed higher
                            Button {
                                withAnimation(.spring()) {
                                    showInfoPanel.toggle()
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: showInfoPanel ? "questionmark.circle.fill" : "questionmark.circle")
                                        .font(.title3)
                                    Text(showInfoPanel ? "Hide Info" : "Show Info")
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            
                            // Collapsible info panel (with improved spring animation)
                            if showInfoPanel {
                                InfoCardView(
                                    title: "How It Works",
                                    message: """
                                    By linking your exchange or wallet via 3commas, you establish a secure API connection. Your credentials remain protected on 3commas servers, and CryptoSage AI only accesses your trading and balance data. Once connected, you can:
                                    • Track real-time balances across your exchanges and portfolio
                                    • Place trades from one unified interface
                                    • Monitor markets and adjust positions quickly
                                    • Leverage our AI insights to optimize your portfolio
                                    """
                                )
                                .transition(.move(edge: .top).combined(with: .opacity))
                                
                                InfoCardView(
                                    title: "Need Help?",
                                    message: """
                                    For detailed setup instructions or troubleshooting, visit our Support page. Contact us directly if you have any questions about linking your accounts and wallets.
                                    """
                                )
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }
                        }
                        .padding(.top, 10)
                        .padding(.bottom, 30)
                    }
                    .frame(maxWidth: .infinity)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                
                // SECTION 2: Connected Accounts
                if !connectedExchanges.isEmpty {
                    Section(header: Text("Connected Accounts").foregroundColor(.white)) {
                        ForEach(connectedExchanges) { exchange in
                            HStack(spacing: 12) {
                                Text(exchange.name)
                                    .foregroundColor(.white)
                                    .font(.body)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                if exchange.isDefault {
                                    Text("Default")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            LinearGradient(
                                                colors: [Color.green.opacity(0.7), Color.green],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .cornerRadius(8)
                                        .foregroundColor(.black)
                                }
                            }
                            .padding(12)
                            .listRowBackground(
                                Group {
                                    if #available(iOS 15.0, *) {
                                        Color.clear.background(.ultraThinMaterial)
                                    } else {
                                        Color.black.opacity(0.25)
                                    }
                                }
                            )
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 4)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowSeparator(.hidden)
                            // SWIPE ACTIONS
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    exchangeToRemove = exchange
                                    showRemoveConfirmation = true
                                } label: {
                                    Label("Remove", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                if !exchange.isDefault {
                                    Button {
                                        exchangeToMakeDefault = exchange
                                        showMakeDefaultConfirmation = true
                                    } label: {
                                        Label("Make Default", systemImage: "star.fill")
                                    }
                                    .tint(.orange)
                                }
                                Button {
                                    exchangeToRename = exchange
                                    renameText = exchange.name
                                    showRenameSheet = true
                                } label: {
                                    Label("Rename", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    exchangeToRemove = exchange
                                    showRemoveConfirmation = true
                                } label: {
                                    Label("Remove Exchange", systemImage: "trash")
                                }
                                if !exchange.isDefault {
                                    Button {
                                        exchangeToMakeDefault = exchange
                                        showMakeDefaultConfirmation = true
                                    } label: {
                                        Label("Make Default", systemImage: "star.fill")
                                    }
                                }
                                Button {
                                    exchangeToRename = exchange
                                    renameText = exchange.name
                                    showRenameSheet = true
                                } label: {
                                    Label("Rename Exchange", systemImage: "pencil")
                                }
                            }
                        }
                    }
                }
                
                // SECTION 3: Disclaimer
                Section {
                    Text("All exchange connections are handled securely via 3commas.\nYour credentials are never stored on our servers.")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 20)
                }
                .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
            .background(FuturisticBackground())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Custom white icon-only back button
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            }
            // 3commas Link Sheet
            .sheet(isPresented: $showLinkSheet) {
                Link3CommasView()
            }
            // Confirmation dialog for removing
            .confirmationDialog(
                "Remove \(exchangeToRemove?.name ?? "this exchange")?",
                isPresented: $showRemoveConfirmation,
                titleVisibility: .visible
            ) {
                Button("Remove Exchange", role: .destructive) {
                    if let doomed = exchangeToRemove {
                        removeExchange(doomed)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to remove this exchange?")
            }
            // Confirmation dialog for making default
            .confirmationDialog(
                "Make \(exchangeToMakeDefault?.name ?? "this exchange") the default?",
                isPresented: $showMakeDefaultConfirmation,
                titleVisibility: .visible
            ) {
                Button("Set as Default") {
                    if let chosen = exchangeToMakeDefault {
                        setAsDefault(chosen)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to make this exchange the default?")
            }
            // Rename Sheet
            .sheet(isPresented: $showRenameSheet) {
                RenameExchangeSheet(exchangeName: $renameText) {
                    if let ex = exchangeToRename {
                        renameExchange(ex, newName: renameText)
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Helper Methods
    
    private func removeExchange(_ exchange: ConnectedExchange) {
        if let index = connectedExchanges.firstIndex(where: { $0.id == exchange.id }) {
            connectedExchanges.remove(at: index)
        }
    }
    
    private func setAsDefault(_ exchange: ConnectedExchange) {
        for i in connectedExchanges.indices {
            connectedExchanges[i].isDefault = false
        }
        if let index = connectedExchanges.firstIndex(where: { $0.id == exchange.id }) {
            connectedExchanges[index].isDefault = true
        }
    }
    
    private func renameExchange(_ exchange: ConnectedExchange, newName: String) {
        if let index = connectedExchanges.firstIndex(where: { $0.id == exchange.id }) {
            connectedExchanges[index].name = newName
        }
    }
}

// MARK: - Models & Additional Views

struct ConnectedExchange: Identifiable {
    let id = UUID()
    var name: String
    var isDefault: Bool
}

/// A hidden row that “warms up” SwiftUI’s swipe actions to prevent the first-swipe glitch.
struct PhantomSwipeRow: View {
    var body: some View {
        Color.clear
            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                Button("") {}
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button("") {}
            }
    }
}

/// A simple sheet to rename an exchange.
struct RenameExchangeSheet: View {
    @Binding var exchangeName: String
    var onSave: () -> Void
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Exchange Nickname")) {
                    TextField("Enter nickname", text: $exchangeName)
                }
                Section {
                    Button("Save") {
                        onSave()
                        presentationMode.wrappedValue.dismiss()
                    }
                    Button("Cancel", role: .cancel) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .navigationTitle("Rename Exchange")
        }
    }
}

/// An informational card with a glassy background.
struct InfoCardView: View {
    let title: String
    let message: String
    
    var body: some View {
        ZStack {
            if #available(iOS 15.0, *) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
            } else {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.black.opacity(0.4))
            }
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(message)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.leading)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 12)
            }
            .padding(.vertical, 16)
        }
        .padding(.horizontal, 24)
        .padding(.top, 10)
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}
