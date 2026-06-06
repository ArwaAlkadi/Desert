//
//  HomeView.swift
//  Desert
//

import SwiftUI
import MapKit
import SwiftData

struct HomeView: View {

    @StateObject private var vm = HomeViewModel()
    @Environment(\.modelContext) private var context
    @Query var trips: [Trip]

    @State private var currentPage: AppPage = .map
    @State private var showCreateTrip = false
    @State private var mapType: MKMapType = .standard
    @State private var centerTrigger: Int = 0
    @State private var resetNorthTrigger: Int = 0
    @State private var navigationResetID = UUID()

    var activeTrip: Trip? { trips.first { $0.isActive || $0.isOverdue } }

    var body: some View {
        NavigationStack {
            ZStack {
                switch currentPage {
                case .map:
                    mapContent
                case .history:
                    TripHistoryView(currentPage: $currentPage)
                }

                VStack {
                    Spacer()
                    AppTabBar(selectedTab: $currentPage)
                        .padding(.bottom, 16)
                }
                .frame(maxWidth: .infinity)
            }
            .ignoresSafeArea(edges: .bottom)
            .navigationDestination(isPresented: $showCreateTrip) {
                CreateTripStepsView(
                    showParentSheet: $showCreateTrip,
                    onTripStarted: { goToMap() }
                )
            }
        }
        .id(navigationResetID)
        .environment(\.onTripStarted, { goToMap() })
        .onAppear { vm.onAppear(context: context) }
        .onDisappear { vm.onDisappear() }
        .navigationBarBackButtonHidden()
    }
}


#Preview {
    HomeView()
        .modelContainer(for: [
            Trip.self, Contact.self, LocationPoint.self,
            AppSettings.self, SavedInfo.self, SavedContact.self
        ], inMemory: true)
}


extension HomeView {

    func goToMap() {
        showCreateTrip = false
        currentPage = .map
        navigationResetID = UUID()
    }

    // MARK: - Map Content

    var mapContent: some View {
        ZStack {
            MapView(
                localTrack: vm.localTrack(for: activeTrip),
                lastUploadedLocation: vm.lastUploadedLocation(),
                destinationLocation: vm.destinationLocation(for: activeTrip),
                userLocation: LocationManager.shared.currentUserLocation,
                mapType: mapType,
                centerTrigger: centerTrigger,
                resetNorthTrigger: resetNorthTrigger
            )
            .ignoresSafeArea()

            HomeTemplate(
                selectedTab: $currentPage,
                mapType: $mapType,
                activeTrip: activeTrip,
                daysLeft: vm.daysLeftText(for: activeTrip?.returnTime ?? Date()),
                isUploaded: vm.returnTimeUploadStatus == .uploaded,
                isConnected: !vm.isConnected,
                onStartTrip: { showCreateTrip = true },
                onCenterTapped: { centerTrigger += 1 },
                onUpdateReturnTime: { newTime in
                    guard let trip = activeTrip else { return }
                    vm.saveReturnTime(trip: trip, editedReturnTime: newTime)
                },
                onEndTrip: {
                    guard let trip = activeTrip else { return }
                    vm.endTrip(trip, context: context)
                }
            )
        }
        .ignoresSafeArea(edges: .bottom)
    }
}
