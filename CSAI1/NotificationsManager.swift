//
//  NotificationsManager.swift
//  CSAI1
//
//  Created by DM on 4/23/25.
//


import Foundation
import Combine
import UserNotifications

final class NotificationsManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationsManager()

    @Published var alerts: [PriceAlert] = []
    private var cancellables = Set<AnyCancellable>()
    /// Timer publisher for periodic checking
    private var timerCancellable: AnyCancellable?
    private let alertsKey = "userPriceAlerts"

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        loadAlerts()
    }

    private func loadAlerts() {
        guard
            let data = UserDefaults.standard.data(forKey: alertsKey),
            let decoded = try? JSONDecoder().decode([PriceAlert].self, from: data)
        else { return }
        alerts = decoded
    }

    private func saveAlerts() {
        if let data = try? JSONEncoder().encode(alerts) {
            UserDefaults.standard.set(data, forKey: alertsKey)
        }
    }

    func addAlert(symbol: String,
                  threshold: Double,
                  isAbove: Bool,
                  enablePush: Bool,
                  enableEmail: Bool,
                  enableTelegram: Bool) {
        let new = PriceAlert(symbol: symbol,
                             threshold: threshold,
                             isAbove: isAbove,
                             enablePush: enablePush,
                             enableEmail: enableEmail,
                             enableTelegram: enableTelegram)
        alerts.append(new)
        saveAlerts()
    }

    func removeAlerts(at offsets: IndexSet) {
        alerts.remove(atOffsets: offsets)
        saveAlerts()
    }

    /// Request push notification permission from the user
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification authorization error: \(error)")
            }
        }
    }

    /// Start periodic monitoring of alerts (default every 60 seconds)
    func startMonitoring(interval: TimeInterval = 60) {
        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkAlerts()
            }
    }

    /// Stop periodic monitoring
    func stopMonitoring() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    /// Internal: runs on each timer tick to check current prices against saved alerts
    private func checkAlerts() {
        // TODO: integrate ThreeCommas API here
    }
}
