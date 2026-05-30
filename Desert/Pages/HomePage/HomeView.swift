//
//  HomeView.swift
//  Desert
//

import SwiftUI
import MapKit
import SwiftData

struct HomeView: View {

    @State private var vm = HomeViewModel()
    @StateObject private var locationManager = LocationManager.shared
    @Environment(\.modelContext) private var context
    @Query var trips: [Trip]

    @State private var currentPage: AppPage = .map
    @State private var showCreateTrip = false
    @State private var mapType: MKMapType = .standard
    @State private var centerTrigger: Int = 0
    @State private var resetNorthTrigger: Int = 0

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
            }
            .navigationDestination(isPresented: $showCreateTrip) {
                CreateTripStepsView(
                    showParentSheet: $showCreateTrip,
                    onTripStarted: {
                        showCreateTrip = false
                        currentPage = .map
                    }
                )
            }
        }
        .environment(\.onTripStarted, { goToMap() })
        .onAppear { vm.onAppear(context: context) }
        .navigationBarBackButtonHidden()
    }

    func goToMap() {
        showCreateTrip = false
        currentPage = .map
    }

    // MARK: - Map Content

    var mapContent: some View {
        ZStack {
            TripMapView(
                localTrack: vm.localTrack(for: activeTrip),
                lastUploadedLocation: vm.lastUploadedLocation(for: activeTrip),
                destinationLocation: vm.destinationLocation(for: activeTrip),
                userLocation: locationManager.currentUserLocation,
                mapType: mapType,
                centerTrigger: centerTrigger,
                resetNorthTrigger: resetNorthTrigger
            )
            .ignoresSafeArea()

            // FAB Buttons
            VStack {
                HStack {
                    Spacer()
                    VStack(spacing: AppSpacing.sm) {

                        FABButton(icon: .location) {
                            centerTrigger += 1
                        }

                        FABButton(icon: .compass) {
                            resetNorthTrigger += 1
                        }

                        Menu {
                            Button {
                                mapType = .standard
                            } label: {
                                Label("map_type_standard".localized, systemImage: "map")
                            }

                            Button {
                                mapType = .satellite
                            } label: {
                                Label("map_type_satellite".localized, systemImage: "globe")
                            }

                            Button {
                                mapType = .hybrid
                            } label: {
                                Label("map_type_hybrid".localized, systemImage: "map.circle")
                            }
                        } label: {
                            FABButton(icon: .map) { }
                        }
                    }
                    .padding(.trailing, AppSpacing.lg)
                    .padding(.top, AppSpacing.xxl)
                }
                Spacer()
            }

            HomeTemplate(
                selectedTab: $currentPage,
                activeTrip: activeTrip,
                onStartTrip: { showCreateTrip = true }
            )
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [
            Trip.self, Contact.self, LocationPoint.self,
            AppSettings.self, SavedInfo.self, SavedContact.self
        ], inMemory: true)
}
