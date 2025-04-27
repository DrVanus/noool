//
//  AddAlertView.swift
//  CSAI1
//
//  Created by DM on 4/23/25.
//


//
//  AddAlertView.swift
//  CryptoSageAI
//
//  Created by DM on 4/23/25.
//


import SwiftUI

struct AddAlertView: View {
  @Environment(\.presentationMode) private var presentationMode
  @ObservedObject private var notificationsManager = NotificationsManager.shared

  @State private var symbol: String = ""
  @State private var thresholdText: String = ""
  @State private var showSymbolInfo: Bool = false
  @State private var showThresholdInfo: Bool = false
  @State private var isAbove: Bool = true
  @State private var enablePush: Bool = true
  @State private var enableEmail: Bool = false
  @State private var enableTelegram: Bool = false
  @State private var showAdvancedOptions: Bool = false
  @State private var selectedExchange: String = ""
  @State private var tradingPair: String = ""
  @State private var takeProfitText: String = ""
  @State private var stopLossText: String = ""
  @State private var currentPrice: Double? = nil

  private let allSymbols = ["BTCUSDT", "ETHUSDT", "SOLUSDT", "ADAUSDT", "DOGEUSDT", "BNBUSDT"]
  private var symbolSuggestions: [String] {
    guard !symbol.isEmpty else { return allSymbols }
    return allSymbols.filter { $0.lowercased().contains(symbol.lowercased()) }
  }

  var body: some View {
    makeForm()
  }

  @ViewBuilder
  private func makeForm() -> some View {
    List {
      Section(header: Text("Alert Details")
                    .font(.headline)
                    .foregroundColor(.yellow)) {
        HStack {
          TextField("Symbol (e.g. BTCUSD)", text: $symbol)
            .autocapitalization(.allCharacters)
            .onChange(of: symbol) { _ in
              Task { await fetchCurrentPrice() }
            }
          Button(action: { showSymbolInfo = true }) {
            Image(systemName: "questionmark.circle")
          }
          .popover(isPresented: $showSymbolInfo) {
            Text("Enter the trading pair symbol as recognized by Binance, e.g., BTCUSDT, ETHUSDT.")
              .padding()
          }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        if let price = currentPrice {
          Text("Current price: \(String(format: "%.2f", price))")
            .font(.caption)
            .foregroundColor(.secondary)
        }
        HStack {
          TextField("Threshold", text: $thresholdText)
            .keyboardType(.decimalPad)
          Button(action: { showThresholdInfo = true }) {
            Image(systemName: "questionmark.circle")
          }
          .popover(isPresented: $showThresholdInfo) {
            Text("The price level at which you want to be alerted. Must be a numeric value.")
              .padding()
          }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(8)

        if !thresholdText.isEmpty && Double(thresholdText) == nil {
          Text("⚠️ Must be a number")
            .font(.caption)
            .foregroundColor(.red)
            .padding(.leading, 8)
        }
        Toggle("Notify when price is above threshold", isOn: $isAbove)
          .toggleStyle(SwitchToggleStyle(tint: .yellow))
        Toggle("Push Notifications", isOn: $enablePush)
          .toggleStyle(SwitchToggleStyle(tint: .yellow))
        Toggle("Email Notifications", isOn: $enableEmail)
          .toggleStyle(SwitchToggleStyle(tint: .yellow))
        Toggle("Telegram Notifications", isOn: $enableTelegram)
          .toggleStyle(SwitchToggleStyle(tint: .yellow))
        DisclosureGroup("Advanced Options", isExpanded: $showAdvancedOptions) {
          VStack(alignment: .leading, spacing: 16) {
            // Exchange picker
            Text("Exchange")
              .font(.subheadline)
              .foregroundColor(.secondary)
            Picker("Select Exchange", selection: $selectedExchange) {
              ForEach(["Binance", "Coinbase", "Kraken"], id: \.self) {
                Text($0)
              }
            }
            .pickerStyle(MenuPickerStyle())

            // Trading pair input
            TextField("Trading Pair (e.g. BTCUSD)", text: $tradingPair)
              .autocapitalization(.allCharacters)
              .padding(8)
              .background(Color(.systemGray6))
              .cornerRadius(8)

            // Take-profit input
            TextField("Take Profit (%)", text: $takeProfitText)
              .keyboardType(.decimalPad)
              .padding(8)
              .background(Color(.systemGray6))
              .cornerRadius(8)

            // Stop-loss input
            TextField("Stop Loss (%)", text: $stopLossText)
              .keyboardType(.decimalPad)
              .padding(8)
              .background(Color(.systemGray6))
              .cornerRadius(8)
          }
          .padding(.top, 8)
        }
        .accentColor(.yellow)
      }
      .listRowBackground(Color("CardBackground"))

      Section {
        Button(action: {
          guard let threshold = Double(thresholdText),
                !symbol.isEmpty else { return }
          notificationsManager.addAlert(
            symbol: symbol.uppercased(),
            threshold: threshold,
            isAbove: isAbove,
            enablePush: enablePush,
            enableEmail: enableEmail,
            enableTelegram: enableTelegram
          )
          presentationMode.wrappedValue.dismiss()
        }) {
          Text("Save Alert")
        }
        .buttonStyle(.borderedProminent)
        .tint(.yellow)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .disabled(symbol.isEmpty || thresholdText.isEmpty)
      }
      .listRowBackground(Color("CardBackground"))
    }
    .searchable(
      text: $symbol,
      placement: .navigationBarDrawer(displayMode: .always),
      prompt: "Symbol (e.g. BTCUSDT)"
    ) {
      ForEach(symbolSuggestions, id: \.self) { suggestion in
        Text(suggestion).searchCompletion(suggestion)
      }
    }
    .listStyle(.insetGrouped)
    .scrollContentBackground(.hidden)
    .background(Color("BackgroundColor").edgesIgnoringSafeArea(.all))
    .navigationTitle("New Price Alert")
    .toolbar {
      ToolbarItem(placement: .navigationBarLeading) {
        Button(action: { presentationMode.wrappedValue.dismiss() }) {
          Image(systemName: "xmark")
            .font(.headline)
            .foregroundColor(.yellow)
        }
        .buttonStyle(PlainButtonStyle())
      }
    }
    .tint(.yellow)
  }

  // Simple model for Binance price response
  private struct PriceResponse: Codable {
    let price: String
  }

  // Fetch current price for the entered symbol
  private func fetchCurrentPrice() async {
    guard !symbol.isEmpty else {
      currentPrice = nil
      return
    }
    let urlString = "https://api.binance.com/api/v3/ticker/price?symbol=\(symbol)"
    guard let url = URL(string: urlString) else { return }
    do {
      let (data, _) = try await URLSession.shared.data(from: url)
      let decoded = try JSONDecoder().decode(PriceResponse.self, from: data)
      if let value = Double(decoded.price) {
        currentPrice = value
      }
    } catch {
      print("Price fetch error:", error)
    }
  }
}

struct AddAlertView_Previews: PreviewProvider {
  static var previews: some View {
    AddAlertView()
  }
}
