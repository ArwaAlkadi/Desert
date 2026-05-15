//
//  TripSessionManager.swift
//  Desert
//

import Foundation
import SwiftData
import CoreLocation
import Combine

/// Coordinates between LocationManager, NotificationsManager, and FirebaseManager.
///
/// ## Layer responsibilities
/// - LocationManager:       GPS only
/// - NotificationsManager:  Local notifications only
/// - FirebaseManager:       Cloud sync only
/// - TripSessionManager:    Orchestrates all of the above and owns trip lifecycle
///
/// ## Trip Status Flow
/// ```
/// "active" → (returnTime exceeded) → "overdue" → alert sent
///          → (user returns safely) → "completed"
/// ```
class TripSessionManager: NSObject, ObservableObject {

    static let shared = TripSessionManager()

    @Published var hasActiveTrip = false

    private let locationManager = LocationManager.shared
    private let notifications   = NotificationsManager.shared
    private let firebase        = FirebaseManager.shared

    // Timer that fires every 60 seconds to check if the trip is overdue.
    private var overdueTimer: Timer?

    // MARK: - Start Trip

    /// Creates a trip ID, saves locally and to Firebase, and begins GPS tracking.
    func startTrip(trip: Trip, context: ModelContext) {
        firebase.createTripId { [weak self] tripId in
            guard let self else { return }

            trip.tripId = tripId
            context.insert(trip)
            firebase.saveTrip(trip, tripId: tripId)
            locationManager.startTrackingForTrip(tripId)
            notifications.scheduleReturnTimeReminder(returnTime: trip.returnTime)
            saveActiveTripToSettings(tripId: tripId, context: context)
            startOverdueTimer(context: context)

            DispatchQueue.main.async { self.hasActiveTrip = true }
            print("TripSessionManager: trip started — \(tripId)")
        }
    }

    // MARK: - Finish Trip

    /// Stops tracking, cancels notifications, marks trip as completed.
    func finishTrip(trip: Trip, context: ModelContext) {
        trip.status = "completed"
        firebase.endTrip(tripId: trip.tripId)
        locationManager.stopTracking()
        notifications.cancelAllNotifications()
        clearActiveTripFromSettings(context: context)
        stopOverdueTimer()

        DispatchQueue.main.async { self.hasActiveTrip = false }
        print("TripSessionManager: trip finished — \(trip.tripId)")
    }

    // MARK: - Resume on App Launch

    /// Resumes GPS tracking if a trip was active when the app was last closed.
    func resumeActiveSessionIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<AppSettings>()
        guard let settings = try? context.fetch(descriptor).first,
              settings.hasActiveTrip,
              !settings.currentTripId.isEmpty,
              !locationManager.isTrackingActive else { return }

        locationManager.resumeTrackingForTrip(settings.currentTripId)
        startOverdueTimer(context: context)

        DispatchQueue.main.async { self.hasActiveTrip = true }
        print("TripSessionManager: session resumed — \(settings.currentTripId)")
    }

    // MARK: - Reschedule Return Time Reminder
    /// Called when the user updates the return time during an active trip.
    /// Cancels the existing notification and schedules a new one.
    func rescheduleReturnTimeReminder(returnTime: Date) {
        notifications.cancelAllNotifications()
        notifications.scheduleReturnTimeReminder(returnTime: returnTime)
        print("TripSessionManager: return time reminder rescheduled — \(returnTime)")
    }

    /// Starts a repeating 60-second timer to check if the trip has exceeded its return time.
    private func startOverdueTimer(context: ModelContext) {
        stopOverdueTimer()
        overdueTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.checkIfOverdue(context: context)
        }
    }

    private func stopOverdueTimer() {
        overdueTimer?.invalidate()
        overdueTimer = nil
    }

    /// Checks if the active trip has exceeded its return time.
    /// - Runs for both "active" and "overdue" trips (trip stays visible after overdue).
    /// - If overdue and alert not yet sent → sets status to "overdue" and triggers the alert.
    /// - If still within time → no action.
    private func checkIfOverdue(context: ModelContext) {
        guard let trip = fetchActiveTrip(context: context) else { return }
        guard trip.isActive || trip.isOverdue else { return }
        guard Date() > trip.returnTime else { return }

        DispatchQueue.main.async {
            if trip.isActive {
                trip.status = "overdue"
                print("TripSessionManager: trip is overdue — \(trip.tripId)")
            }

            self.firebase.fetchAlertStatus(tripId: trip.tripId) { alertSentFromServer in
                DispatchQueue.main.async {

                    // Update local cache based on Firebase/server only
                    trip.alertSent = alertSentFromServer

                    // If server says alert was not sent yet, trigger overdue status
                    if !alertSentFromServer {
                        self.firebase.sendOverdueAlert(tripId: trip.tripId)
                        self.notifications.scheduleOverdueNotifications()
                        print("TripSessionManager: overdue alert requested — \(trip.tripId)")
                    } else {
                        print("TripSessionManager: alert already confirmed by server — \(trip.tripId)")
                    }
                }
            }
        }
    }
}

