//
//  ActiveTripCardView.swift
//  Desert
//

import SwiftUI
import SwiftData

struct ActiveTripCardView: View {

    var trip: Trip

    @Environment(\.modelContext) private var context
    @StateObject private var vm = ActiveTripCardViewModel()

    var body: some View {
        ActiveTripCard(
            tripName: trip.tripName,
            daysLeft: vm.daysLeftText(for: trip.returnTime),
            isUploaded: vm.returnTimeUploadStatus == .uploaded,
            returnTime: trip.returnTime,
            isOverdue: trip.isOverdue,
            emergencyContacts: trip.emergencyContacts,
            onUpdateReturnTime: { newTime in
                vm.saveReturnTime(
                    trip: trip,
                    editedReturnTime: newTime
                )
            },
            onEndTrip: {
                vm.endTrip(trip, context: context)
            }
        )
        .onAppear {
            vm.startMonitoring()
        }
        .onDisappear {
            vm.stopMonitoring()
        }
    }
}


#Preview {
    ActiveTripCardView(
        trip: Trip(
            tripId: "trip_001_preview",
            tripName: "Desert Trip",
            userName: "Samar",
            phoneNumber: "+966501234567",
            destination: "Al Thumamah",
            destinationLat: 24.9,
            destinationLng: 46.7,
            returnTime: Date().addingTimeInterval(4 * 24 * 60 * 60),
            hasGroup: false,
            groupSize: 1,
            carName: "Toyota",
            carColor: "White",
            is4WD: true,
            plateLetters: "ABC",
            plateNumbers: "1234"
        )
    )
    .modelContainer(for: [
        Trip.self,
        LocationPoint.self
    ], inMemory: true)
}
