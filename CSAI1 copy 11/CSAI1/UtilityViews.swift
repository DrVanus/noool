//
//  CardView.swift
//  CSAI1
//
//  Created by DM on 3/16/25.
//


//
//  UtilityViews.swift
//  CRYPTOSAI
//
//  Reusable UI components, plus ChatMessage/ChatBubble.
//

import SwiftUI

// Generic card view
struct CardView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color(UIColor.secondarySystemBackground))
            .shadow(radius: 5)
            .overlay(content)
            .padding()
    }
}

// Simple trending card
struct TrendingCard: View {
    var coin: String
    var body: some View {
        CardView {
            Text("Trending: \(coin)")
                .font(.headline)
        }
    }
}

// Basic chat message
struct ChatMessage: Identifiable {
    var id = UUID()
    var sender: String  // "user" or "ai"
    var text: String
}

// Chat bubble
struct ChatBubble: View {
    var message: ChatMessage
    var body: some View {
        HStack {
            if message.sender == "ai" { Spacer() }
            Text(message.text)
                .padding()
                .background(message.sender == "ai" ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                .cornerRadius(10)
            if message.sender == "user" { Spacer() }
        }
        .padding(message.sender == "ai" ? .leading : .trailing)
    }
}
