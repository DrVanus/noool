//
//  AITabView.swift
//  CSAI1
//
//  Multi-conversation chat view. Displays the active conversation’s messages,
//  provides quick replies, and includes a sheet for conversation history
//  where you can rename or delete threads.
//

import SwiftUI

// MARK: - ChatBubble
/// A simple bubble view for a single ChatMessage (user or AI).
struct ChatBubble: View {
    let message: ChatMessage
    
    // Gradients for user, AI, and error messages
    private let userBubbleGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 0.85, green: 0.7, blue: 0.1),
            Color(red: 0.9, green: 0.8, blue: 0.2)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    private let aiBubbleGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 0.5, green: 0.5, blue: 0.5, opacity: 0.4),
            Color(red: 0.6, green: 0.6, blue: 0.6, opacity: 0.8)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    private let errorBubbleGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color.red.opacity(0.4),
            Color.red.opacity(0.8)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var body: some View {
        HStack {
            if message.sender == "ai" {
                bubbleContent(isAI: true)
                Spacer(minLength: 10)
            } else {
                Spacer(minLength: 10)
                bubbleContent(isAI: false)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
    
    /// Renders the message text inside a gradient bubble
    private func bubbleContent(isAI: Bool) -> some View {
        let textColor: Color = isAI ? .white : .black
        
        return Text(message.text)
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(textColor)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(
                        message.isError
                        ? errorBubbleGradient
                        : (isAI ? aiBubbleGradient : userBubbleGradient)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            )
    }
}

// MARK: - AITabView (Main Chat View)
struct AITabView: View {
    // All stored conversations
    @State private var conversations: [Conversation] = []
    // Which conversation is currently active
    @State private var activeConversationID: UUID? = nil
    
    // Controls whether the history sheet is shown
    @State private var showHistory = false
    
    // The user's chat input
    @State private var chatText: String = ""
    // Whether the AI is "thinking"
    @State private var isThinking: Bool = false
    
    // Example quick replies (just text)
    private let quickReplies = [
        "Compare with BTC",
        "Show me a price chart",
        "What is DeFi?"
    ]
    
    // Computed: returns the messages for the active conversation
    private var currentMessages: [ChatMessage] {
        guard let activeID = activeConversationID,
              let index = conversations.firstIndex(where: { $0.id == activeID }) else {
            return []
        }
        return conversations[index].messages
    }
    
    var body: some View {
        NavigationView {
            // The main chat UI
            chatBodyView
                // The title is the active conversation's title
                .navigationTitle(activeConversationTitle())
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    // Left: History icon
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            showHistory.toggle()
                        } label: {
                            Image(systemName: "list.bullet.rectangle")
                                .imageScale(.large)
                        }
                        .foregroundColor(.white)
                        // Show the conversation history sheet
                        .sheet(isPresented: $showHistory) {
                            ConversationHistoryView(
                                conversations: conversations,
                                onSelectConversation: { convo in
                                    activeConversationID = convo.id
                                    showHistory = false
                                    saveConversations()
                                },
                                onNewChat: {
                                    let newConvo = Conversation(title: "Untitled Chat")
                                    conversations.append(newConvo)
                                    activeConversationID = newConvo.id
                                    showHistory = false
                                    saveConversations()
                                },
                                onDeleteConversation: { convo in
                                    // remove the conversation entirely
                                    if let idx = conversations.firstIndex(where: { $0.id == convo.id }) {
                                        conversations.remove(at: idx)
                                        // if that was the active convo, pick a new one or none
                                        if convo.id == activeConversationID {
                                            activeConversationID = conversations.first?.id
                                        }
                                        saveConversations()
                                    }
                                },
                                onRenameConversation: { convo, newTitle in
                                    // rename
                                    if let idx = conversations.firstIndex(where: { $0.id == convo.id }) {
                                        var updated = conversations[idx]
                                        updated.title = newTitle.isEmpty ? "Untitled Chat" : newTitle
                                        conversations[idx] = updated
                                        saveConversations()
                                    }
                                }
                            )
                            .presentationDetents([.medium, .large])
                            .presentationDragIndicator(.visible)
                        }
                    }
                    
                    // Right: If you want to keep "Clear Chat," uncomment below:
                    /*
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Clear Chat") {
                            clearActiveConversation()
                        }
                        .foregroundColor(.white)
                    }
                    */
                }
                // On appear, load from storage and pick a conversation
                .onAppear {
                    loadConversations()
                    if activeConversationID == nil, let first = conversations.first {
                        activeConversationID = first.id
                    }
                }
        }
    }
}

// MARK: - Subviews & Helpers
extension AITabView {
    
