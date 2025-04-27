//
//  ExchangeDetailViewModel.swift
//  CSAI1
//
//  Created by DM on 4/3/25.
//


//
//  ExchangeDetailView.swift
//  CSAI1
//
//  Created by [Your Name] on [Date].
//

import SwiftUI
import Combine

// MARK: - View Model

/// A simple view model to simulate connecting to a secure backend.
class ExchangeDetailViewModel: ObservableObject {
    @Published var isConnecting = false
    @Published var connectionStatus: String = "Not connected"
    
    /// Simulates a connection process to a secure backend.
    /// - Parameter exchange: The exchange or wallet to connect to.
    func connect(for exchange: ExchangeItem) {
        isConnecting = true
        connectionStatus = "Connecting to \(exchange.name)..."
        
        // Simulate a network delay (replace with real API call later)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.connectionStatus = "Connected to \(exchange.name) successfully!"
            self.isConnecting = false
        }
    }
}

// MARK: - Exchange Detail View

struct ExchangeDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    let exchange: ExchangeItem
    
    // Use the view model to handle connection logic
    @StateObject private var viewModel = ExchangeDetailViewModel()
    
    var body: some View {
        ZStack {
            // Use your custom futuristic background
            FuturisticBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Custom top bar with a back button
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text(exchange.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // For symmetry; can be an empty space or additional controls later
                    Spacer().frame(width: 24)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                Spacer()
                
                // Display the current connection status
                Text(viewModel.connectionStatus)
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                
                // Connect button
                Button(action: {
                    viewModel.connect(for: exchange)
                }) {
                    if viewModel.isConnecting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(width: 100, height: 44)
                    } else {
                        Text("Connect")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(width: 100, height: 44)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                }
                .disabled(viewModel.isConnecting)
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Preview

struct ExchangeDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            // For preview, using a sample exchange item.
            ExchangeDetailView(exchange: ExchangeItem(name: "Binance"))
        }
    }
}
