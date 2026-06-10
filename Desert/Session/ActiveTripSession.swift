//
//  ActiveTripSession.swift
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
/// - LocationManager:      GPS tracking and location context only.
/// - NotificationsManager: Local notifications only.
/// - FirebaseManager:      Cloud sync only.
/// - ActiveTripSession:    Trip lifecycle decisions only.
///
/// ## Trip Status Flow
/// ```
/// .active → returnTime exceeded → .overdue
/// .overdue → user safely returns → .completed
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
/// - The device reads alertStatus from Firebase to update the UI only.
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
///
/// ## Usage
/// ```swift
/// // 1. Set the ModelContext once on app launch
/// ActiveTripSession.shared.setModelContext(context)
///
/// // 2. Resume any active session (e.g. after app restart)
/// ActiveTripSession.shared.resumeActiveSessionIfNeeded(context: context)
///
/// // 3. Start a new trip
/// ActiveTripSession.shared.startTrip(trip: trip, context: context)
///
/// // 4. Update return time if the user edits it
/// ActiveTripSession.shared.updateReturnTime(trip: trip, newReturnTime: date, onSuccess: {}, onFailure: {})
///
/// // 5. End the trip manually
/// ActiveTripSession.shared.finishTrip(trip: trip, context: context)
/// ```
///
/// - Note: Steps 1 and 2 are called from `HomeViewModel.onAppear`.
///         Step 3 is called from `CreateTripViewModel.startTrip`.
class ActiveTripSession: NSObject, ObservableObject {

    // MARK: - Singleton

    static let shared = ActiveTripSession()

    // MARK: - Published

    @Published var hasActiveTrip = false
    @Published var lastUploadedLocation: CLLocationCoordinate2D? = nil

    // MARK: - Private — Dependencies

    private let locationManager = LocationManager.shared
    private let notifications = NotificationsManager.shared
    private let firebase = FirebaseManager.shared

    // MARK: - Private — Timers & Listeners

    /// Fires every 60 seconds to check overdue status and location context.
    private var overdueTimer: DispatchSourceTimer?
    private var uploadTimer: DispatchSourceTimer?

    /// Listens to trip status changes written by Cloud Functions.
    private var tripStatusListener: ListenerRegistration?

    /// Debounces the uploaded location pin to avoid map flickering.
    private var pinDebounceTimer: Timer?

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
        print("ActiveTripSession: trip finished — \(trip.tripId)")
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

        if let trip = fetchActiveTrip(context: context), trip.lastKnownLat != 0 {
            lastUploadedLocation = CLLocationCoordinate2D(
                latitude: trip.lastKnownLat,
                longitude: trip.lastKnownLng
            )
        }

