//
//  HistoryMapTrackView.swift
//  Desert
//
//  Historical trip track map — shown in TripHistoryInDetailsView.
//
//  Displays the full saved GPS track for a completed trip.
//  Supports replaying the route step-by-step, like a video.
//  Uses TripMapView internally — no map rendering logic lives here.
//  Replay logic lives in TripHistoryViewModel.
//
//  Controls:
//  - Play / Stop: starts or pauses the replay animation
//  - Reset: jumps back to the first point
//

import SwiftUI
import MapKit

struct HistoryTripTrackView: View {

    var localTrack: [CLLocationCoordinate2D]
    var destinationLocation: CLLocationCoordinate2D?
    var onBack: () -> Void

    @StateObject private var vm = TripHistoryViewModel()

    var displayTrack: [CLLocationCoordinate2D] {
        vm.displayTrack(for: localTrack)
    }

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
            onReset: {
                vm.resetReplay()
            },
            onToggleReplay: {
                vm.isReplaying ? vm.stopReplay() : vm.startReplay(localTrack: localTrack)
            }
        )
    }
}

#Preview {
    HistoryTripTrackView(
        localTrack: [
            CLLocationCoordinate2D(latitude: 24.7136, longitude: 46.6753),
            CLLocationCoordinate2D(latitude: 24.7300, longitude: 46.6900),
            CLLocationCoordinate2D(latitude: 24.7500, longitude: 46.7100),
            CLLocationCoordinate2D(latitude: 24.7800, longitude: 46.7400)
        ],
        destinationLocation: CLLocationCoordinate2D(
            latitude: 24.8000,
            longitude: 46.7600
        ),
        onBack: {}
    )
}