    /// A separate subview to reduce complexity in body
    private var chatBodyView: some View {
        ZStack(alignment: .bottom) {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color.gray.opacity(0.2)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // The main scrollable chat area
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(currentMessages) { msg in
                                ChatBubble(message: msg)
                                    .id(msg.id)
                            }
                            if isThinking {
                                thinkingIndicator()
                            }
                        }
                        .padding(.vertical)
                    }
                    .onChange(of: currentMessages.count) { _ in
                        withAnimation {
                            if let lastID = currentMessages.last?.id {
                                scrollProxy.scrollTo(lastID, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Quick replies
                quickReplyBar()
                
                // The input bar
                inputBar()
            }
        }
    }
    
    /// Returns the title for the active conversation (or "AI Chat" if none)
    private func activeConversationTitle() -> String {
        guard let activeID = activeConversationID,
              let convo = conversations.first(where: { $0.id == activeID }) else {
            return "AI Chat"
        }
        return convo.title
    }
    
    /// A simple row showing a "thinking" indicator
    private func thinkingIndicator() -> some View {
        HStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
            Text("CryptoSage is thinking...")
                .foregroundColor(.white)
                .font(.caption)
            Spacer()
        }
        .padding(.horizontal)
    }
    
    /// Horizontal scroll of quick reply buttons
    private func quickReplyBar() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(quickReplies, id: \.self) { reply in
                    Button(reply) {
                        handleQuickReply(reply)
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.yellow.opacity(0.25))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.yellow.opacity(0.4), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
            // helps prevent accidental taps when swiping horizontally
            .simultaneousGesture(DragGesture(minimumDistance: 10))
        }
        .background(Color.black.opacity(0.3))
    }
    
    /// The bottom input bar for typing messages
    private func inputBar() -> some View {
        HStack {
            TextField("Ask your AI...", text: $chatText)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .padding(10)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
            
            Button(action: sendMessage) {
                Text("Send")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.yellow.opacity(0.8))
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.6))
    }
    
    /// Sends a user message to the active conversation and simulates an AI reply
    private func sendMessage() {
        guard let activeID = activeConversationID,
              let index = conversations.firstIndex(where: { $0.id == activeID }) else {
            // If no active conversation, create a new one
            let newConvo = Conversation(title: "Untitled Chat")
            conversations.append(newConvo)
            activeConversationID = newConvo.id
            saveConversations()
            return
        }
        
        let trimmed = chatText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        var convo = conversations[index]
        let userMsg = ChatMessage(sender: "user", text: trimmed)
        convo.messages.append(userMsg)
        
        // If the conversation is still "Untitled Chat" and this is the first message
        if convo.title == "Untitled Chat" && convo.messages.count == 1 {
            convo.title = String(trimmed.prefix(20)) + (trimmed.count > 20 ? "..." : "")
        }
        
        conversations[index] = convo
        chatText = ""
        saveConversations()
        
        // Simulate AI thinking
        isThinking = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            guard let idx = self.conversations.firstIndex(where: { $0.id == self.activeConversationID }) else { return }
            var updatedConvo = self.conversations[idx]
            
            let success = Bool.random()
            if success {
                let aiText = self.generateMockResponse(for: trimmed)
                let aiMsg = ChatMessage(sender: "ai", text: aiText)
                updatedConvo.messages.append(aiMsg)
            } else {
                let errMsg = ChatMessage(sender: "ai", text: "AI failed to respond. Please try again.", isError: true)
                updatedConvo.messages.append(errMsg)
            }
            self.conversations[idx] = updatedConvo
            self.isThinking = false
            self.saveConversations()
        }
    }
    
    /// A simple mock response generator
    private func generateMockResponse(for userText: String) -> String {
        """
        I see you asked about "\(userText)".
        (Mock) For real data, I'd query CryptoSage AI!
        """
    }
    
    /// Called when a user taps a quick reply
    private func handleQuickReply(_ reply: String) {
        chatText = reply
        sendMessage()
    }
    
    /// Clears all messages in the active conversation (optional)
    private func clearActiveConversation() {
        guard let activeID = activeConversationID,
              let index = conversations.firstIndex(where: { $0.id == activeID }) else { return }
        var convo = conversations[index]
        convo.messages.removeAll()
        conversations[index] = convo
        saveConversations()
    }
}

// MARK: - Persistence
extension AITabView {
    /// Saves the array of conversations to UserDefaults
    private func saveConversations() {
        do {
            let data = try JSONEncoder().encode(conversations)
            UserDefaults.standard.set(data, forKey: "csai_conversations")
        } catch {
            print("Failed to encode conversations: \(error)")
        }
    }
    
    /// Loads the array of conversations from UserDefaults
    private func loadConversations() {
        guard let data = UserDefaults.standard.data(forKey: "csai_conversations") else { return }
        do {
            conversations = try JSONDecoder().decode([Conversation].self, from: data)
        } catch {
            print("Failed to decode conversations: \(error)")
        }
    }
}
