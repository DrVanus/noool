//
//  TradingCredentialsView.swift
//  CSAI1
//
//  Created by DM on 4/20/25.
//


import SwiftUI

struct TradingCredentialsView: View {
    @State private var apiKey: String = ""
    @State private var apiSecret: String = ""
    @State private var statusMessage: String?

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("3Commas Trading Credentials")) {
                    TextField("API Key", text: $apiKey)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    SecureField("API Secret", text: $apiSecret)
                }

                Button("Save Credentials") {
                    saveCredentials()
                }
                .frame(maxWidth: .infinity, alignment: .center)

                if let msg = statusMessage {
                    Text(msg)
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                }
            }
            .navigationTitle("Trading Credentials")
        }
    }

    private func saveCredentials() {
        do {
            try KeychainHelper.shared.save(apiKey, service: "3Commas", account: "trading_key")
            try KeychainHelper.shared.save(apiSecret, service: "3Commas", account: "trading_secret")
            statusMessage = "✅ Credentials saved in Keychain"
        } catch {
            statusMessage = "Error saving: \(error.localizedDescription)"
        }
    }
}
