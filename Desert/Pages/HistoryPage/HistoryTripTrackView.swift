//
//  HistoryTripTrackView.swift
//  Desert
//
//  Full-screen map showing a completed trip's GPS track with step-by-step replay.
//  Replay logic lives in TripHistoryViewModel — this view is UI only.
//

import SwiftUI
import MapKit

struct HistoryTripTrackView: View {

    // MARK: - Input

    var localTrack: [CLLocationCoordinate2D]
    var destinationLocation: CLLocationCoordinate2D?
    var onBack: () -> Void

    // MARK: - ViewModel

    @StateObject private var vm = TripHistoryViewModel()

    // MARK: - Computed

    /// The visible slice of the track based on the current replay position.
    var displayTrack: [CLLocationCoordinate2D] {
        vm.displayTrack(for: localTrack)
    }

    // MARK: - Body

    var body: some View {
        TripTrackTemplate(
            isReplaying: vm.isReplaying,
            mapContent: {
                MapView(
                    localTrack: displayTrack,
                    lastUploadedLocation: nil,
                    destinationLocation: destinationLocation,
                    userLocation: nil
                )
            },
            onBack: onBack,
            onReset: { vm.resetReplay() },
            onToggleReplay: {
                vm.isReplaying ? vm.stopReplay() : vm.startReplay(localTrack: localTrack)
            }
        )
    }
}

// MARK: - Preview

#Preview {
    HistoryTripTrackView(
        localTrack: [
            CLLocationCoordinate2D(latitude: 24.7136, longitude: 46.6753),
            CLLocationCoordinate2D(latitude: 24.7300, longitude: 46.6900),
            CLLocationCoordinate2D(latitude: 24.7500, longitude: 46.7100),
            CLLocationCoordinate2D(latitude: 24.7800, longitude: 46.7400)
        ],
        destinationLocation: CLLocationCoordinate2D(latitude: 24.8000, longitude: 46.7600),
        onBack: {}
    )
}
