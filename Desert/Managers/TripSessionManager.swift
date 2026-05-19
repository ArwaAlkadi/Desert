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
/// ## Layer Responsibilities
/// - LocationManager: GPS tracking and location context only.
/// - NotificationsManager: Local notifications only.
/// - FirebaseManager: Cloud sync only.
/// - TripSessionManager: Trip lifecycle decisions only.
///
/// ## Trip Status Flow
/// ```
/// "active" → returnTime exceeded → "overdue"
/// "overdue" → user safely returns → "completed"
/// ```
///
/// ## Key Decisions
/// - The trip becomes overdue immediately after returnTime passes.
/// - Auto-end logic starts only 1 hour after returnTime.
/// - WhatsApp alerts are handled by Firebase Cloud Functions, not the device.
/// - The device only schedules local notifications and reads alert status from Firebase.
class TripSessionManager: NSObject, ObservableObject {

    static let shared = TripSessionManager()

    @Published var hasActiveTrip = false

    private let locationManager = LocationManager.shared
    private let notifications = NotificationsManager.shared
    private let firebase = FirebaseManager.shared

    private var overdueTimer: Timer?

    // MARK: - Start Trip

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

    // MARK: - Resume Session

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

    // MARK: - Return Time Reminder

    func rescheduleReturnTimeReminder(returnTime: Date) {
        notifications.cancelAllNotifications()
        notifications.scheduleReturnTimeReminder(returnTime: returnTime)
        print("TripSessionManager: return time reminder rescheduled — \(returnTime)")
    }

    // MARK: - Overdue Timer

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

    // MARK: - Overdue Decision

    private func checkIfOverdue(context: ModelContext) {
        guard let trip = fetchActiveTrip(context: context) else { return }
        guard trip.isActive || trip.isOverdue else { return }
        guard Date() > trip.returnTime else { return }

        DispatchQueue.main.async {
            if trip.isActive {
                trip.status = "overdue"
                print("TripSessionManager: trip is overdue — \(trip.tripId)")
            }
        }

        let autoEndStartTime = trip.returnTime.addingTimeInterval(60 * 60)

        guard Date() >= autoEndStartTime else {
            print("TripSessionManager: auto-end not started yet — waiting 1 hour after return time")
            return
        }

        locationManager.startOriginMonitoringIfNeeded()

        guard let lastLocation = locationManager.lastKnownLocation else {
            sendAlertIfNeeded(trip: trip)
            return
        }

        locationManager.checkLocationContext(for: lastLocation) { [weak self] result in
            guard let self else { return }

            switch result {
            case .urban:
                DispatchQueue.main.async {
                    self.finishTrip(trip: trip, context: context)
                    print("TripSessionManager: trip auto-ended — user in urban area")
                }

            case .outskirts:
                print("TripSessionManager: user in outskirts — monitoring continues")

            case .unavailable:
                self.sendAlertIfNeeded(trip: trip)
            }
        }
    }

    // MARK: - Local Alert Status Sync

    private func sendAlertIfNeeded(trip: Trip) {
        firebase.fetchAlertStatus(tripId: trip.tripId) { [weak self] alertSentFromServer in
            DispatchQueue.main.async {
                trip.alertSent = alertSentFromServer

                if !alertSentFromServer {
                    self?.notifications.scheduleOverdueNotifications()
                    print("TripSessionManager: overdue notification scheduled — \(trip.tripId)")
                } else {
                    print("TripSessionManager: alert already confirmed by server — \(trip.tripId)")
                }
            }
        }
    }
}

// MARK: - LocationManagerDelegate

extension TripSessionManager: LocationManagerDelegate {

    func onNewLocationReceived(_ location: CLLocation) {
        guard let context = activeModelContext else { return }
        guard let trip = fetchActiveTrip(context: context) else { return }

        saveGPSPointLocally(location, trip: trip)

        if shouldUploadLocationNow(location) {
            uploadLocationToCloud(location, trip: trip, context: context)
        }
    }

    func onUserReturnedToStartPoint() {
        guard let context = activeModelContext else { return }
        guard let trip = fetchActiveTrip(context: context) else { return }

        DispatchQueue.main.async { [weak self] in
            self?.finishTrip(trip: trip, context: context)
            print("TripSessionManager: trip auto-ended — user returned to start point")
        }
    }

    // MARK: - Local GPS Track

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

    private func uploadLocationToCloud(_ location: CLLocation, trip: Trip, context: ModelContext) {
        let direction = location.course >= 0 ? location.course : nil

        firebase.updateLocation(
            tripId: trip.tripId,
            lat: location.coordinate.latitude,
            lng: location.coordinate.longitude,
            direction: direction,
            onSuccess: { [weak self] in
                guard let self else { return }

                if !trip.isOverdue {
                    self.notifications.cancelAllNotifications()
                }

                trip.lastKnownLat = location.coordinate.latitude
                trip.lastKnownLng = location.coordinate.longitude
                trip.lastUploadTime = Date()
                trip.lastDirection = direction

                self.lastUploadDate = Date()
                self.lastUploadedCoordinate = location.coordinate

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

    private func shouldUploadLocationNow(_ location: CLLocation) -> Bool {
        guard let last = lastUploadedCoordinate else { return true }

        let lastCL = CLLocation(latitude: last.latitude, longitude: last.longitude)

        if location.distance(from: lastCL) >= uploadDistance(for: location.speed) { return true }
        if Date().timeIntervalSince(lastUploadDate) >= maxTimeBetweenUploads { return true }

        return false
    }

    private func uploadDistance(for speed: CLLocationSpeed) -> CLLocationDistance {
        switch speed {
        case ..<5:
            return 1000
        case 5..<15:
            return 3000
        default:
            return 5000
        }
    }
}

// MARK: - Private State

extension TripSessionManager {

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

    var minDistanceBetweenSavedPoints: CLLocationDistance { 250 }
    var maxTimeBetweenUploads: TimeInterval { 30 * 60 }

    var activeModelContext: ModelContext? { _activeModelContext }

    static var _activeModelContext: ModelContext?

    var _activeModelContext: ModelContext? {
        get { TripSessionManager._activeModelContext }
        set { TripSessionManager._activeModelContext = newValue }
    }

    func setModelContext(_ context: ModelContext) {
        _activeModelContext = context
    }

    // MARK: - AppSettings

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

        savedPointsCount = 0
        lastUploadedCoordinate = nil
        lastSavedCoordinate = nil
    }

    private func fetchActiveTrip(context: ModelContext) -> Trip? {
        let tripId = locationManager.activeTripId
        let descriptor = FetchDescriptor<Trip>(predicate: #Predicate { $0.tripId == tripId })
        return try? context.fetch(descriptor).first
    }
}
