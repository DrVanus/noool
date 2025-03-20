import SwiftUI

struct TradeView: View {
    @StateObject private var tradeVM = TradeViewModel()
    
    var body: some View {
        ZStack {
            // Our custom gradient from Theme.swift
            AppTheme.backgroundGradient
                .edgesIgnoringSafeArea(.all)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    
                    // MARK: - Title + Chart
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Live Chart")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(.leading, 8)
                        
                        TradingViewWebView(symbol: tradeVM.convertedSymbol, timeframe: "60")
                            .frame(height: 300)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 4)
                    }
                    
                    // MARK: - Order Card
                    VStack(alignment: .leading, spacing: 16) {
                        
                        Text("Place an Order")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Balance: $\(tradeVM.userBalance, specifier: "%.2f")")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        
                        // Symbol & Side pickers
                        HStack {
                            Picker("Symbol", selection: $tradeVM.selectedSymbol) {
                                ForEach(tradeVM.symbolOptions, id: \.self) { symbol in
                                    Text(symbol).tag(symbol)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            
                            Picker("Side", selection: $tradeVM.side) {
                                Text("Buy").tag("Buy")
                                Text("Sell").tag("Sell")
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        
                        // Order Type
                        Picker("Order Type", selection: $tradeVM.orderType) {
                            ForEach(tradeVM.orderTypes, id: \.self) { type in
                                Text(type)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        // Quantity
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Quantity")
                                .foregroundColor(.gray)
                            TextField("0.00", text: $tradeVM.quantity)
                                .keyboardType(.decimalPad)
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(8)
                                .foregroundColor(.white)
                        }
                        
                        // Price (only if not Market)
                        if tradeVM.orderType != "Market" {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Price")
                                    .foregroundColor(.gray)
                                TextField("0.00", text: $tradeVM.limitPrice)
                                    .keyboardType(.decimalPad)
                                    .padding()
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(8)
                                    .foregroundColor(.white)
                            }
                        }
                        
                        // Quick Fraction Buttons
                        HStack(spacing: 10) {
                            ForEach([0.25, 0.50, 0.75, 1.0], id: \.self) { fraction in
                                Button {
                                    tradeVM.applyFraction(fraction)
                                } label: {
                                    Text("\(Int(fraction * 100))%")
                                        .font(.subheadline)
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 16)
                                        // Use the new sage accent for fraction buttons
                                        .background(AppTheme.sageAccent)
                                        .foregroundColor(.black)
                                        .cornerRadius(8)
                                }
                            }
                        }
                        
                        // Submit Order Button
                        Button {
                            tradeVM.submitOrder()
                        } label: {
                            Text("\(tradeVM.side) \(tradeVM.selectedSymbol)")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .foregroundColor(.white)
                                .background(
                                    tradeVM.side == "Buy"
                                    ? AppTheme.sageAccent  // greenish accent
                                    : Color.red            // keep red for Sell
                                )
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    
                    // MARK: - Advanced Trading Toggle
                    Toggle("Show Advanced Trading", isOn: $tradeVM.showAdvanced)
                        .toggleStyle(SwitchToggleStyle(tint: AppTheme.sageAccent))
                        .foregroundColor(.white)
                    
                    // MARK: - Advanced Trading Section
                    if tradeVM.showAdvanced {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Order Book and Depth Chart")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("Coming Soon...")
                                .foregroundColor(.gray)
                                .font(.subheadline)
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 24)
                .padding(.bottom, 50)
            }
        }
        .navigationBarTitle("Trade", displayMode: .inline)
    }
}