// MARK: - LocationManagerDelegate

extension TripSessionManager: LocationManagerDelegate {

    /// Called on every new location update — decides whether to save locally or upload.
    func onNewLocationReceived(_ location: CLLocation) {
        guard let context = activeModelContext else { return }
        guard let trip = fetchActiveTrip(context: context) else { return }

        saveGPSPointLocally(location, trip: trip)

        if shouldUploadLocationNow(location) {
            uploadLocationToCloud(location, trip: trip, context: context)
        }
    }

    /// Called when the user returns to the origin zone — ends the trip automatically.
    func onUserReturnedToStartPoint() {
        guard let context = activeModelContext else { return }
        guard let trip = fetchActiveTrip(context: context) else { return }

        DispatchQueue.main.async { [weak self] in
            self?.finishTrip(trip: trip, context: context)
            print("TripSessionManager: trip auto-ended — user returned to start point")
        }
    }

    // MARK: - Save GPS Point Locally

    private func saveGPSPointLocally(_ location: CLLocation, trip: Trip) {
        if let last = lastSavedCoordinate {
            let lastCL = CLLocation(latitude: last.latitude, longitude: last.longitude)
            guard location.distance(from: lastCL) >= minDistanceBetweenSavedPoints else { return }
        }
        lastSavedCoordinate = location.coordinate
        savedPointsCount += 1
        trip.gpsTrack.append(LocationPoint(
            index: savedPointsCount,
            lat: location.coordinate.latitude,
            lng: location.coordinate.longitude
        ))
        print("TripSessionManager: GPS point saved — #\(savedPointsCount)")
    }

    // MARK: - Upload to Cloud

    private func uploadLocationToCloud(_ location: CLLocation, trip: Trip, context: ModelContext) {
        let direction = location.course >= 0 ? location.course : nil

        firebase.updateLocation(
            tripId: trip.tripId,
            lat: location.coordinate.latitude,
            lng: location.coordinate.longitude,
            direction: direction,
            onSuccess: { [weak self] in
                guard let self else { return }
                // Only cancel notifications if trip is not overdue yet.
                // If overdue, notifications must stay active.
                if !trip.isOverdue {
                    self.notifications.cancelAllNotifications()
                }
                trip.lastKnownLat    = location.coordinate.latitude
                trip.lastKnownLng    = location.coordinate.longitude
                trip.lastUploadTime  = Date()
                trip.lastDirection   = direction
                self.lastUploadDate          = Date()
                self.lastUploadedCoordinate  = location.coordinate
                print("TripSessionManager: location uploaded to cloud")
            },
            onFailure: { [weak self] in
                guard Date() >= trip.returnTime else { return }
                self?.notifications.scheduleOverdueNotifications()
                print("TripSessionManager: upload failed — overdue notifications scheduled")
            }
        )
    }

    // MARK: - Upload Decision

