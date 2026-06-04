//
//  TripSessionManager.swift
//  Desert
//

import Foundation
import SwiftData
import CoreLocation
import Combine
import UIKit
import FirebaseFirestore

/// Coordinates between LocationManager, NotificationsManager, and FirebaseManager.
///
/// ## Layer Responsibilities
/// - LocationManager:       GPS tracking and location context only.
/// - NotificationsManager:  Local notifications only.
/// - FirebaseManager:       Cloud sync only.
/// - TripSessionManager:    Trip lifecycle decisions only.
///
/// ## Trip Status Flow
/// ```
/// "active" → returnTime exceeded → "overdue"
/// "overdue" → user safely returns → "completed"
/// ```
///
/// ## Auto-End Logic
/// Before return time:
/// - User ends the trip manually only.
///
/// After return time:
/// - Trip status changes to "overdue" immediately.
/// - Auto-end logic starts 5 minutes after return time.
/// - overdueTimer checks every 60 seconds using CLGeocoder:
///     - Urban area (street or neighborhood found) → finishTrip() automatically.
///     - Outskirts (no street or neighborhood)     → keep monitoring.
///     - No network (geocoder unavailable)         → monitoring continues, Cloud Function handles alert delivery.
/// - Cloud Function sends 3 updated location alerts → trip is automatically marked as completed.
/// - Firestore listener detects Cloud Function completion and ends the session locally.
///
/// ## Alert Responsibility
/// - WhatsApp alerts are sent by Firebase Cloud Functions — not the device.
/// - Cloud Function checks every 5 minutes:
///     returnTime passed + no upload for 35 min + alert not yet sent → sends WhatsApp.
/// - The device reads h-alertStatus from Firebase to update the UI only.
/// - The device schedules local notifications at trip start — no app wake-up needed.
///
/// ## Notification Logic
/// - Both notifications (return time + overdue) are scheduled at trip start.
/// - iOS fires them automatically — even if the app is sleeping or force-quit.
/// - If upload succeeds after return time → cancel reassurance notification only.
/// - If user updates return time → cancel all and reschedule with new time.
/// - If trip ends → cancel all notifications.
///
/// ## Upload Distance (Dynamic)
/// - < 5 m/s  → 1km
/// - 5–15 m/s → 3km
/// - > 15 m/s → 5km
/// - Time fallback: every 30 minutes regardless of movement.
class TripSessionManager: NSObject, ObservableObject {

    static let shared = TripSessionManager()

    @Published var hasActiveTrip = false
    @Published var lastUploadedLocation: CLLocationCoordinate2D? = nil
    
    private var pinDebounceTimer: Timer?
    private let locationManager = LocationManager.shared
    private let notifications = NotificationsManager.shared
    private let firebase = FirebaseManager.shared

    /// Fires every 60 seconds to check overdue status and location context.
    private var overdueTimer: DispatchSourceTimer?
    private var uploadTimer: DispatchSourceTimer?

    /// Listens to trip status changes from Cloud Functions.
    private var tripStatusListener: ListenerRegistration?

