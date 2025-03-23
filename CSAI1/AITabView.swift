//
//  AITabView.swift
//  CSAI1
//
//  Multi-conversation chat view. Displays the active conversation’s messages,
//  provides quick replies, and includes a sheet for conversation history
//  where you can rename, delete, and pin/unpin threads.
//

import SwiftUI

// MARK: - ChatBubble
/// A chat bubble (or no-bubble) view for a single ChatMessage, aiming for a ChatGPT-like style:
/// - AI: White text, no bubble, left-aligned.
/// - User: Dark gray bubble, white text, right-aligned.
/// - Error: Red bubble, white text, right-aligned.
struct ChatBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .top) {
            if message.sender == "ai" {
                // AI on the left
                aiView
                Spacer()
            } else {
                // User (or error) on the right
                Spacer()
                userOrErrorView
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
    
    /// AI messages: white text, no bubble, left-aligned.
    private var aiView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(message.text)
                .font(.system(size: 16))
                .foregroundColor(.white)
            
            // Optional timestamp
            Text(formattedTime(message.timestamp))
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
        }
    }
    
    /// User messages or error messages: bubble with white text, right-aligned.
    private var userOrErrorView: some View {
        let bubbleColor: Color = message.isError ? Color.red.opacity(0.8) : Color(UIColor.darkGray)
        
        return VStack(alignment: .trailing, spacing: 4) {
            Text(message.text)
                .font(.system(size: 16))
                .foregroundColor(.white)
            
            // Optional timestamp
            Text(formattedTime(message.timestamp))
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(12)
        .background(bubbleColor)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
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
    
    // Example quick replies
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
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    // 1) Custom principal item to show conversation title, truncated if too long
                    ToolbarItem(placement: .principal) {
                        Text(activeConversationTitle())
                            .font(.headline)
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    
                    // 2) Left icon for conversation history
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            showHistory.toggle()
                        } label: {
                            Image(systemName: "text.bubble") // Choose any SF Symbol you like
                                .imageScale(.large)
                        }
                        .foregroundColor(.white)
                        // Show conversation history sheet
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
                                    if let idx = conversations.firstIndex(where: { $0.id == convo.id }) {
                                        conversations.remove(at: idx)
                                        if convo.id == activeConversationID {
                                            activeConversationID = conversations.first?.id
                                        }
                                        saveConversations()
                                    }
                                },
                                onRenameConversation: { convo, newTitle in
                                    if let idx = conversations.firstIndex(where: { $0.id == convo.id }) {
                                        var updated = conversations[idx]
                                        updated.title = newTitle.isEmpty ? "Untitled Chat" : newTitle
                                        conversations[idx] = updated
                                        saveConversations()
                                    }
                                },
                                // Pin/unpin
                                onTogglePin: { convo in
                                    guard let idx = conversations.firstIndex(where: { $0.id == convo.id }) else { return }
                                    conversations[idx].pinned.toggle()
                                    saveConversations()
                                }
                            )
                            .presentationDetents([.medium, .large])
                            .presentationDragIndicator(.visible)
                        }
                    }
                }
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
    /// Main chat content view
    private var chatBodyView: some View {
        ZStack(alignment: .bottom) {
            // Solid black background
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Scrollable chat area
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
                
                // Input bar
                inputBar()
            }
        }
    }
    
    /// Returns the title for the active conversation
    private func activeConversationTitle() -> String {
        guard let activeID = activeConversationID,
              let convo = conversations.first(where: { $0.id == activeID }) else {
            return "AI Chat"
        }
        return convo.title
    }
    
    /// "Thinking" indicator row
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
    
    /// Horizontal quick replies bar
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
        
        // If the conversation is "Untitled Chat" and this is the first message, update the title
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
