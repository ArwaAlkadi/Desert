//
//  NotificationsManager.swift
//  Desert
//
//  Manages all local notifications for active desert trips.
//
//  Responsibilities:
//  1. Requesting notification permission (called once from HomeViewModel.onAppear)
//  2. Scheduling safety reminders when Firebase upload fails and trip is overdue
//  3. Cancelling all notifications when a trip ends or upload succeeds
//  4. Showing notifications even when the app is in the foreground
//
//  Notification schedule (when offline and overdue):
//  - 5 min:  "No Signal Detected"
//  - 30 min: "Safety Reminder"
//  - 60 min: "Stay With Your Vehicle"
//

import Foundation
import UserNotifications
import Combine

class NotificationsManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {

    static let shared = NotificationsManager()

    /// Whether the user has granted notification permission.
    @Published var isAuthorized: Bool = false

    override init() {
        super.init()
        // Show notifications even when app is in foreground
        UNUserNotificationCenter.current().delegate = self
    }

    // MARK: - Request Permission
    /// Requests notification permission from the user.
    /// Called once from HomeViewModel.onAppear on the second app visit.
    /// Subsequent calls are ignored by iOS if permission was already decided.
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound]
        ) { granted, _ in
            DispatchQueue.main.async {
                self.isAuthorized = granted
                print("NotificationsManager: permission granted = \(granted)")
            }
        }
    }

    // MARK: - Foreground Presentation
    /// Allows notifications to appear while the app is in the foreground.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    // MARK: - Schedule Return Time Reminder
    /// Schedules a notification at the trip's return time.
    /// Called when a trip starts — iOS fires it automatically at the right time.
    /// Cancelled when the trip ends normally or the user updates the return time.
    func scheduleReturnTimeReminder(returnTime: Date) {
        guard returnTime > Date() else { return }

        scheduleNotification(
            title: "notification_return_time_title".localized,
            body:  "notification_return_time_body".localized,
            date:  returnTime
        )

        print("NotificationsManager: return time reminder scheduled for \(returnTime)")
    }

    // MARK: - Schedule Overdue Notifications
    /// Schedules escalating safety reminders when a trip becomes overdue.
    ///
    /// Called by TripSessionManager in two cases:
    /// 1. checkIfOverdue() — timer detects return time has passed
    /// 2. uploadLocationToCloud() onFailure — upload fails and trip is overdue
    ///
    /// Cancels existing notifications before scheduling new ones to avoid duplicates.
    func scheduleOverdueNotifications() {
        cancelAllNotifications()

        let now = Date()

        let schedule: [(titleKey: String, bodyKey: String, delay: TimeInterval)] = [
            (
                titleKey: "notification_no_signal_title",
                bodyKey:  "notification_no_signal_body",
                delay:    60 * 5
            ),
            (
                titleKey: "notification_safety_reminder_title",
                bodyKey:  "notification_safety_reminder_body",
                delay:    60 * 30
            ),
            (
                titleKey: "notification_stay_vehicle_title",
                bodyKey:  "notification_stay_vehicle_body",
                delay:    60 * 60
            )
        ]

        for item in schedule {
            scheduleNotification(
                title: item.titleKey.localized,
                body:  item.bodyKey.localized,
                date:  now.addingTimeInterval(item.delay)
            )
        }

        print("NotificationsManager: overdue notifications scheduled")
    }

    // MARK: - Cancel All Notifications
    /// Cancels all pending local notifications.
    ///
    /// Called when:
    /// - Trip ends normally ("I'm Back Safely")
    /// - Firebase upload succeeds (network restored)
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("NotificationsManager: all notifications cancelled")
    }

    // MARK: - Schedule Single Notification
    /// Internal helper — schedules one notification at a specific date.
    private func scheduleNotification(title: String, body: String, date: Date) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body  = body
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("NotificationsManager: failed to schedule — \(error.localizedDescription)")
            }
        }
    }
}