    private func startUploadTimer(context: ModelContext) {
        uploadTimer?.cancel()
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global())
        timer.schedule(deadline: .now() + (30 * 60), repeating: 30 * 60)
        timer.setEventHandler { [weak self] in
            guard let self else { return }
            guard let context = self.activeModelContext else { return }
            guard let trip = self.fetchActiveTrip(context: context) else { return }
            guard let lastLocation = self.locationManager.lastKnownLocation else { return }
            self.uploadLocationToCloud(lastLocation, trip: trip, context: context)
            print("TripSessionManager: periodic upload — stationary")
        }
        timer.resume()
        uploadTimer = timer
    }

    // MARK: - Start Trip

    /// Creates a trip ID, saves locally and to Firebase, and begins GPS tracking.
    /// Schedules both the return time reminder and reassurance notification at trip start —
    /// iOS fires them automatically regardless of app state.
    func startTrip(
        trip: Trip,
        context: ModelContext,
        completion: @escaping () -> Void = {}
    ) {
        UIDevice.current.isBatteryMonitoringEnabled = true

        firebase.createTripId { [weak self] tripId in
            guard let self else { return }

            trip.tripId = tripId
            context.insert(trip)
            try? context.save()

            firebase.saveTrip(trip, tripId: tripId)
            locationManager.startTrackingForTrip(tripId)

            notifications.scheduleTripNotifications(
                tripId: tripId,
                returnTime: trip.returnTime
            )

            saveActiveTripToSettings(tripId: tripId, context: context)
            startOverdueTimer(context: context)
            startUploadTimer(context: context)
            startTripStatusListener(tripId: tripId, context: context)

            DispatchQueue.main.async {
                self.hasActiveTrip = true
                completion()
            }
        }
    }

    func updateLastUploadedLocation(_ location: CLLocationCoordinate2D) {
        pinDebounceTimer?.invalidate()
        pinDebounceTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.lastUploadedLocation = location
            }
        }
    }
    
    // MARK: - Finish Trip

    /// Stops tracking, cancels all notifications, and marks the trip as completed.
    func finishTrip(trip: Trip, context: ModelContext) {
        UIDevice.current.isBatteryMonitoringEnabled = false
        trip.endedAt = Date()
        trip.status = "completed"
        firebase.endTrip(tripId: trip.tripId)
        locationManager.stopTracking()
        notifications.cancelAllNotifications()
        clearActiveTripFromSettings(context: context)
        stopOverdueTimer()
        uploadTimer?.cancel()
        uploadTimer = nil
        tripStatusListener?.remove()
        tripStatusListener = nil

        DispatchQueue.main.async { self.hasActiveTrip = false }
        print("TripSessionManager: trip finished — \(trip.tripId)")
    }

    // MARK: - Resume Session

    /// Resumes GPS tracking if a trip was active when the app was last closed.
    func resumeActiveSessionIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<AppSettings>()

        guard let settings = try? context.fetch(descriptor).first,
              settings.hasActiveTrip,
              !settings.currentTripId.isEmpty,
              !locationManager.isTrackingActive else { return }

        locationManager.resumeTrackingForTrip(settings.currentTripId)
        startOverdueTimer(context: context)
        startUploadTimer(context: context)
        startTripStatusListener(tripId: settings.currentTripId, context: context)

        if let trip = fetchActiveTrip(context: context),
           trip.lastKnownLat != 0 {
            lastUploadedLocation = CLLocationCoordinate2D(
                latitude: trip.lastKnownLat,
                longitude: trip.lastKnownLng
            )
        }

        DispatchQueue.main.async { self.hasActiveTrip = true }
        print("TripSessionManager: session resumed — \(settings.currentTripId)")
    }

    // MARK: - Update Return Time

    /// Called when the user updates the return time during an active trip.
    /// Cancels all existing notifications and reschedules both with the new return time.
    func rescheduleReturnTimeReminder(returnTime: Date) {
        notifications.cancelAllNotifications()
        let tripId = locationManager.activeTripId
        notifications.scheduleTripNotifications(tripId: tripId, returnTime: returnTime)
        print("TripSessionManager: notifications rescheduled for new return time — \(returnTime)")
    }
    
    func updateReturnTime(
        trip: Trip,
        newReturnTime: Date,
        onSuccess: @escaping () -> Void,
        onFailure: @escaping () -> Void
    ) {
        guard newReturnTime > Date() else { return }

        trip.returnTime = newReturnTime

        rescheduleReturnTimeReminder(returnTime: newReturnTime)

        firebase.updateReturnTime(
            tripId: trip.tripId,
            returnTime: newReturnTime,
            onSuccess: onSuccess,
            onFailure: onFailure
        )
    }

    // MARK: - Trip Status Listener

    /// Listens to Firestore for trip status changes made by Cloud Functions.
    /// When the Cloud Function marks the trip as completed after 3 updated alerts,
    /// the listener detects the change and ends the session locally on the device.
    private func startTripStatusListener(tripId: String, context: ModelContext) {
        tripStatusListener = firebase.listenToTripStatus(tripId: tripId) { [weak self] status in
            guard let self else { return }
            guard status == "completed" else { return }
            guard let trip = self.fetchActiveTrip(context: context) else { return }
            guard !trip.isCompleted else { return }

            DispatchQueue.main.async {
                self.finishTrip(trip: trip, context: context)
                print("TripSessionManager: trip completed by Cloud Function — \(tripId)")
            }
        }
    }

    // MARK: - Overdue Timer

    /// Starts a repeating 60-second timer for the full trip duration.
    /// Acts only after return time has passed.
    private func startOverdueTimer(context: ModelContext) {
        stopOverdueTimer()
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global())
        timer.schedule(deadline: .now() + 60, repeating: 60)
        timer.setEventHandler { [weak self] in
            self?.checkIfOverdue(context: context)
        }
        timer.resume()
        overdueTimer = timer
    }

    private func stopOverdueTimer() {
        overdueTimer?.cancel()
        overdueTimer = nil
    }

    // MARK: - Overdue Decision

    /// Runs every 60 seconds. Acts only after return time has passed.
    ///
    /// Steps:
    /// 1. Mark trip as overdue immediately after return time passes.
    /// 2. Wait 5 minutes before starting auto-end logic — gives user time to tap "I'm Back Safely".
    /// 3. Use CLGeocoder to determine location context:
    ///    - Urban  → end the trip automatically.
    ///    - Outskirts → keep monitoring.
    ///    - No network → monitoring continues, Cloud Function handles alert delivery.
    ///    WhatsApp alert is handled by Cloud Function — not here.
    private func checkIfOverdue(context: ModelContext) {
        guard let trip = fetchActiveTrip(context: context) else { return }
        guard trip.isActive || trip.isOverdue else { return }
        guard Date() > trip.returnTime else { return }

        // mark as overdue immediately
        DispatchQueue.main.async {
            if trip.isActive {
                trip.status = "overdue"
                print("TripSessionManager: trip is overdue — \(trip.tripId)")
            }
        }

        if let lastLocation = locationManager.lastKnownLocation {
            if Date().timeIntervalSince(lastUploadDate) >= maxTimeBetweenUploads {
                uploadLocationToCloud(lastLocation, trip: trip, context: context)
            }
        }

        // auto-end starts 5 minutes after return time
        // gives the user time to tap "I'm Back Safely" before automatic action
        let autoEndStartTime = trip.returnTime.addingTimeInterval(5 * 60)
        guard Date() >= autoEndStartTime else {
            print("TripSessionManager: waiting 5 min before auto-end — \(trip.tripId)")
            return
        }

        guard let lastLocation = locationManager.lastKnownLocation else {
            print("TripSessionManager: no location available — overdue notification already scheduled at trip start")
            return
        }

        locationManager.checkLocationContext(for: lastLocation) { [weak self] result in
            guard let self else { return }

            switch result {
            case .urban:
                // user is in a real urban area — end the trip automatically
                DispatchQueue.main.async {
                    self.finishTrip(trip: trip, context: context)
                    print("TripSessionManager: trip auto-ended — user in urban area")
                }

            case .outskirts:
                // user is in outskirts or desert — keep monitoring
                print("TripSessionManager: user in outskirts — monitoring continues")

            case .unavailable:
                // no network — monitoring continues, Cloud Function handles alert delivery
                print("TripSessionManager: no network — monitoring continues")
            }
        }
    }
}

