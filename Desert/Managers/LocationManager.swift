//
//  LocationManager.swift
//  Desert
//

import Foundation
import CoreLocation
import SwiftData
import Combine

// MARK: - LocationManagerDelegate

protocol LocationManagerDelegate: AnyObject {
    func onNewLocationReceived(_ location: CLLocation)
    func onUserReturnedToStartPoint()
}

// MARK: - Location Context Result

enum LocationContextResult {
    case urban
    case outskirts
    case unavailable
}

// MARK: - LocationManager

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    static let shared = LocationManager()

    private let clManager = CLLocationManager()

    @Published var isTrackingActive = false
    @Published var currentUserLocation: CLLocationCoordinate2D?
    @Published var locationPermissionStatus: CLAuthorizationStatus = .notDetermined

    weak var delegate: LocationManagerDelegate?

    var activeTripId: String = ""
    var lastKnownLocation: CLLocation?

    private let gpsDistanceFilter: CLLocationDistance = 100
    private let maxAcceptableAccuracy: CLLocationAccuracy = 150

    private var originMonitor: CLMonitor?
    private var originMonitorTask: Task<Void, Never>?
    private var originMonitoringStarted = false

    override init() {
        super.init()
        clManager.delegate = self
    }

    // MARK: - Permission

    func requestLocationPermission() {
        clManager.requestAlwaysAuthorization()
    }

    // MARK: - Initial Map Location

    func requestInitialLocationForMap() {
        guard clManager.authorizationStatus == .authorizedWhenInUse ||
              clManager.authorizationStatus == .authorizedAlways else { return }

        clManager.desiredAccuracy = kCLLocationAccuracyKilometer
        clManager.requestLocation()
    }

    // MARK: - Start Tracking

    func startTrackingForTrip(_ tripId: String) {
        stopOriginMonitoring()
        originMonitoringStarted = false

        UserDefaults.standard.set(tripId, forKey: "activeTripId")

        activeTripId = tripId
        isTrackingActive = true

        clManager.activityType = .automotiveNavigation
        clManager.pausesLocationUpdatesAutomatically = true
        clManager.desiredAccuracy = kCLLocationAccuracyBest
        clManager.distanceFilter = gpsDistanceFilter
        clManager.allowsBackgroundLocationUpdates = true
        clManager.showsBackgroundLocationIndicator = true

        clManager.startUpdatingLocation()
        clManager.startMonitoringSignificantLocationChanges()

        print("LocationManager: tracking started — \(tripId)")
    }

    // MARK: - Stop Tracking

    func stopTracking() {
        clManager.stopUpdatingLocation()
        clManager.stopMonitoringSignificantLocationChanges()
        clManager.allowsBackgroundLocationUpdates = false
        clManager.showsBackgroundLocationIndicator = false
        clManager.pausesLocationUpdatesAutomatically = false

        stopOriginMonitoring()

        isTrackingActive = false
        originMonitoringStarted = false
        activeTripId = ""
        lastKnownLocation = nil

        UserDefaults.standard.removeObject(forKey: "activeTripId")

        print("LocationManager: tracking stopped — no background updates")
    }

    // MARK: - Resume Tracking

    func resumeTrackingForTrip(_ tripId: String) {
        activeTripId = tripId
        isTrackingActive = true
        originMonitoringStarted = false

        clManager.activityType = .automotiveNavigation
        clManager.pausesLocationUpdatesAutomatically = true
        clManager.desiredAccuracy = kCLLocationAccuracyBest
        clManager.distanceFilter = gpsDistanceFilter
        clManager.allowsBackgroundLocationUpdates = true
        clManager.showsBackgroundLocationIndicator = true

        clManager.startUpdatingLocation()
        clManager.startMonitoringSignificantLocationChanges()

        print("LocationManager: tracking resumed — \(tripId)")
    }

    // MARK: - Restore After Force Quit

    func restoreSessionAfterForceQuit() {
        let tripId = UserDefaults.standard.string(forKey: "activeTripId") ?? ""
        guard !tripId.isEmpty else { return }

        activeTripId = tripId
        isTrackingActive = true
        originMonitoringStarted = false

        clManager.activityType = .automotiveNavigation
        clManager.pausesLocationUpdatesAutomatically = true
        clManager.desiredAccuracy = kCLLocationAccuracyBest
        clManager.distanceFilter = gpsDistanceFilter
        clManager.allowsBackgroundLocationUpdates = true
        clManager.showsBackgroundLocationIndicator = true

        clManager.startUpdatingLocation()
        clManager.startMonitoringSignificantLocationChanges()

        print("LocationManager: session restored after force quit — \(tripId)")
    }

    // MARK: - Origin Monitoring Decision

    func startOriginMonitoringIfNeeded() {
        guard !originMonitoringStarted else { return }
        guard let location = lastKnownLocation else { return }

        startMonitoringReturnToStart(
            lat: location.coordinate.latitude,
            lng: location.coordinate.longitude
        )

        originMonitoringStarted = true
        print("LocationManager: CLMonitor started")
    }

    // MARK: - Location Context Decision

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

    func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
        print("LocationManager: GPS paused — device is stationary")
    }

    func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
        print("LocationManager: GPS resumed — device is moving")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        locationPermissionStatus = manager.authorizationStatus

        if manager.authorizationStatus == .authorizedWhenInUse ||
            manager.authorizationStatus == .authorizedAlways {
            requestInitialLocationForMap()
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LocationManager: error — \(error.localizedDescription)")
    }

    // MARK: - Origin Monitor

    private func startMonitoringReturnToStart(lat: Double, lng: Double) {
        originMonitorTask = Task {
            let center = CLLocationCoordinate2D(latitude: lat, longitude: lng)
            let region = CLMonitor.CircularGeographicCondition(center: center, radius: 2000)
            let monitorName = "origin\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))"

            originMonitor = await CLMonitor(monitorName)
            await originMonitor?.add(region, identifier: "startPoint")

            guard let originMonitor else { return }

            var isFirstEvent = true

            do {
                for try await event in await originMonitor.events {
                    if isFirstEvent {
                        isFirstEvent = false
                        continue
                    }

                    if event.state == .satisfied {
                        delegate?.onUserReturnedToStartPoint()
                    }
                }
            } catch {
                print("LocationManager: CLMonitor error — \(error.localizedDescription)")
            }
        }
    }

    private func stopOriginMonitoring() {
        originMonitorTask?.cancel()
        originMonitorTask = nil
        originMonitor = nil
    }
}
