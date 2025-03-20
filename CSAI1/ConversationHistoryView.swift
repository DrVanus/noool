//
//  ConversationHistoryView.swift
//  CSAI1
//
//  Lists all saved conversations with options to select, delete, or rename them.
//  Also includes a "New Chat" button in the navigation bar.
//

import SwiftUI

struct ConversationHistoryView: View {
    @State private var showRenameAlert = false
    @State private var renameText = ""
    @State private var convoToRename: Conversation? = nil
    
    let conversations: [Conversation]
    let onSelectConversation: (Conversation) -> Void
    let onNewChat: () -> Void
    let onDeleteConversation: (Conversation) -> Void
    let onRenameConversation: (Conversation, String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(conversations) { convo in
                    Button {
                        onSelectConversation(convo)
                        dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(convo.title)
                                .font(.headline)
                                .foregroundColor(.white)
                            Text(convo.messages.last?.text ?? "")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                            Text("Started \(formattedDate(convo.createdAt)) • \(convo.messages.count) msgs")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(Color.black.opacity(0.85))
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            onDeleteConversation(convo)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        
                        Button {
                            convoToRename = convo
                            renameText = convo.title
                            showRenameAlert = true
                        } label: {
                            Label("Rename", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                }
            }
            .listStyle(.plain)
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
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.black, Color.gray.opacity(0.2)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
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
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }
}
