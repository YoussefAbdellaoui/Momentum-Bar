//
//  NotificationService.swift
//  MomentumBar
//
//  Created by Claude on behalf of Youssef Abdellaoui.
//

import Foundation
import UserNotifications
import AppKit
import Combine

/// Service for managing meeting reminder notifications
@MainActor
final class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()

    @Published var isAuthorized = false
    @Published var pendingNotifications: Set<String> = []

    private let notificationCenter = UNUserNotificationCenter.current()
    private var scheduledEventIDs: Set<String> = []

    override private init() {
        super.init()
        notificationCenter.delegate = self
        checkAuthorizationStatus()
    }

    // MARK: - Authorization

    func checkAuthorizationStatus() {
        notificationCenter.getNotificationSettings { [weak self] settings in
            Task { @MainActor in
                self?.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                isAuthorized = granted
            }
            return granted
        } catch {
            print("Notification authorization failed: \(error)")
            return false
        }
    }

    // MARK: - Schedule Notifications

    func scheduleReminder(for event: CalendarEvent, minutesBefore: Int) async {
        if !isAuthorized {
            let granted = await requestAuthorization()
            guard granted else { return }
        }

        // Don't schedule if already scheduled or event is in the past
        guard !scheduledEventIDs.contains(event.id) else { return }
        guard event.isUpcoming else { return }

        // Calculate trigger time
        let triggerDate = event.startDate.addingTimeInterval(-Double(minutesBefore * 60))
        guard triggerDate > Date() else { return }

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Upcoming Meeting"
        content.body = "\(event.title) starts in \(minutesBefore) minutes"
        content.sound = .default
        content.categoryIdentifier = "MEETING_REMINDER"

        // Add meeting link as user info if available
        if let meetingLink = event.meetingLink {
            content.userInfo = [
                "eventID": event.id,
                "meetingURL": meetingLink.url.absoluteString,
                "platform": meetingLink.platform.rawValue
            ]
        } else {
            content.userInfo = ["eventID": event.id]
        }

        // Create trigger
        let triggerComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: triggerDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)

        // Create request
        let request = UNNotificationRequest(
            identifier: "meeting-\(event.id)",
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
            scheduledEventIDs.insert(event.id)
            pendingNotifications.insert(event.id)
        } catch {
            print("Failed to schedule notification: \(error)")
        }
    }

    func scheduleReminders(for events: [CalendarEvent], minutesBefore: Int) async {
        for event in events where event.isUpcoming && !event.isAllDay {
            await scheduleReminder(for: event, minutesBefore: minutesBefore)
        }
    }

    // MARK: - Cancel Notifications

    func cancelReminder(for eventID: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["meeting-\(eventID)"])
        scheduledEventIDs.remove(eventID)
        pendingNotifications.remove(eventID)
    }

    func cancelAllReminders() {
        notificationCenter.removeAllPendingNotificationRequests()
        scheduledEventIDs.removeAll()
        pendingNotifications.removeAll()
    }

    // MARK: - Setup Categories

    func setupNotificationCategories() {
        let joinAction = UNNotificationAction(
            identifier: "JOIN_MEETING",
            title: "Join Meeting",
            options: .foreground
        )

        let dismissAction = UNNotificationAction(
            identifier: "DISMISS",
            title: "Dismiss",
            options: .destructive
        )

        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE",
            title: "Remind in 5 min",
            options: []
        )

        let meetingCategory = UNNotificationCategory(
            identifier: "MEETING_REMINDER",
            actions: [joinAction, snoozeAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )

        notificationCenter.setNotificationCategories([meetingCategory])
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationService: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        // Show notification even when app is in foreground
        return [.banner, .sound, .badge]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo

        switch response.actionIdentifier {
        case "JOIN_MEETING":
            if let urlString = userInfo["meetingURL"] as? String,
               let url = URL(string: urlString) {
                _ = await MainActor.run {
                    NSWorkspace.shared.open(url)
                }
            }

        case "SNOOZE":
            // Reschedule notification for 5 minutes later
            if let eventID = userInfo["eventID"] as? String {
                let content = response.notification.request.content.mutableCopy() as! UNMutableNotificationContent
                content.body = "Meeting starting soon!"

                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5 * 60, repeats: false)
                let request = UNNotificationRequest(
                    identifier: "meeting-snooze-\(eventID)",
                    content: content,
                    trigger: trigger
                )

                try? await center.add(request)
            }

        case UNNotificationDefaultActionIdentifier:
            // User tapped notification - try to open meeting link
            if let urlString = userInfo["meetingURL"] as? String,
               let url = URL(string: urlString) {
                _ = await MainActor.run {
                    NSWorkspace.shared.open(url)
                }
            }

        default:
            break
        }
    }
}
