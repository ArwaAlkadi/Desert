//
//  LocationManager.swift
//  Desert
//

import Foundation
import CoreLocation
import SwiftData
import Combine

// MARK: - LocationManagerDelegate

/// Receives filtered location updates from `LocationManager` during an active trip.
protocol LocationManagerDelegate: AnyObject {
    /// Called for every valid GPS reading that passes the accuracy filter.
    func onNewLocationReceived(_ location: CLLocation)
}

// MARK: - LocationContextResult

/// The result of a reverse-geocoding check used to decide whether to auto-end an overdue trip.
enum LocationContextResult {
    /// Street or neighborhood found — user is likely back in a populated area.
    case urban
    /// No street or neighborhood — user is still in the desert or outskirts.
    case outskirts
    /// Geocoder failed (no network or timeout) — decision deferred to Cloud Function.
    case unavailable
}

// MARK: - LocationManager

/// Wraps `CLLocationManager` and exposes GPS tracking as a singleton.
///
/// ## Responsibilities
/// 1. Requesting location permission (When In Use and Always)
/// 2. Starting, stopping, and resuming GPS tracking for an active trip
/// 3. Filtering low-accuracy readings before forwarding them
/// 4. Determining whether the user is in an urban or desert area via reverse geocoding
/// 5. Restoring tracking state after a force quit using `UserDefaults`
///
/// ## Talks To
/// - `TripSessionManager` — receives new locations via `LocationManagerDelegate`
///
/// ## Notes
/// - `distanceFilter` is 100 m — delegate fires every 100 m, not every meter
/// - Accuracy switches dynamically: Best when speed > 5 m/s, HundredMeters otherwise
/// - `activeTripId` is persisted in `UserDefaults` so tracking survives force quit
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    // MARK: - Singleton

    static let shared = LocationManager()

    // MARK: - Published

    @Published var isTrackingActive = false
    @Published var currentUserLocation: CLLocationCoordinate2D?
    @Published var locationPermissionStatus: CLAuthorizationStatus = .notDetermined

    // MARK: - Internal

    weak var delegate: LocationManagerDelegate?
    var activeTripId: String = ""
    var lastKnownLocation: CLLocation?

    // MARK: - Private

    private let clManager = CLLocationManager()
    private let gpsDistanceFilter: CLLocationDistance = 100
    private let maxAcceptableAccuracy: CLLocationAccuracy = 150

    // MARK: - Init

    override init() {
        super.init()
        clManager.delegate = self
    }

    // MARK: - Permission

    /// Requests Always Allow location permission — required before starting a trip.
    func requestLocationPermission() {
        clManager.requestAlwaysAuthorization()
    }

    // MARK: - Initial Map Location

    /// Requests a single low-accuracy location to center the map on app launch.
    /// No-ops if the user hasn't granted permission yet.
    func requestInitialLocationForMap() {
        guard clManager.authorizationStatus == .authorizedWhenInUse ||
              clManager.authorizationStatus == .authorizedAlways else { return }

        clManager.desiredAccuracy = kCLLocationAccuracyKilometer
        clManager.requestLocation()
    }

    // MARK: - Start Tracking

    /// Starts full GPS tracking for a trip and persists `tripId` to `UserDefaults` for force-quit recovery.
    func startTrackingForTrip(_ tripId: String) {
        UserDefaults.standard.set(tripId, forKey: UserDefaultsKeys.activeTripId)

        activeTripId = tripId
        isTrackingActive = true

        clManager.activityType = .automotiveNavigation
        clManager.pausesLocationUpdatesAutomatically = false
        clManager.desiredAccuracy = kCLLocationAccuracyBest
        clManager.distanceFilter = gpsDistanceFilter
        clManager.allowsBackgroundLocationUpdates = true
        clManager.showsBackgroundLocationIndicator = true

        clManager.startUpdatingLocation()
        clManager.startMonitoringSignificantLocationChanges()

        print("LocationManager: tracking started — \(tripId)")
    }

    // MARK: - Stop Tracking

    /// Stops all GPS tracking and clears `activeTripId` from `UserDefaults`.
    func stopTracking() {
        clManager.stopUpdatingLocation()
        clManager.stopMonitoringSignificantLocationChanges()
        clManager.allowsBackgroundLocationUpdates = false
        clManager.showsBackgroundLocationIndicator = false
        clManager.pausesLocationUpdatesAutomatically = false

        isTrackingActive = false
        activeTripId = ""
        lastKnownLocation = nil

        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.activeTripId)

        print("LocationManager: tracking stopped — no background updates")
    }

    // MARK: - Resume Tracking

    /// Resumes tracking without re-persisting to `UserDefaults` (already saved at trip start).
    func resumeTrackingForTrip(_ tripId: String) {
        activeTripId = tripId
        isTrackingActive = true

        clManager.activityType = .automotiveNavigation
        clManager.pausesLocationUpdatesAutomatically = false
        clManager.desiredAccuracy = kCLLocationAccuracyBest
        clManager.distanceFilter = gpsDistanceFilter
        clManager.allowsBackgroundLocationUpdates = true
        clManager.showsBackgroundLocationIndicator = true

        clManager.startUpdatingLocation()
        clManager.startMonitoringSignificantLocationChanges()

        print("LocationManager: tracking resumed — \(tripId)")
    }

    // MARK: - Restore After Force Quit

    /// Re-attaches GPS tracking if a `tripId` was saved in `UserDefaults` from a previous session.
    /// Called from `AppDelegate.application(_:didFinishLaunchingWithOptions:)`.
    func restoreSessionAfterForceQuit() {
        let tripId = UserDefaults.standard.string(forKey: UserDefaultsKeys.activeTripId) ?? ""
        guard !tripId.isEmpty else { return }

        activeTripId = tripId
        isTrackingActive = true

        clManager.activityType = .automotiveNavigation
        clManager.pausesLocationUpdatesAutomatically = false
        clManager.desiredAccuracy = kCLLocationAccuracyBest
        clManager.distanceFilter = gpsDistanceFilter
        clManager.allowsBackgroundLocationUpdates = true
        clManager.showsBackgroundLocationIndicator = true

        clManager.startUpdatingLocation()
        clManager.startMonitoringSignificantLocationChanges()

        print("LocationManager: session restored after force quit — \(tripId)")
    }

    // MARK: - Location Context Decision

    /// Reverse-geocodes `location` to decide if the user is in an urban area or still in the desert.
    /// - Parameters:
    ///   - location: The user's current GPS location.
    ///   - completion: Returns `.urban`, `.outskirts`, or `.unavailable` on the calling thread.
    func checkLocationContext(
        for location: CLLocation,
        completion: @escaping (LocationContextResult) -> Void
    ) {
        print("LocationManager: checking location context...")

        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in

            if let error {
                print("LocationManager: geocoder error — \(error.localizedDescription)")
                completion(.unavailable)
                return
            }

            let placemark = placemarks?.first

            print("LocationManager: placemark received")
            print("Street: \(placemark?.thoroughfare ?? "nil")")
            print("Neighborhood: \(placemark?.subLocality ?? "nil")")
            print("City: \(placemark?.locality ?? "nil")")

            let hasStreet = placemark?.thoroughfare != nil
            let hasNeighborhood = placemark?.subLocality != nil

            if hasStreet || hasNeighborhood {
                print("LocationManager: urban area detected")
                completion(.urban)
            } else {
                print("LocationManager: outskirts/desert detected")
                completion(.outskirts)
            }
        }
    }

    // MARK: - CLLocationManagerDelegate

    /// Filters low-accuracy readings, adjusts accuracy dynamically by speed, then forwards to the delegate.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        lastKnownLocation = location

        DispatchQueue.main.async {
            self.currentUserLocation = location.coordinate
        }

        guard isTrackingActive, !activeTripId.isEmpty else { return }

        guard location.horizontalAccuracy > 0,
              location.horizontalAccuracy <= maxAcceptableAccuracy else { return }

        clManager.desiredAccuracy = location.speed > 5.0
            ? kCLLocationAccuracyBest
            : kCLLocationAccuracyHundredMeters

        delegate?.onNewLocationReceived(location)
    }

    /// Called when iOS auto-pauses location updates because the device is stationary.
    func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
        print("LocationManager: GPS paused — device is stationary")
    }

    /// Called when iOS resumes location updates after a stationary pause.
    func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
        print("LocationManager: GPS resumed — device is moving")
    }

    /// Updates `locationPermissionStatus` and requests the initial map location if permission was just granted.
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        locationPermissionStatus = manager.authorizationStatus

        if manager.authorizationStatus == .authorizedWhenInUse ||
            manager.authorizationStatus == .authorizedAlways {
            requestInitialLocationForMap()
        }
    }

    /// Logs GPS errors — no recovery action needed as tracking continues automatically.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LocationManager: error — \(error.localizedDescription)")
    }
}
