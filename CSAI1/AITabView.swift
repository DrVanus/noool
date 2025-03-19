//
//  AITabView.swift
//  CSAI1
//
//  Created by DM on 3/16/25.
//


//
//  AITabView.swift
//  CRYPTOSAI
//
//  Simple AI chat screen (placeholder).
//

import SwiftUI

struct AITabView: View {
    @State private var chatText: String = ""
    @State private var messages: [ChatMessage] = []
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    ForEach(messages) { message in
                        ChatBubble(message: message)
                    }
                }
                .padding()
                
                HStack {
                    TextField("Ask your AI...", text: $chatText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("Send") {
                        sendMessage()
                    }
                }
                .padding()
            }
            .navigationTitle("AI Chat")
        }
    }
    
    func sendMessage() {
        let newMessage = ChatMessage(sender: "user", text: chatText)
        messages.append(newMessage)
        chatText = ""
        
        // Simulate AI response
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let aiResponse = ChatMessage(sender: "ai", text: "This is an AI response.")
            messages.append(aiResponse)
        }
    }
}

struct AITabView_Previews: PreviewProvider {
    static var previews: some View {
        AITabView()
    }
}
