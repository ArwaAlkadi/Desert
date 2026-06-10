//
//  NotificationsManager.swift
//  Desert
//

import Foundation
import UserNotifications
import Combine

/// Schedules and cancels all local notifications for active desert trips.
///
/// ## Responsibilities
/// 1. Requesting notification permission (called once from `HomeViewModel.onAppear`)
/// 2. Scheduling a return-time reminder and a reassurance reminder at trip start
/// 3. Cancelling the reassurance reminder when a Firebase upload confirms the user is moving
/// 4. Cancelling all notifications when a trip ends or the return time is updated
/// 5. Showing notifications even when the app is in the foreground
///
/// ## Talks To
/// - `HomeViewModel` — triggers `requestPermission()` on first visible app visit
/// - `ActiveTripSession` — calls `scheduleTripNotifications`, `cancelReassuranceNotification`, and `cancelAllNotifications`
///
/// ## Notification Schedule (fixed to `returnTime`, scheduled at trip start)
/// | Offset | Identifier | Purpose |
/// |--------|------------|---------|
/// | +0 min | `returnTime_<tripId>` | Return time reminder |
/// | +10 min | `reassurance_<tripId>` | Overdue follow-up reminder |
class NotificationsManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {

    // MARK: - Singleton

    static let shared = NotificationsManager()

    // MARK: - Published

    /// Whether the user has granted notification permission.
    @Published var isAuthorized: Bool = false

    // MARK: - Init

    override init() {
        super.init()
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

    // MARK: - Schedule All Trip Notifications

    /// Schedules both the return time reminder and the overdue notification at trip start.
    /// iOS handles firing — no app wake-up needed.
    ///
    /// Called once when a trip starts.
    /// Re-called (after cancelAllNotifications) when the user updates the return time.
    func scheduleTripNotifications(tripId: String, returnTime: Date) {
        guard returnTime > Date() else { return }

        // Return time notification — fires exactly at return time
        scheduleNotification(
            identifier: "returnTime_\(tripId)",
            title: "notification_return_time_title".localized,
            body:  "notification_return_time_body".localized,
            date:  returnTime
        )

        // Reassurance reminder — fires 10 minutes after return time
        let reassuranceDate = returnTime.addingTimeInterval(10 * 60)
        scheduleNotification(
            identifier: "reassurance_\(tripId)",
            title: "notification_reassurance_title".localized,
            body:  "notification_reassurance_body".localized,
            date:  reassuranceDate
        )

        print("NotificationsManager: trip notifications scheduled — returnTime: \(returnTime), overdue: \(reassuranceDate)")
    }

    // MARK: - Cancel Overdue Notification Only

    /// Cancels only the overdue notification.
    ///
    /// Called when Firebase upload succeeds after return time has passed —
    /// the user is fine and moving, so the overdue reminder is no longer needed.
    func cancelReassuranceNotification(tripId: String) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["reassurance_\(tripId)"])
        print("NotificationsManager: reassurance notification cancelled — \(tripId)")
    }

    // MARK: - Cancel All Notifications

    /// Cancels all pending local notifications.
    ///
    /// Called when:
    /// - Trip ends normally ("I'm Back Safely") via finishTrip()
    /// - User updates the return time — reschedule follows immediately after
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("NotificationsManager: all notifications cancelled")
    }

    // MARK: - Schedule Single Notification

    /// Internal helper — schedules one notification at a specific date with a fixed identifier.
    /// Using a fixed identifier allows targeted cancellation later.
    private func scheduleNotification(
        identifier: String,
        title: String,
        body: String,
        date: Date
    ) {
        guard date > Date() else { return }

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
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("NotificationsManager: failed to schedule \(identifier) — \(error.localizedDescription)")
            }
        }
    }
}
