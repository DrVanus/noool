//
//  NotificationsView.swift
//  CSAI1
//
//  Created by DM on 3/24/25.
//


import SwiftUI

struct NotificationsView: View {
    @State private var priceAlerts: [PriceAlert] = [
        PriceAlert(coinSymbol: "BTC", triggerPrice: 30000),
        PriceAlert(coinSymbol: "ETH", triggerPrice: 2000)
    ]
    @State private var showAddAlertSheet = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Price Alerts")) {
                    ForEach(priceAlerts) { alert in
                        HStack {
                            Text("\(alert.coinSymbol) alert at $\(Int(alert.triggerPrice))")
                            Spacer()
                            Button("Remove") {
                                removeAlert(alert)
                            }
                            .foregroundColor(.red)
                        }
                    }
                }
                
                Button("Add New Alert") {
                    showAddAlertSheet = true
                }
            }
            .navigationTitle("Notifications & Alerts")
            .sheet(isPresented: $showAddAlertSheet) {
                AddPriceAlertView { newAlert in
                    priceAlerts.append(newAlert)
                }
            }
        }
    }
    
    func removeAlert(_ alert: PriceAlert) {
        priceAlerts.removeAll { $0.id == alert.id }
    }
}

struct PriceAlert: Identifiable {
    let id = UUID()
    let coinSymbol: String
    let triggerPrice: Double
}

struct AddPriceAlertView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State private var coinSymbol = "BTC"
    @State private var triggerPrice = ""
    
    let onSave: (PriceAlert) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Coin Symbol", text: $coinSymbol)
                TextField("Trigger Price", text: $triggerPrice)
                    .keyboardType(.decimalPad)
            }
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    if let price = Double(triggerPrice) {
                        let newAlert = PriceAlert(coinSymbol: coinSymbol.uppercased(), triggerPrice: price)
                        onSave(newAlert)
                    }
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .navigationTitle("Add Price Alert")
        }
    }
}