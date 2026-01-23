//
//  NotificationManager.swift
//  StoicCamarade Watch App
//
//  Handles scheduling and managing daily wisdom notifications
//

import Foundation
import UserNotifications
import SwiftUI
import Combine

class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()

    @Published var isAuthorized = false
    @Published var pendingNotifications: [UNNotificationRequest] = []

    private let notificationCenter = UNUserNotificationCenter.current()

    // Notification identifiers
    private let morningNotificationId = "stoic_morning_wisdom"
    private let eveningNotificationId = "stoic_evening_wisdom"
    private let customNotificationPrefix = "stoic_custom_"

    override init() {
        super.init()
        notificationCenter.delegate = self
        checkAuthorizationStatus()
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                self.isAuthorized = granted
            }
            return granted
        } catch {
            print("Notification authorization error: \(error)")
            return false
        }
    }

    func checkAuthorizationStatus() {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    // MARK: - Schedule Notifications

    func scheduleAllNotifications() async {
        let settings = PersistenceManager.shared.notificationSettings

        // Remove all existing scheduled notifications first
        await removeAllScheduledNotifications()

        // Schedule morning notification
        if settings.morningEnabled {
            await scheduleDailyNotification(
                id: morningNotificationId,
                time: settings.morningTime,
                title: "Morning Wisdom",
                body: "Start your day with stoic guidance",
                context: "morning"
            )
        }

        // Schedule evening notification
        if settings.eveningEnabled {
            await scheduleDailyNotification(
                id: eveningNotificationId,
                time: settings.eveningTime,
                title: "Evening Reflection",
                body: "End your day with stoic wisdom",
                context: "evening"
            )
        }

        // Schedule custom notifications
        if settings.customEnabled {
            for (index, time) in settings.customTimes.enumerated() {
                await scheduleDailyNotification(
                    id: "\(customNotificationPrefix)\(index)",
                    time: time,
                    title: "Stoic Wisdom",
                    body: "Take a moment for reflection",
                    context: "general"
                )
            }
        }

        // Refresh pending list
        await refreshPendingNotifications()
    }

    private func scheduleDailyNotification(
        id: String,
        time: Date,
        title: String,
        body: String,
        context: String
    ) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = ["context": context]

        // Create date components for daily trigger
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.hour = calendar.component(.hour, from: time)
        dateComponents.minute = calendar.component(.minute, from: time)

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        do {
            try await notificationCenter.add(request)
            if Config.debugMode {
                print("✅ Scheduled notification: \(id) at \(dateComponents.hour ?? 0):\(dateComponents.minute ?? 0)")
            }
        } catch {
            print("❌ Failed to schedule notification: \(error)")
        }
    }

    // MARK: - Remove Notifications

    func removeAllScheduledNotifications() async {
        notificationCenter.removeAllPendingNotificationRequests()
        await refreshPendingNotifications()
    }

    func removeNotification(withId id: String) async {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [id])
        await refreshPendingNotifications()
    }

    // MARK: - Query Notifications

    func refreshPendingNotifications() async {
        let pending = await notificationCenter.pendingNotificationRequests()
        await MainActor.run {
            self.pendingNotifications = pending
        }
    }

    // MARK: - Quick Actions

    func scheduleOneTimeNotification(
        inMinutes minutes: Int,
        title: String = "Stoic Reminder",
        body: String = "Time for a moment of reflection"
    ) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(minutes * 60),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "stoic_reminder_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
        } catch {
            print("Failed to schedule one-time notification: \(error)")
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        // Show notification even when app is in foreground
        return [.banner, .sound]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        // Handle notification tap - could open to specific quote context
        let userInfo = response.notification.request.content.userInfo
        if let context = userInfo["context"] as? String {
            // Post notification to open app with specific context
            NotificationCenter.default.post(
                name: .stoicNotificationTapped,
                object: nil,
                userInfo: ["context": context]
            )
        }
    }
}

// MARK: - Notification Name Extension

extension Notification.Name {
    static let stoicNotificationTapped = Notification.Name("stoicNotificationTapped")
}