    /// Returns true if enough distance or time has passed since the last upload.
    ///
    /// Upload triggers:
    /// - Distance: 1km slow / 3km normal / 5km fast (handled by LocationManager speed logic)
    /// - Time: every 30 minutes regardless of movement
    private func shouldUploadLocationNow(_ location: CLLocation) -> Bool {
        guard let last = lastUploadedCoordinate else { return true }
        let lastCL = CLLocation(latitude: last.latitude, longitude: last.longitude)
        if location.distance(from: lastCL) >= minDistanceBetweenUploads { return true }
        if Date().timeIntervalSince(lastUploadDate) >= maxTimeBetweenUploads { return true }
        return false
    }
}

// MARK: - Private State

extension TripSessionManager {

    // MARK: Persisted GPS State

    var lastSavedCoordinate: CLLocationCoordinate2D? {
        get {
            let lat = UserDefaults.standard.double(forKey: "lastSavedLat")
            let lng = UserDefaults.standard.double(forKey: "lastSavedLng")
            guard lat != 0 else { return nil }
            return CLLocationCoordinate2D(latitude: lat, longitude: lng)
        }
        set {
            UserDefaults.standard.set(newValue?.latitude ?? 0,  forKey: "lastSavedLat")
            UserDefaults.standard.set(newValue?.longitude ?? 0, forKey: "lastSavedLng")
        }
    }

    var savedPointsCount: Int {
        get { UserDefaults.standard.integer(forKey: "savedPointsCount") }
        set { UserDefaults.standard.set(newValue, forKey: "savedPointsCount") }
    }

    // MARK: Persisted Upload State

    var lastUploadDate: Date {
        get {
            let t = UserDefaults.standard.double(forKey: "lastUploadDate")
            return t == 0 ? .distantPast : Date(timeIntervalSince1970: t)
        }
        set { UserDefaults.standard.set(newValue.timeIntervalSince1970, forKey: "lastUploadDate") }
    }

    var lastUploadedCoordinate: CLLocationCoordinate2D? {
        get {
            let lat = UserDefaults.standard.double(forKey: "lastUploadedLat")
            let lng = UserDefaults.standard.double(forKey: "lastUploadedLng")
            guard lat != 0 else { return nil }
            return CLLocationCoordinate2D(latitude: lat, longitude: lng)
        }
        set {
            UserDefaults.standard.set(newValue?.latitude ?? 0,  forKey: "lastUploadedLat")
            UserDefaults.standard.set(newValue?.longitude ?? 0, forKey: "lastUploadedLng")
        }
    }

    // MARK: Constants

    var minDistanceBetweenSavedPoints: CLLocationDistance { 250 }
    var minDistanceBetweenUploads: CLLocationDistance { 2000 }
    var maxTimeBetweenUploads: TimeInterval { 30 * 60 }

    // MARK: SwiftData Context

    var activeModelContext: ModelContext? {
        return _activeModelContext
    }

    static var _activeModelContext: ModelContext?

    var _activeModelContext: ModelContext? {
        get { TripSessionManager._activeModelContext }
        set { TripSessionManager._activeModelContext = newValue }
    }

    /// Called from HomeViewModel.onAppear to inject the SwiftData context.
    func setModelContext(_ context: ModelContext) {
        _activeModelContext = context
    }

    // MARK: AppSettings Helpers

    private func saveActiveTripToSettings(tripId: String, context: ModelContext) {
        let descriptor = FetchDescriptor<AppSettings>()
        if let s = try? context.fetch(descriptor).first {
            s.currentTripId = tripId
            s.isFirstLaunch = false
        } else {
            let s = AppSettings()
            s.currentTripId = tripId
            s.isFirstLaunch = false
            context.insert(s)
        }
    }

    private func clearActiveTripFromSettings(context: ModelContext) {
        let descriptor = FetchDescriptor<AppSettings>()
        if let s = try? context.fetch(descriptor).first {
            s.currentTripId = ""
        }
        savedPointsCount         = 0
        lastUploadedCoordinate   = nil
        lastSavedCoordinate      = nil
    }

    private func fetchActiveTrip(context: ModelContext) -> Trip? {
        let tripId = locationManager.activeTripId
        let descriptor = FetchDescriptor<Trip>(predicate: #Predicate { $0.tripId == tripId })
        return try? context.fetch(descriptor).first
    }
}
