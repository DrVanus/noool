//
//  ConversationHistoryView.swift
//  CSAI1
//
//  Lists all saved conversations with options to select, delete, rename, and pin/unpin them.
//  Also includes a "New Chat" button in the navigation bar.
//

import SwiftUI

struct ConversationHistoryView: View {
    @State private var showRenameAlert = false
    @State private var renameText = ""
    @State private var convoToRename: Conversation? = nil
    
    @State private var searchText = ""
    @State private var showDeleteAlert = false
    @State private var convoToDelete: Conversation? = nil
    
    // MARK: - External callbacks
    let conversations: [Conversation]
    let onSelectConversation: (Conversation) -> Void
    let onNewChat: () -> Void
    let onDeleteConversation: (Conversation) -> Void
    let onRenameConversation: (Conversation, String) -> Void
    let onTogglePin: (Conversation) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            List {
                // 1) If no pinned & no unpinned, show a placeholder
                if pinnedConversations.isEmpty && unpinnedConversations.isEmpty {
                    Text("No conversations found.")
                        .foregroundColor(.gray)
                        .listRowBackground(Color.clear)
                } else {
                    // 2) Group pinned and unpinned in separate sections
                    if !pinnedConversations.isEmpty {
                        Section(header: Text("Pinned")) {
                            ForEach(pinnedConversations) { convo in
                                conversationRow(convo)
                                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                    .listRowBackground(Color.clear)
                            }
                        }
                    }
                    
                    Section(header: Text("All Conversations")) {
                        ForEach(unpinnedConversations) { convo in
                            conversationRow(convo)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .listRowBackground(Color.clear)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search Conversations")
            .listStyle(.insetGrouped) // a more modern iOS look
            .navigationTitle("Conversations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("New Chat") {
                        onNewChat()
                        dismiss()
                    }
                    .foregroundColor(.yellow)
                }
            }
            // Background gradient
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.black, Color.gray.opacity(0.2)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            // Rename alert
            .alert("Rename Conversation", isPresented: $showRenameAlert) {
                TextField("New Title", text: $renameText)
                Button("Save") {
                    if let convo = convoToRename {
                        onRenameConversation(convo, renameText)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Enter a new title:")
            }
        }
        // Delete confirmation alert
        .alert("Delete Conversation?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let convo = convoToDelete {
                    onDeleteConversation(convo)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this conversation?")
        }
    }
    
    // MARK: - Conversation Row
    /// Returns the row UI for a single conversation with:
    /// - 3-dot menu for Pin/Unpin & Rename (with icons)
    /// - Context menu for Pin/Unpin, Rename, **and Delete** (with icons) on long press
    /// - Trailing swipe for Delete (with icon)
    private func conversationRow(_ convo: Conversation) -> some View {
        HStack {
            // Show a pin icon if pinned
            if convo.pinned {
                Image(systemName: "pin.fill")
                    .foregroundColor(.yellow)
                    .padding(.trailing, 4)
            }
            
            // Main button to select conversation
            Button {
                onSelectConversation(convo)
                dismiss()
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(convo.title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    // Show the last message's text/timestamp if it exists
                    if let lastMsg = convo.messages.last {
                        Text(lastMsg.text)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                        
                        Text(formattedDate(lastMsg.timestamp))
                            .font(.caption2)
                            .foregroundColor(.gray)
                    } else {
                        // If no messages, show creation date + # of msgs
                        Text("Started \(formattedDate(convo.createdAt)) • \(convo.messages.count) msgs")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 4)
            }
            
            Spacer()
            
            // 3-dot menu for Pin/Unpin & Rename (with icons)
            Menu {
                Button {
                    onTogglePin(convo)
                } label: {
                    Label(convo.pinned ? "Unpin" : "Pin",
                          systemImage: convo.pinned ? "pin.slash" : "pin.fill")
                }
                Button {
                    convoToRename = convo
                    renameText = convo.title
                    showRenameAlert = true
                } label: {
                    Label("Rename", systemImage: "pencil")
                }
                // Delete at the bottom (destructive)
                Divider() // optional separator
                Button(role: .destructive) {
                    convoToDelete = convo
                    showDeleteAlert = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundColor(.white)
                    .font(.title3)
                    .padding(.trailing, 8)
            }
        }
        // Only one swipe action: Delete
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                convoToDelete = convo
                showDeleteAlert = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        // Context menu for long-press with the same Pin/Unpin & Rename (with icons)
        // + a "Delete" option at the bottom, like ChatGPT.
        .contextMenu {
            // Pin/Unpin
            Button {
                onTogglePin(convo)
            } label: {
                Label(convo.pinned ? "Unpin" : "Pin",
                      systemImage: convo.pinned ? "pin.slash" : "pin.fill")
            }
            // Rename
            Button {
                convoToRename = convo
                renameText = convo.title
                showRenameAlert = true
            } label: {
                Label("Rename", systemImage: "pencil")
            }
            // Delete at the bottom (destructive)
            Divider() // optional separator
            Button(role: .destructive) {
                convoToDelete = convo
                showDeleteAlert = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    // MARK: - Filtering & Sorting
    private var pinnedConversations: [Conversation] {
        filteredConversations.filter { $0.pinned }
    }
    private var unpinnedConversations: [Conversation] {
        filteredConversations.filter { !$0.pinned }
    }
    
    private var filteredConversations: [Conversation] {
        let base = searchText.isEmpty
            ? conversations
            : conversations.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                ($0.messages.last?.text.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        return base
    }
    
    // MARK: - Date Formatting
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }
}
