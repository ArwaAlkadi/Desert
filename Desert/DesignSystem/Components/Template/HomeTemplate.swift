//
//  HomeTemplate.swift
//  Desert
//
//  Created by Samar A on 10/12/1447 AH.
//

// هلا سمر هنا اضفت الماب تايب الدوائر

import SwiftUI
import MapKit

struct HomeTemplate: View {

    @Binding var selectedTab: AppPage
    @Binding var mapType: MKMapType

    var activeTrip: Trip?
    var onStartTrip: () -> Void
    var onCenterTapped: () -> Void

    var body: some View {
        ZStack {

            fabButtons

            VStack(spacing: 0) {
                Spacer()

                if let activeTrip {
                    ActiveTripCardView(trip: activeTrip)
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.bottom, 96)
                } else {
                    NoActiveTripsCard {
                        onStartTrip()
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.bottom, 100)
                }
            }

        }
    }
}

extension HomeTemplate {
    var fabButtons: some View {
        VStack {
            HStack {
                Spacer()
                VStack(spacing: AppSpacing.sm) {

                    FABButton(icon: .location) {
                        onCenterTapped()
                    }
                    .padding(.horizontal, AppSpacing.sm)

                    Menu {
                        Button {
                            mapType = .standard
                        } label: {
                            Label("map_standard".localized, systemImage: "map")
                        }
                        Button {
                            mapType = .satellite
                        } label: {
                            Label("map_satellite".localized, systemImage: "globe")
                        }
                        Button {
                            mapType = .hybrid
                        } label: {
                            Label("map_hybrid".localized, systemImage: "map.circle")
                        }
                    } label: {
                        FABButton(icon: .map) { }
                    }
                }
                .padding(.trailing, AppSpacing.lg)
                .padding(.top, 68)
            }
            Spacer()
        }
    }
}


#Preview {
    HomeTemplate(
        selectedTab: .constant(.map),
        mapType: .constant(.standard),
        activeTrip: nil,
        onStartTrip: {},
        onCenterTapped: {}
    )
    .background(.gray.opacity(0.5))
}