        DispatchQueue.main.async { self.hasActiveTrip = true }
        print("ActiveTripSession: session resumed — \(settings.currentTripId)")
    }

    // MARK: - Update Return Time

    /// Cancels existing notifications and reschedules both with the new return time.
    func rescheduleReturnTimeReminder(returnTime: Date) {
        notifications.cancelAllNotifications()
        let tripId = locationManager.activeTripId
        notifications.scheduleTripNotifications(tripId: tripId, returnTime: returnTime)
        print("ActiveTripSession: notifications rescheduled for new return time — \(returnTime)")
    }

    /// Updates the return time locally on the trip, reschedules notifications, and syncs to Firebase.
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
                print("ActiveTripSession: trip completed by Cloud Function — \(tripId)")
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

    /// Cancels and clears the overdue timer.
    private func stopOverdueTimer() {
        overdueTimer?.cancel()
        overdueTimer = nil
    }

    /// Starts a repeating 30-minute timer that uploads the last known location even if the user hasn't moved.
    /// Acts as a fallback when `distanceFilter` hasn't fired due to inactivity.
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
            print("ActiveTripSession: periodic upload — stationary")
        }
        timer.resume()
        uploadTimer = timer
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
    private func checkIfOverdue(context: ModelContext) {
        guard let trip = fetchActiveTrip(context: context) else { return }
        guard trip.isActive || trip.isOverdue else { return }
        guard Date() > trip.returnTime else { return }

        DispatchQueue.main.async {
            if trip.isActive {
                trip.status = "overdue"
                print("ActiveTripSession: trip is overdue — \(trip.tripId)")
            }
        }

        if let lastLocation = locationManager.lastKnownLocation {
            if Date().timeIntervalSince(lastUploadDate) >= maxTimeBetweenUploads {
                uploadLocationToCloud(lastLocation, trip: trip, context: context)
            }
        }

        let autoEndStartTime = trip.returnTime.addingTimeInterval(5 * 60)
        guard Date() >= autoEndStartTime else {
            print("ActiveTripSession: waiting 5 min before auto-end — \(trip.tripId)")
            return
        }

        guard let lastLocation = locationManager.lastKnownLocation else {
            print("ActiveTripSession: no location available — overdue notification already scheduled at trip start")
            return
        }

        locationManager.checkLocationContext(for: lastLocation) { [weak self] result in
            guard let self else { return }

            switch result {
            case .urban:
                DispatchQueue.main.async {
                    self.finishTrip(trip: trip, context: context)
                    print("ActiveTripSession: trip auto-ended — user in urban area")
                }
            case .outskirts:
                print("ActiveTripSession: user in outskirts — monitoring continues")
            case .unavailable:
                print("ActiveTripSession: no network — monitoring continues")
            }
        }
    }
}

// MARK: - LocationManagerDelegate

extension ActiveTripSession: LocationManagerDelegate {

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

        print("ActiveTripSession: GPS point saved — #\(savedPointsCount)")
    }

    // MARK: - Cloud Upload

    /// Uploads the current location to Firebase.
    /// On success:
    ///   - Before return time → no notification action needed
    ///   - After return time  → cancel reassurance notification (user is fine and moving)
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

                print("ActiveTripSession: location uploaded to cloud")
            },
            onFailure: { [weak self] in
                guard self != nil else { return }
                print("ActiveTripSession: upload failed — reassurance notification already scheduled at trip start")
            }
        )
    }

    // MARK: - Upload Decision

    /// Returns true if the user has moved far enough or enough time has passed since the last upload.
    ///
    /// Upload distance adapts to speed:
    /// - Stationary / slow (< 5 m/s):  1km
    /// - Normal off-road (5–15 m/s):   3km
    /// - High speed (> 15 m/s):        5km
    private func shouldUploadLocationNow(_ location: CLLocation) -> Bool {
        guard let last = lastUploadedCoordinate else { return true }
        let lastCL = CLLocation(latitude: last.latitude, longitude: last.longitude)
        if location.distance(from: lastCL) >= uploadDistance(for: location.speed) { return true }
        if Date().timeIntervalSince(lastUploadDate) >= maxTimeBetweenUploads { return true }
        return false
    }

    /// Returns the required upload distance based on current speed.
    private func uploadDistance(for speed: CLLocationSpeed) -> CLLocationDistance {
        switch speed {
        case ..<5:   return 1000
        case 5..<15: return 3000
        default:     return 5000
        }
    }

    /// Updates the last uploaded location pin on the map with a 3-second debounce.
    /// Prevents the pin from flickering when multiple uploads arrive in quick succession.
    func updateLastUploadedLocation(_ location: CLLocationCoordinate2D) {
        pinDebounceTimer?.invalidate()
        pinDebounceTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.lastUploadedLocation = location
            }
        }
    }
}

// MARK: - Private State

extension ActiveTripSession {

    // MARK: Persisted GPS State

