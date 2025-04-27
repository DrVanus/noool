import SwiftUI
import CoreImage.CIFilterBuiltins

// MARK: - QRCodeView
/// Generates a QR code image from a provided string.
struct QRCodeView: View {
    let uriString: String
    
    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()
    
    var body: some View {
        if let qrImage = generateQRCode(from: uriString) {
            Image(uiImage: qrImage)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
        } else {
            Text("Unable to generate QR Code")
                .foregroundColor(.red)
        }
    }
    
    private func generateQRCode(from string: String) -> UIImage? {
        let data = Data(string.utf8)
        filter.setValue(data, forKey: "inputMessage")
        
        if let outputImage = filter.outputImage {
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)
            
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        return nil
    }
}

// MARK: - ExchangeConnectionView
struct ExchangeConnectionView: View {
    @Environment(\.presentationMode) var presentationMode
    
    // Use the external WalletConnectManager from WalletConnectManager.swift
    @StateObject var walletConnectManager = WalletConnectManager()
    
    // Fields for manual input
    @State private var apiKey: String = ""
    @State private var apiSecret: String = ""
    
    // Simple alert toggle to confirm manual connection
    @State private var showManualConnectAlert = false
    
    var body: some View {
        ZStack {
            // Replace with your own background or gradient
            FuturisticBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Custom Top Bar
                HStack {
                    // Back button (icon only)
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("Wallet Setup")
                        .font(.system(size: 22, weight: .bold)) // Larger & bolder
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Spacer for symmetry
                    Spacer().frame(width: 40)
                }
                .padding()
                .background(Color.black.opacity(0.2))
                
                // MARK: - Main Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        
                        // -- WalletConnect Section --
                        walletConnectCard
                        
                        // Subtle divider to separate the two sections
                        Divider()
                            .background(Color.white.opacity(0.2))
                            .padding(.horizontal, 50)
                        
                        // -- Manual Entry Section --
                        manualCard
                        
                        Spacer(minLength: 30)
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .alert("Manual Connection", isPresented: $showManualConnectAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("API Key: \(apiKey)\nAPI Secret: \(apiSecret)")
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
    }
    
    // MARK: - WalletConnect Card
    private var walletConnectCard: some View {
        VStack(spacing: 16) {
            Text("WalletConnect")
                .font(.headline)
                .foregroundColor(.white)
            
            if walletConnectManager.isPairing, let uri = walletConnectManager.pairingURI {
                // Show QR code & link if pairing is active
                Text("Scan this QR code with your wallet or tap the link below:")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                
                QRCodeView(uriString: uri)
                
                // URI link
                Text(uri)
                    .font(.footnote)
                    .foregroundColor(.blue)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .onTapGesture {
                        // Optionally handle link tap
                    }
                
                // Copy button
                Button(action: {
                    UIPasteboard.general.string = uri
                }) {
                    Label("Copy URI", systemImage: "doc.on.doc")
                        .font(.footnote)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                }
            } else {
                // Prompt to connect if not yet pairing
                Text("Use WalletConnect to link your wallet.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                
                Button(action: {
                    walletConnectManager.connect()
                }) {
                    Text("Connect via WalletConnect")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(Color.black.opacity(0.2))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
        .padding(.horizontal, 16)
        .animation(.easeInOut, value: walletConnectManager.isPairing)
    }
    
    // MARK: - Manual Card
    private var manualCard: some View {
        VStack(spacing: 16) {
            Text("Manual Setup")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Enter your API credentials manually.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
            
            // API Key
            TextField("API Key", text: $apiKey)
                .padding()
                .foregroundColor(.white)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
            
            // API Secret (masked by default, which is typical for sensitive info)
            SecureField("API Secret", text: $apiSecret)
                .padding()
                .foregroundColor(.white)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
            
            // Same gradient as the WalletConnect button
            Button(action: {
                // Show an alert as a placeholder for real logic
                showManualConnectAlert = true
            }) {
                Text("Connect Manually")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding(16)
        .background(Color.black.opacity(0.2))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
        .padding(.horizontal, 16)
    }
}

// MARK: - Preview
struct ExchangeConnectionView_Previews: PreviewProvider {
    static var previews: some View {
        ExchangeConnectionView()
    }
}
