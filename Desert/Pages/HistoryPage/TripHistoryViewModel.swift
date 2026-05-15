//
//  TripHistoryViewModel.swift
//  Desert
//
//  Manages state and actions for the trip history list.
//  Handles multi-select deletion and date formatting.
//

import SwiftUI
import SwiftData
import Combine

class TripHistoryViewModel: ObservableObject {

    // MARK: - UI State

    @Published var selectedTrips: Set<String> = []
    @Published var showDeleteAlert = false

    // MARK: - Delete

    /// Deletes all trips whose IDs are in the current selection.
    func deleteSelected(trips: [Trip], context: ModelContext) {
        let toDelete = trips.filter { selectedTrips.contains($0.tripId) }
        for trip in toDelete { context.delete(trip) }
        selectedTrips.removeAll()
    }

    /// Deletes a single trip and saves the context.
    func deleteTrip(_ trip: Trip, context: ModelContext) {
        context.delete(trip)
        try? context.save()
    }

    // MARK: - Formatting

    /// Returns a readable date range string, e.g. "4 May — 5 May".
    func formatDateRange(_ start: Date, _ end: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "d MMM"
        return "\(f.string(from: start)) — \(f.string(from: end))"
    }

    /// Returns a human-readable trip duration, e.g. "2 days".
    func tripDuration(_ trip: Trip) -> String {
        let days = Calendar.current.dateComponents([.day], from: trip.startTime, to: trip.returnTime).day ?? 0
        return "\(max(1, days)) days"
    }
}