    /// Last coordinate saved to the local GPS track — persisted so it survives app restarts.
    var lastSavedCoordinate: CLLocationCoordinate2D? {
        get {
            let lat = UserDefaults.standard.double(forKey: UserDefaultsKeys.lastSavedLat)
            let lng = UserDefaults.standard.double(forKey: UserDefaultsKeys.lastSavedLng)
            guard lat != 0 else { return nil }
            return CLLocationCoordinate2D(latitude: lat, longitude: lng)
        }
        set {
            UserDefaults.standard.set(newValue?.latitude ?? 0, forKey: UserDefaultsKeys.lastSavedLat)
            UserDefaults.standard.set(newValue?.longitude ?? 0, forKey: UserDefaultsKeys.lastSavedLng)
        }
    }

    /// Number of GPS points saved locally — used as the index for new `LocationPoint` entries.
    var savedPointsCount: Int {
        get { UserDefaults.standard.integer(forKey: UserDefaultsKeys.savedPointsCount) }
        set { UserDefaults.standard.set(newValue, forKey: UserDefaultsKeys.savedPointsCount) }
    }

    // MARK: Persisted Upload State

    /// Timestamp of the last successful Firebase upload — defaults to `.distantPast` if never uploaded.
    var lastUploadDate: Date {
        get {
            let t = UserDefaults.standard.double(forKey: UserDefaultsKeys.lastUploadDate)
            return t == 0 ? .distantPast : Date(timeIntervalSince1970: t)
        }
        set {
            UserDefaults.standard.set(newValue.timeIntervalSince1970, forKey: UserDefaultsKeys.lastUploadDate)
        }
    }

    /// Last coordinate successfully uploaded to Firebase — used to measure distance since last upload.
    var lastUploadedCoordinate: CLLocationCoordinate2D? {
        get {
            let lat = UserDefaults.standard.double(forKey: UserDefaultsKeys.lastUploadedLat)
            let lng = UserDefaults.standard.double(forKey: UserDefaultsKeys.lastUploadedLng)
            guard lat != 0 else { return nil }
            return CLLocationCoordinate2D(latitude: lat, longitude: lng)
        }
        set {
            UserDefaults.standard.set(newValue?.latitude ?? 0, forKey: UserDefaultsKeys.lastUploadedLat)
            UserDefaults.standard.set(newValue?.longitude ?? 0, forKey: UserDefaultsKeys.lastUploadedLng)
        }
    }

    // MARK: Constants

    /// Minimum distance between locally saved GPS points (100m).
    var minDistanceBetweenSavedPoints: CLLocationDistance { 100 }

    /// Maximum time allowed between Firebase uploads before a forced upload (30 min).
    var maxTimeBetweenUploads: TimeInterval { 30 * 60 }

    // MARK: SwiftData Context

    static var _activeModelContext: ModelContext?

    var _activeModelContext: ModelContext? {
        get { ActiveTripSession._activeModelContext }
        set { ActiveTripSession._activeModelContext = newValue }
    }

    /// The active `ModelContext` — set once from `HomeViewModel.onAppear`.
    var activeModelContext: ModelContext? { _activeModelContext }

    /// Stores the active `ModelContext` — set once from `HomeViewModel.onAppear`.
    func setModelContext(_ context: ModelContext) {
        _activeModelContext = context
    }

    // MARK: AppSettings Helpers

    /// Persists the active trip ID to `AppSettings` so it survives app restarts.
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

    /// Clears the active trip ID from `AppSettings` and resets all persisted GPS state.
    private func clearActiveTripFromSettings(context: ModelContext) {
        let descriptor = FetchDescriptor<AppSettings>()

        if let settings = try? context.fetch(descriptor).first {
            settings.currentTripId = ""
        }

        savedPointsCount       = 0
        lastUploadedCoordinate = nil
        lastSavedCoordinate    = nil
    }

    /// Fetches the currently active trip from SwiftData using `activeTripId`.
    private func fetchActiveTrip(context: ModelContext) -> Trip? {
        let tripId = locationManager.activeTripId
        let descriptor = FetchDescriptor<Trip>(predicate: #Predicate { $0.tripId == tripId })
        return try? context.fetch(descriptor).first
    }
}