// MARK: - LocationManagerDelegate

extension TripSessionManager: LocationManagerDelegate {

    /// Called on every valid location update — saves locally and uploads if conditions are met.
    func onNewLocationReceived(_ location: CLLocation) {
        guard let context = activeModelContext else { return }
        guard let trip = fetchActiveTrip(context: context) else { return }

        saveGPSPointLocally(location, trip: trip)

        if shouldUploadLocationNow(location) {
            uploadLocationToCloud(location, trip: trip, context: context)
        }
    }

    // MARK: - Local GPS Track

    /// Saves a GPS point locally every 250m — never uploaded to Firebase.
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

    // MARK: - Cloud Upload

    /// Uploads the current location to Firebase.
    /// On success:
    ///   - Before return time → no notification action needed
    ///   - After return time  → cancel reassurance notification (user is fine and moving)
    /// On failure:
    ///   - Reassurance notification already scheduled at trip start — nothing extra needed
    private func uploadLocationToCloud(_ location: CLLocation, trip: Trip, context: ModelContext) {
        let direction = location.course >= 0 ? location.course : nil

        firebase.updateLocation(
            tripId: trip.tripId,
            lat: location.coordinate.latitude,
            lng: location.coordinate.longitude,
            direction: direction,
            onSuccess: { [weak self] in
                guard let self else { return }

                if trip.isOverdue {
                    self.notifications.cancelReassuranceNotification(tripId: trip.tripId)
                }

                DispatchQueue.main.async {
                    trip.lastKnownLat   = location.coordinate.latitude
                    trip.lastKnownLng   = location.coordinate.longitude
                    trip.lastUploadTime = Date()
                    trip.lastDirection  = direction
                    self.updateLastUploadedLocation(location.coordinate)
                }

                self.lastUploadDate         = Date()
                self.lastUploadedCoordinate = location.coordinate

                print("TripSessionManager: location uploaded to cloud")
            },
            onFailure: { [weak self] in
                guard let self else { return }
                print("TripSessionManager: upload failed — reassurance notification already scheduled at trip start")
            }
        )
    }

