//
//  TripHistoryInDetailsView.swift
//  Desert
//

import SwiftUI
import MapKit
import SwiftData

struct TripHistoryInDetailsView: View {

    var trip: Trip

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @StateObject private var vm = TripHistoryViewModel()

    @State private var showRepeatTrip = false
    @State private var showFullMap = false

    var localTrack: [CLLocationCoordinate2D] {
        trip.gpsTrack
            .sorted { $0.index < $1.index }
            .map {
                CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lng)
            }
    }
    
    var destinationLocation: CLLocationCoordinate2D? {
        guard trip.destinationLat != 0 else { return nil }
        return CLLocationCoordinate2D(
            latitude: trip.destinationLat,
            longitude: trip.destinationLng
        )
    }

    var body: some View {
        HistoryTripDetailsTemplate(
            tripName: trip.tripName,
            alertSent: trip.alertSent,
            startTime: trip.startTime,
            returnTime: trip.returnTime,
            destination: trip.destination,
            isGroup: trip.hasGroup,
            groupCount: trip.groupSize,
            carDetails: "\(trip.carColor.localized) \(trip.carName)",
            plateNumber: "\(trip.plateNumbers) | \(trip.plateLetters)",
            distance: "\(trip.gpsTrack.count * 250 / 1000) KM",
            emergencyContacts: trip.emergencyContacts.map {
                (initial: String($0.name.prefix(1)), name: $0.name, phone: $0.phone)
            },
            groupContacts: trip.groupContacts.map {
                (initial: String($0.name.prefix(1)), name: $0.name, phone: $0.phone)
            },
            onBack: { dismiss() },
            onDelete: {
                vm.deleteTrip(trip, context: context)
                dismiss()
            },
            onRepeatTrip: {
                guard !vm.hasActiveTrip else { return }
                showRepeatTrip = true
            },
            onExpandMap: {
                showFullMap = true
            },
            hasActiveTrip: vm.hasActiveTrip
        )
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $showRepeatTrip) {
            CreateTripStepsView(
                showParentSheet: $showRepeatTrip,
                tripToRepeat: trip,
                onTripStarted: { showRepeatTrip = false },
                onCancel: { showRepeatTrip = false }
            )
        }
        .fullScreenCover(isPresented: $showFullMap) {
            HistoryTripTrackView(
                localTrack: localTrack,
                destinationLocation: destinationLocation,
                onBack: { showFullMap = false }
            )
            .ignoresSafeArea()
        }
    }
}


#Preview {
    let trip = Trip(
        tripId: "trip_001_preview",
        tripName: "27 May Trip",
        userName: "Samar",
        phoneNumber: "+966501234567",
        destination: "Al Thumamah",
        destinationLat: 24.9,
        destinationLng: 46.7,
        returnTime: Date().addingTimeInterval(3600 * 8),
        hasGroup: true,
        groupSize: 3,
        carName: "Toyota",
        carColor: "White",
        is4WD: true,
        plateLetters: "ABC",
        plateNumbers: "1234"
    )

    trip.status = "completed"
    trip.alertSent = false
    trip.emergencyContacts = [
        Contact(name: "Ahmed", phone: "+966501234567")
    ]
    trip.groupContacts = [
        Contact(name: "Faisal", phone: "+966507654321")
    ]

    return NavigationStack {
        TripHistoryInDetailsView(trip: trip)
    }
    .modelContainer(for: [
        Trip.self,
        LocationPoint.self,
        SavedInfo.self,
        SavedContact.self,
        AppSettings.self
    ], inMemory: true)
}
