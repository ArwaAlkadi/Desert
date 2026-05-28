//
//  HomeView.swift
//  Desert
//
//  Root view after onboarding. Manages navigation between Map and History pages.
//
//  Location Permission Behavior:
//  - No permission: Trip cannot start. User directed to Settings.
//  - "When In Use" only: Trip cannot start. User directed to Settings to enable Always Allow.
//  - "Always Allow": Trip starts normally.
//
//  Permissions are requested at the following points:
//  - Location (When In Use): Onboarding
//  - Notifications: Second app visit (triggered in onAppear)
//  - Location (Always Allow): When the user taps Start Trip
//
//  Firebase Upload Triggers:
//  - Distance-based: 1km when slow, 3km at normal off-road speed, 5km at high speed.
//  - Time-based: Every 30 minutes to confirm signal and app activity.
//
//  Origin Monitoring:
//  - CLMonitor creates a 2km radius around the trip's start location.
//  - Returning to this zone automatically ends the trip.
//

import SwiftUI
import MapKit
import SwiftData


// MARK: - HomeView

struct HomeView: View {

    @State private var vm = HomeViewModel()
    @StateObject private var locationManager = LocationManager.shared
    @Environment(\.modelContext) private var context
    @Query var trips: [Trip]

    @State private var currentPage: AppPage = .map
    @State private var showCreateTrip = false

    /// Active or overdue trip — stays visible until the user taps "I'm Back Safely".
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
                CreateTripView(
                    showParentSheet: $showCreateTrip,
                    onTripStarted: {
                        showCreateTrip = false
                        currentPage = .map
                    }
                )
            }
        }
        .environment(\.onTripStarted, { goToMap() })
        .onAppear {
            vm.onAppear(context: context)
        }
        .navigationBarBackButtonHidden()
    }

    // MARK: - Navigation

    /// Dismisses any active sheet and returns the user to the map page.
    func goToMap() {
        showCreateTrip = false
        currentPage = .map
    }

    // MARK: - Map Content

    var mapContent: some View {
        ZStack(alignment: .bottom) {

            TripMapView(
                localTrack: vm.localTrack(for: activeTrip),
                lastUploadedLocation: vm.lastUploadedLocation(for: activeTrip),
                destinationLocation: vm.destinationLocation(for: activeTrip),
                userLocation: locationManager.currentUserLocation
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                if activeTrip == nil {
                    WelcomeCard(onStartTrip: { showCreateTrip = true })
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                } else {
                    ActiveTripCardView(trip: activeTrip!)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }

                AppTabBar(selectedTab: $currentPage)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Preview

#Preview {
    HomeView()
        .modelContainer(for: [
            Trip.self, Contact.self, LocationPoint.self,
            AppSettings.self, SavedInfo.self, SavedContact.self
        ], inMemory: true)
}
