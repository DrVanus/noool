//
//  AppPairingContent.swift
//  CSAI1
//
//  Created by DM on 4/2/25.
//


import SwiftUI

struct AppPairingContent: View {
    var body: some View {
        ZStack {
            // A simple gradient background to set a modern tone.
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Pair Your App")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 40)
                
                Text("Follow the steps below to pair your app with your account. Make sure your device is connected and your credentials are correct.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .padding(.horizontal)
                
                Spacer()
                
                Button(action: {
                    // TODO: Implement pairing action.
                }) {
                    Text("Pair Now")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.green, Color.blue]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)
                
                Button(action: {
                    // TODO: Implement cancel action.
                }) {
                    Text("Cancel")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .padding()
                .background(Color.gray.opacity(0.7))
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)
                
                Spacer()
            }
        }
    }
}

struct AppPairingContent_Previews: PreviewProvider {
    static var previews: some View {
        AppPairingContent()
    }
}