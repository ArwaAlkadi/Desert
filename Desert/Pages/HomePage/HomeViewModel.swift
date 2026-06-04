//
//  HomeViewModel.swift
//  Desert
//
//  Provides computed map data for the active trip displayed in HomeView.
//  Used by TripMapView to render the GPS track, last uploaded location, and destination pin.
//
//  Also handles app-level setup on first appear:
//  - Sets SwiftData context on TripSessionManager
//  - Resumes any active trip session after force quit
//  - Requests notification permission on second app visit
//

import SwiftUI
import MapKit
import SwiftData

struct HomeViewModel {

    // MARK: - Map Data Helpers

    /// Returns the full local GPS track for the active trip as map coordinates.
    func localTrack(for trip: Trip?) -> [CLLocationCoordinate2D] {
        trip?.gpsTrack.map {
            CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lng)
        } ?? []
    }

    /// Returns the last successfully uploaded location to Firebase, if available.
    func lastUploadedLocation() -> CLLocationCoordinate2D? {
        TripSessionManager.shared.lastUploadedLocation
    }

    /// Returns the trip's selected destination coordinate, if set.
    func destinationLocation(for trip: Trip?) -> CLLocationCoordinate2D? {
        guard let trip, trip.destinationLat != 0 else { return nil }
        return CLLocationCoordinate2D(latitude: trip.destinationLat, longitude: trip.destinationLng)
    }

    // MARK: - App Setup

    /// Called on HomeView.onAppear.
    /// Routes all manager setup through a single entry point.
    func onAppear(context: ModelContext) {
        TripSessionManager.shared.setModelContext(context)
        TripSessionManager.shared.resumeActiveSessionIfNeeded(context: context)
        NotificationsManager.shared.requestPermission()
    }

    // MARK: - End Trip

    /// Ends the active trip via TripSessionManager.
    func endTrip(_ trip: Trip, context: ModelContext) {
        TripSessionManager.shared.finishTrip(trip: trip, context: context)
    }

    // MARK: - Reschedule Return Time Reminder
    /// Called when the user updates the return time from ActiveTripCardView.
    func rescheduleReturnTimeReminder(returnTime: Date) {
        TripSessionManager.shared.rescheduleReturnTimeReminder(returnTime: returnTime)
    }
}
