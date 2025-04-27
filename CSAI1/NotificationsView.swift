//
//  AlertRowView.swift
//  CSAI1
//
//  Created by DM on 4/23/25.
//


//
//  NotificationsView.swift
//  CSAI1
//

import SwiftUI

struct AlertRowView: View {
  let alert: PriceAlert   // your alert model

  var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text(alert.symbol)
          .font(.headline)
          .foregroundColor(.white)
        Text(alert.isAbove
               ? "Above \(String(format: "%.2f", alert.threshold))"
               : "Below \(String(format: "%.2f", alert.threshold))")
          .font(.subheadline)
          .foregroundColor(.gray)
      }
      Spacer()
      HStack(spacing: 12) {
        if alert.enablePush    { Image(systemName: "bell.fill") }
        if alert.enableEmail   { Image(systemName: "envelope.fill") }
        if alert.enableTelegram{ Image(systemName: "paperplane.fill") }
      }
      .foregroundColor(.yellow)
    }
    .padding()
    .background(Color("CardBackground"))
    .cornerRadius(12)
    .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
    .padding(.vertical, 6)
  }
}

struct AlertSwipeRowView: View {
  let alert: PriceAlert
  private let notificationsManager = NotificationsManager.shared

  var body: some View {
    AlertRowView(alert: alert)
      .swipeActions(edge: .trailing, allowsFullSwipe: false) {
        // Delete action
        Button(role: .destructive) {
          if let idx = notificationsManager.alerts.firstIndex(where: { $0.id == alert.id }) {
            notificationsManager.removeAlerts(at: IndexSet(integer: idx))
          }
        } label: {
          Label("Delete", systemImage: "trash")
        }
      }
  }
}

struct NotificationsView: View {
  @ObservedObject private var notificationsManager = NotificationsManager.shared
  @State private var showAddAlert = false

  var body: some View {
    makeContent()
  }

  @ViewBuilder
  private func makeContent() -> some View {
    NavigationView {
        if notificationsManager.alerts.isEmpty {
            emptyStateView()
        } else {
            alertsListView()
        }
    }
    .listStyle(.insetGrouped)
    .scrollContentBackground(.hidden)
    .background(Color("BackgroundColor").edgesIgnoringSafeArea(.all))
    .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
            EditButton()
                .font(.headline)
                .foregroundColor(.yellow)
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: { showAddAlert = true }) {
                ZStack {
                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 32, height: 32)
                    Image(systemName: "plus")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    .sheet(isPresented: $showAddAlert) {
        AddAlertView()
    }
  }

  @ViewBuilder
  private func emptyStateView() -> some View {
    VStack(spacing: 16) {
        Spacer()
        Image(systemName: "bell.slash.fill")
            .font(.system(size: 64))
            .foregroundColor(.gray)
            .padding(.bottom, 8)
        Text("No Price Alerts")
            .font(.title2)
            .foregroundColor(.white)
        Text("Tap the + button to create your first alert.")
            .font(.subheadline)
            .foregroundColor(.gray)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
            .padding(.bottom, 16)
        Button(action: { showAddAlert = true }) {
            Label("Create Alert", systemImage: "plus.circle.fill")
                .font(.headline)
                .padding()
                .background(Color.yellow)
                .foregroundColor(.black)
                .cornerRadius(8)
        }
        Spacer()
    }
    .navigationTitle("Price Alerts")
  }

  @ViewBuilder
  private func alertsListView() -> some View {
    List {
        Section(header: Text("Active Price Alerts")
                    .font(.headline)
                    .foregroundColor(.yellow)
                    .padding(.top, 8)) {
            ForEach(notificationsManager.alerts) { alert in
                AlertSwipeRowView(alert: alert)
            }
            .onDelete { notificationsManager.removeAlerts(at: $0) }
        }
    }
    .listRowSeparator(.hidden)
    .listRowBackground(Color.clear)
    .navigationTitle("Price Alerts")
  }
}
