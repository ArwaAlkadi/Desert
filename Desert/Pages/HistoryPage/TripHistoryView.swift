//
//  TripHistoryView.swift
//  Desert
//

import SwiftUI
import SwiftData

struct TripHistoryView: View {

    @Binding var currentPage: AppPage

    @StateObject private var vm = TripHistoryViewModel()
    @Environment(\.modelContext) private var context

    @Query(
        filter: #Predicate<Trip> { $0.status == "completed" },
        sort: \Trip.startTime,
        order: .reverse
    )
    var trips: [Trip]

    @State private var selectedTrip: Trip?
    @State private var showDetails = false

    @State private var tripToRepeat: Trip?
    @State private var showRepeatTrip = false

    var body: some View {
        HistoryTemplate(
            selectedTab: $currentPage,
            hasTrips: !trips.isEmpty,
            tripsCount: trips.count,
            onStartTrip: {
                currentPage = .map
            }
        ) {
            tripList
        }
        .alert(
            String(format: "delete_trips_alert".localized, vm.selectedTrips.count),
            isPresented: $vm.showDeleteAlert
        ) {
            Button("cancel".localized, role: .cancel) { }

            Button("delete".localized, role: .destructive) {
                vm.deleteSelected(trips: trips, context: context)
            }
        } message: {
            Text("delete_trips_message".localized)
        }
        .navigationDestination(isPresented: $showDetails) {
            if let selectedTrip {
                TripHistoryInDetailsView(trip: selectedTrip)
            }
        }
        .navigationDestination(isPresented: $showRepeatTrip) {
            if let tripToRepeat {
                CreateTripView(
                    showParentSheet: $showRepeatTrip,
                    tripToRepeat: tripToRepeat,
                    onTripStarted: {
                        showRepeatTrip = false
                        currentPage = .map
                    }
                )
            }
        }
        .background(Color.Background)
        .ignoresSafeArea(edges: .bottom)
        .onAppear {
            for trip in trips {
                vm.syncAlertStatusIfNeeded(for: trip, context: context)
            }
        }
    }
}








extension TripHistoryView {
    var tripList: some View {

        ScrollView(showsIndicators: false) {

            LazyVStack(spacing: 16) {

                ForEach(trips, id: \.tripId) { trip in

                    HistoryTripCard(
                        titleKey: trip.tripName,
                        destinationKey: trip.destination,
                        statusKey: trip.alertSent
                            ? "history.status.alertSent"
                            : "history.status.noAlert",
                        badgeStyle: trip.alertSent ? .destructive : .positive,
                        durationKey: vm.tripDuration(trip),
                        distanceKey: "\(trip.gpsTrack.count * 250 / 1000) KM",

                        peopleIcon: trip.groupSize == 1
                            ? "person.fill"
                            : "person.3.fill",

                        peopleKey: trip.groupSize == 1
                            ? "history.person".localized
                            : String(
                                format: "history.peopleCount".localized,
                                trip.groupSize
                            ),

                        dateKey: vm.formatStartDate(trip.startTime),

                        repeatAction: {
                            guard !TripSessionManager.shared.hasActiveTrip else { return }

                            tripToRepeat = trip
                            showRepeatTrip = true
                        }
                    )
                    .onTapGesture {
                        selectedTrip = trip
                        showDetails = true
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        DeleteSwipeActionA {
                            vm.selectedTrips = [trip.tripId]
                            vm.showDeleteAlert = true
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 120)
        }
    }
}
