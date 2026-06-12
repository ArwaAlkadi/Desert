//
//  HomeViewModel.swift
//  Desert
//

import SwiftUI
import MapKit
import SwiftData
import Network
import Combine

/// Drives `HomeView` — prepares map data for the active trip and handles app-level setup.
///
/// ## Responsibilities
/// 1. Providing computed map data: GPS track, last uploaded location, and destination pin
/// 2. Formatting the time-remaining / overdue label shown on the active trip card
/// 3. Delegating return-time updates and trip-end actions to `TripSessionManager`
/// 4. Monitoring network connectivity to reflect upload status in the UI
/// 5. Bootstrapping app services on first appearance (session resume, notification permission)
///
/// ## Talks To
/// - `TripSessionManager` — for `resumeActiveSessionIfNeeded`, `updateReturnTime`, `finishTrip`
/// - `NotificationsManager` — requests permission on `onAppear`
/// - `LocationManager` — reads `currentUserLocation` for the map
class HomeViewModel: ObservableObject {

    // MARK: - Upload Status

    /// Reflects the Firebase upload state of a return-time edit.
    enum UploadStatus {
        /// No edit in progress.
        case idle
        /// Upload request sent, awaiting Firebase response.
        case uploading
        /// Upload confirmed by Firebase.
        case uploaded
        /// No network — update will retry when connectivity returns.
        case pending

        var label: String {
            switch self {
            case .idle:      return ""
            case .uploading: return "uploading".localized
            case .uploaded:  return "uploaded".localized
            case .pending:   return "pending_upload".localized
            }
        }
    }

    // MARK: - Published

    @Published var returnTimeUploadStatus: UploadStatus = .idle
    @Published var isConnected = true

    // MARK: - Private

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "HomeViewNetworkMonitor")

    // MARK: - Network Monitoring

    /// Starts listening for connectivity changes.
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }

    /// Stops the network monitor. Call from `onDisappear`.
    func stopMonitoring() {
        monitor.cancel()
    }

    // MARK: - Map Data Helpers

    /// Returns the full local GPS track for the active trip as map coordinates, sorted by index.
    func localTrack(for trip: Trip?) -> [CLLocationCoordinate2D] {
        trip?.gpsTrack
            .sorted { $0.index < $1.index }
            .map { CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lng) }
        ?? []
    }

    /// Returns the last successfully uploaded location to Firebase, if available.
    func lastUploadedLocation() -> CLLocationCoordinate2D? {
        ActiveTripSession.shared.lastUploadedLocation
    }

    /// Returns the trip's selected destination coordinate, if set.
    func destinationLocation(for trip: Trip?) -> CLLocationCoordinate2D? {
        guard let trip, trip.destinationLat != 0 else { return nil }
        return CLLocationCoordinate2D(latitude: trip.destinationLat, longitude: trip.destinationLng)
    }

    // MARK: - Days Left Text

    /// Formats the time remaining (or overdue) for a trip into a human-readable string.
    /// Returns a localized plural string — e.g. "2 days left", "3 hours overdue".
    func daysLeftText(for returnTime: Date) -> String {
        let seconds = returnTime.timeIntervalSince(Date())

        if seconds <= 0 {
            let overdueSeconds = abs(seconds)
            let days    = Int(overdueSeconds / 86400)
            let hours   = Int(overdueSeconds / 3600)
            let minutes = Int(overdueSeconds / 60)

            if days > 0 {
                return String.localizedStringWithFormat(NSLocalizedString("activeTrip.daysOverdue", tableName: "PluralStrings", comment: ""), days)
            } else if hours > 0 {
                return String.localizedStringWithFormat(NSLocalizedString("activeTrip.hoursOverdue", tableName: "PluralStrings", comment: ""), hours)
            } else {
                return String.localizedStringWithFormat(NSLocalizedString("activeTrip.minutesOverdue", tableName: "PluralStrings", comment: ""), minutes)
            }
        }

        let days    = Int(seconds / 86400)
        let hours   = Int(seconds / 3600)
        let minutes = Int(seconds / 60)

        if days > 0 {
            return String.localizedStringWithFormat(NSLocalizedString("activeTrip.daysLeft", tableName: "PluralStrings", comment: ""), days)
        } else if hours > 0 {
            return String.localizedStringWithFormat(NSLocalizedString("activeTrip.hoursLeft", tableName: "PluralStrings", comment: ""), hours)
        } else {
            return String.localizedStringWithFormat(NSLocalizedString("activeTrip.minutesLeft", tableName: "PluralStrings", comment: ""), minutes)
        }
    }

    // MARK: - Active Trip Card Actions

    /// Saves an edited return time to Firebase and updates `returnTimeUploadStatus` accordingly.
    /// Silently no-ops if `editedReturnTime` is in the past.
    func saveReturnTime(trip: Trip, editedReturnTime: Date) {
        guard editedReturnTime > Date() else { return }

        returnTimeUploadStatus = isConnected ? .uploading : .pending

        ActiveTripSession.shared.updateReturnTime(
            trip: trip,
            newReturnTime: editedReturnTime
        ) { [weak self] in
            DispatchQueue.main.async {
                self?.returnTimeUploadStatus = .uploaded
            }
        } onFailure: { [weak self] in
            DispatchQueue.main.async {
                self?.returnTimeUploadStatus = .pending
            }
        }
    }

    /// Delegates trip termination to `TripSessionManager`.
    func endTrip(_ trip: Trip, context: ModelContext) {
        ActiveTripSession.shared.finishTrip(trip: trip, context: context)
    }

    // MARK: - App Setup

    /// Bootstraps all app-level services. Called from `HomeView.onAppear`.
    func onAppear(context: ModelContext) {
        ActiveTripSession.shared.setModelContext(context)
        ActiveTripSession.shared.resumeActiveSessionIfNeeded(context: context)

       // NotificationsManager.shared.requestPermission {
            
       // }

        startMonitoring()
    }

    /// Stops the network monitor when the view disappears.
    func onDisappear() {
        stopMonitoring()
    }
}
