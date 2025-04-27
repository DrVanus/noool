import SwiftUI
import UIKit

/// Official 3commas brand color (#14c9bc)
private let threeCommasColor = Color(red: 0.078, green: 0.784, blue: 0.737)

struct Link3CommasView: View {
    @Environment(\.presentationMode) var presentationMode

    @State private var apiKey: String = ""
    @State private var apiSecret: String = ""
    @State private var isSaving: Bool = false

    var body: some View {
        ZStack {
            // Use the FuturisticBackground defined in Theme.swift
            FuturisticBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom top bar with a back arrow
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("3commas Link")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    // Extra space for symmetry
                    Spacer().frame(width: 24)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                VStack(spacing: 20) {
                    Text("Enter Your 3commas API Credentials")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.top, 20)
                    
                    // Form-like fields
                    VStack(spacing: 16) {
                        TextField("API Key", text: $apiKey)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                            .foregroundColor(.white)
                        
                        SecureField("API Secret", text: $apiSecret)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 32)
                    
                    // Save button
                    Button(action: saveCredentials) {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Save")
                                    .fontWeight(.semibold)
                            }
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(threeCommasColor)
                        .cornerRadius(12)
                        .shadow(color: threeCommasColor.opacity(0.4), radius: 6, x: 0, y: 4)
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 10)
                    
                    VStack(spacing: 6) {
                        // Direct link to 3commas
                        Button(action: {
                            if let url = URL(string: "https://3commas.io/") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            Text("Need an API key? Visit 3commas.io")
                                .foregroundColor(.white.opacity(0.8))
                                .underline()
                        }
                        
                        // Alternative approach explanation
                        Text("Or connect from 'View All Exchanges & Wallets' if you prefer.")
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .font(.footnote)
                    }
                    .padding(.top, 8)
                    
                    Spacer()
                }
                .padding(.bottom, 40)
            }
        }
        // Hide the default navigation bar so only our custom top bar is visible
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
    }
    
    private func saveCredentials() {
        isSaving = true
        Task {
            do {
                let success = try await ThreeCommasAPI.shared.connect(apiKey: apiKey, apiSecret: apiSecret)
                await MainActor.run {
                    isSaving = false
                    if success {
                        presentationMode.wrappedValue.dismiss()
                    } else {
                        print("Error connecting to 3commas: invalid credentials")
                    }
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    print("Error connecting to 3commas: \(error.localizedDescription)")
                }
            }
        }
    }
}

struct Link3CommasView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            Link3CommasView()
        }
    }
}
