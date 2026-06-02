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
    @State private var showCreateTrip = false
    
    var body: some View {
        HistoryTemplate(
            selectedTab: $currentPage,
            hasTrips: !trips.isEmpty,
            tripsCount: trips.count,
            hasActiveTrip: vm.hasActiveTrip,
            onStartTrip: {
                showCreateTrip = true
            }
        ) {
            tripList
        }
//        .ignoresSafeArea(edges: .bottom)
        .navigationDestination(isPresented: $showCreateTrip) {
            CreateTripStepsView(
                showParentSheet: $showCreateTrip,
                onTripStarted: {
                    showCreateTrip = false
                    currentPage = .map
                },
                onCancel: {
                    showCreateTrip = false
                }
            )
        }
        .navigationDestination(isPresented: $showRepeatTrip) {
            if let tripToRepeat {
                CreateTripStepsView(
                    showParentSheet: $showRepeatTrip,
                    tripToRepeat: tripToRepeat,
                    onTripStarted: {
                        showRepeatTrip = false
                        currentPage = .map
                    },
                    onCancel: {
                        showRepeatTrip = false
                    }
                )
            }
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
       
        .onAppear {
            for trip in trips {
                vm.syncAlertStatusIfNeeded(for: trip, context: context)
            }
        }
    }
}



#Preview {
    NavigationStack {
        TripHistoryView(currentPage: .constant(.history))
    }
    .modelContainer(for: [
        Trip.self,
        LocationPoint.self,
        SavedInfo.self,
        SavedContact.self,
        AppSettings.self
    ], inMemory: true)
}




extension TripHistoryView {
    var tripList: some View {


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
                        peopleType: trip.groupSize == 1 ? .solo : .group,
                        peopleKey: String.localizedStringWithFormat(
                            NSLocalizedString("history.peopleCount", tableName: "PluralStrings", comment: ""),
                            trip.groupSize
                        ),
                        dateKey: vm.formatStartDate(trip.startTime),
                        repeatAction: {
                            tripToRepeat = trip
                            showRepeatTrip = true
                        },
                        hasActiveTrip: vm.hasActiveTrip
                    )
                    .onTapGesture {
                        selectedTrip = trip
                        showDetails = true
                    }
                }
            }

        .padding(.horizontal, AppSpacing.lg)
    }
}


