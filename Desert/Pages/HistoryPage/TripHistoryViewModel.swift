//
//  TripHistoryViewModel.swift
//  Desert
//

import SwiftUI
import SwiftData
import MapKit
import Combine

/// Drives `TripHistoryView` — manages selection, deletion, formatting, and GPS replay.
///
/// ## Responsibilities
/// 1. Tracking multi-select state for batch deletion
/// 2. Deleting individual or selected trips from SwiftData
/// 3. Syncing the `alertSent` flag from Firebase for trips that haven't been synced yet
/// 4. Formatting trip start dates and durations for display
/// 5. Animating a step-by-step GPS track replay using a repeating timer
///
/// ## Talks To
/// - `FirebaseManager` — fetches and syncs `alertSent` status per trip
/// - `ActiveTripSession` — reads `hasActiveTrip` to gate history actions
/// - `SwiftData` — deletes `Trip` objects directly via `ModelContext`
  class TripHistoryViewModel: ObservableObject {

    // MARK: - Published

    @Published var selectedTrips: Set<String> = []
    @Published var showDeleteAlert = false
    @Published var alertStatuses: [String: Bool] = [:]
    @Published var replayIndex: Int = 0
    @Published var isReplaying: Bool = false

    // MARK: - Internal

    var localTrack: [CLLocationCoordinate2D] = []
    var destinationLocation: CLLocationCoordinate2D? = nil
      

    // MARK: - Private

    private let firebase = FirebaseManager.shared
    private var replayTimer: Timer?

    // MARK: - Computed

    /// `true` if a trip is currently active — used to gate delete actions in the UI.
    var hasActiveTrip: Bool {
        ActiveTripSession.shared.hasActiveTrip
    }


    /// Fetches `alertSent` from Firebase and caches it in `alertStatuses` for display.
    func fetchAlertStatus(
        tripId: String,
        completion: @escaping (Bool) -> Void
    ) {
        firebase.fetchAlertStatus(tripId: tripId) { [weak self] sent in
            DispatchQueue.main.async {
                self?.alertStatuses[tripId] = sent
                completion(sent)
            }
        }
    }

    /// Syncs `alertSent` from Firebase once per trip and persists it locally.
    /// Skips trips that have already been synced (`didSyncAlertStatus == true`).
    func syncAlertStatusIfNeeded(for trip: Trip, context: ModelContext) {
        guard trip.didSyncAlertStatus == false else { return }
        
        firebase.fetchAlertStatus(tripId: trip.tripId) { sent in
            DispatchQueue.main.async {
                trip.alertSent = sent
                trip.didSyncAlertStatus = true
                try? context.save()
            }
        }
    }
    
    // MARK: - Delete

    /// Deletes all trips that are currently selected in multi-select mode.
    func deleteSelected(trips: [Trip], context: ModelContext) {
        let toDelete = trips.filter { selectedTrips.contains($0.tripId) }
        for trip in toDelete {
            context.delete(trip)
        }
        selectedTrips.removeAll()
    }
    

    /// Deletes a single trip from SwiftData immediately.
    func deleteTrip(_ trip: Trip, context: ModelContext) {
        context.delete(trip)
        try? context.save()
    }
    
    // MARK: - Formatting

    

    /// Formats a trip start date into a readable string — e.g. `"06 May, 03:45pm"`.
    func formatStartDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMMM, hh:mma"
        return formatter.string(from: date)
    }


    /// Returns the trip duration as a human-readable string — e.g. "2D 3h", "5h".
    /// Uses `endedAt` if available, falls back to `returnTime`.
    func tripDuration(_ trip: Trip) -> String {
        let endDate = trip.endedAt ?? trip.returnTime
        let seconds = endDate.timeIntervalSince(trip.startTime)

        let totalHours = max(0, Int(seconds / 3600))
        let days = totalHours / 24
        let hours = totalHours % 24

        let dayUnit = AppLanguage.isArabic ? "ي" : "D"
        let hourUnit = AppLanguage.isArabic ? "س" : "h"

        let daysText = formatNumber(days)
        let hoursText = formatNumber(hours)

        if days > 0 && hours > 0 {
            return "\(daysText)\(dayUnit) \(hoursText)\(hourUnit)"
        } else if days > 0 {
            return "\(daysText)\(dayUnit)"
        } else {
            return "\(hoursText)\(hourUnit)"
        }
    }
    // MARK: - Replay

    /// Returns the visible portion of the track based on the current replay position.
    /// Returns the full track when replay is idle and hasn't started.
    func displayTrack(for track: [CLLocationCoordinate2D]) -> [CLLocationCoordinate2D] {
        guard !track.isEmpty else { return [] }
        if isReplaying || replayIndex > 0 {
            return Array(track.prefix(replayIndex + 1))
        }
        return track
    }

    /// Animates through the GPS track step by step at 0.4s intervals.
    /// Resets to the beginning if the previous replay finished.
    func startReplay(localTrack: [CLLocationCoordinate2D]) {
        guard !localTrack.isEmpty else { return }
        if replayIndex >= localTrack.count - 1 { replayIndex = 0 }
        isReplaying = true

        replayTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { [weak self] _ in
            guard let self else { return }
            if self.replayIndex < localTrack.count - 1 {
                self.replayIndex += 1
            } else {
                self.replayTimer?.invalidate()
                self.isReplaying = false
            }
        }
    }

    /// Pauses the replay timer without resetting the current position.
    func stopReplay() {
        replayTimer?.invalidate()
        isReplaying = false
    }

    /// Stops the replay and resets the position back to the start.
    func resetReplay() {
        stopReplay()
        replayIndex = 0
    }
    
    // MARK: - Formatting

    func formatNumber(_ number: Int) -> String {
        guard AppLanguage.isArabic else {
            return "\(number)"
        }

        let western = ["0","1","2","3","4","5","6","7","8","9"]
        let arabic = ["٠","١","٢","٣","٤","٥","٦","٧","٨","٩"]

        var result = "\(number)"

        for index in western.indices {
            result = result.replacingOccurrences(
                of: western[index],
                with: arabic[index]
            )
        }

        return result
    }

    func formatDistance(_ gpsCount: Int) -> String {
        let km = gpsCount * 250 / 1000
        let value = formatNumber(km)

        return AppLanguage.isArabic
            ? "\(value) كم"
            : "\(value) KM"
    }
}
