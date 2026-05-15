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
        ZStack(alignment: .bottom) {

            Group {
                if trips.isEmpty {
                    emptyState
                } else {
                    tripList
                }
            }
            .navigationTitle("history_title".localized)
            .navigationBarTitleDisplayMode(.large)
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

            CustomTabBar(currentPage: $currentPage)
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .ignoresSafeArea(edges: .bottom)
    }

    var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()

            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("no_trips_yet".localized)
                .foregroundColor(.secondary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 100)
    }

    var tripList: some View {
        List {
            ForEach(trips, id: \.tripId) { trip in
                TripHistoryRow(
                    trip: trip,
                    dateRange: vm.formatDateRange(trip.startTime, trip.returnTime),
                    duration: vm.tripDuration(trip),
                    distance: "\(trip.gpsTrack.count * 250 / 1000) KM",
                    onOpenDetails: {
                        selectedTrip = trip
                        showDetails = true
                    },
                    onRepeatTrip: {
                        tripToRepeat = trip
                        showRepeatTrip = true
                    }
                )
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    DeleteSwipeAction {
                        vm.selectedTrips = [trip.tripId]
                        vm.showDeleteAlert = true
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(UIColor.systemGroupedBackground))
        .padding(.bottom, 50)
    }
}