    // MARK: - Upload Decision

    /// Returns true if the user has moved far enough or enough time has passed.
    ///
    /// Upload distance adapts to speed:
    /// - Stationary / slow (< 5 m/s):   1km
    /// - Normal off-road (5–15 m/s):    3km
    /// - High speed (> 15 m/s):         5km
    ///
    /// Time fallback: every 30 minutes regardless of movement.
    private func shouldUploadLocationNow(_ location: CLLocation) -> Bool {
        guard let last = lastUploadedCoordinate else { return true }
        let lastCL = CLLocation(latitude: last.latitude, longitude: last.longitude)
        if location.distance(from: lastCL) >= uploadDistance(for: location.speed) { return true }
        if Date().timeIntervalSince(lastUploadDate) >= maxTimeBetweenUploads { return true }
        return false
    }

    /// Dynamic upload distance based on speed.
    private func uploadDistance(for speed: CLLocationSpeed) -> CLLocationDistance {
        switch speed {
        case ..<5:   return 1000
        case 5..<15: return 3000
        default:     return 5000
        }
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
            UserDefaults.standard.set(newValue?.latitude ?? 0, forKey: "lastSavedLat")
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
        set {
            UserDefaults.standard.set(newValue.timeIntervalSince1970, forKey: "lastUploadDate")
        }
    }

    var lastUploadedCoordinate: CLLocationCoordinate2D? {
        get {
            let lat = UserDefaults.standard.double(forKey: "lastUploadedLat")
            let lng = UserDefaults.standard.double(forKey: "lastUploadedLng")
            guard lat != 0 else { return nil }
            return CLLocationCoordinate2D(latitude: lat, longitude: lng)
        }
        set {
            UserDefaults.standard.set(newValue?.latitude ?? 0, forKey: "lastUploadedLat")
            UserDefaults.standard.set(newValue?.longitude ?? 0, forKey: "lastUploadedLng")
        }
    }

    // MARK: Constants

    var minDistanceBetweenSavedPoints: CLLocationDistance { 100 }
    var maxTimeBetweenUploads: TimeInterval { 30 * 60 }

    // MARK: SwiftData Context

    var activeModelContext: ModelContext? { _activeModelContext }

    static var _activeModelContext: ModelContext?

    var _activeModelContext: ModelContext? {
        get { TripSessionManager._activeModelContext }
        set { TripSessionManager._activeModelContext = newValue }
    }

    func setModelContext(_ context: ModelContext) {
        _activeModelContext = context
    }

    // MARK: AppSettings Helpers

    private func saveActiveTripToSettings(tripId: String, context: ModelContext) {
        let descriptor = FetchDescriptor<AppSettings>()

        if let settings = try? context.fetch(descriptor).first {
            settings.currentTripId = tripId
            settings.isFirstLaunch = false
        } else {
            let settings = AppSettings()
            settings.currentTripId = tripId
            settings.isFirstLaunch = false
            context.insert(settings)
        }
    }

    private func clearActiveTripFromSettings(context: ModelContext) {
        let descriptor = FetchDescriptor<AppSettings>()

        if let settings = try? context.fetch(descriptor).first {
            settings.currentTripId = ""
        }

        savedPointsCount        = 0
        lastUploadedCoordinate  = nil
        lastSavedCoordinate     = nil
    }

    private func fetchActiveTrip(context: ModelContext) -> Trip? {
        let tripId = locationManager.activeTripId
        let descriptor = FetchDescriptor<Trip>(predicate: #Predicate { $0.tripId == tripId })
        return try? context.fetch(descriptor).first
    }
}
