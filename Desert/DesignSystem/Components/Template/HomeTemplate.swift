//
//  HomeTemplate.swift
//  Desert
//
//  Created by Samar A on 10/12/1447 AH.
//


// TODO: Show only when network status changes.
// Offline alert: 3–5s or dismiss on tap.
// Reconnection toast: auto-dismiss after 2s.
// Do not show if initial state is online.


import SwiftUI

struct HomeTemplate: View {
    
    @State private var selectedTab: AppTabBar.TabItem = .trips
    @State private var networkStatus: NetworkStatusBanner.Status? = .disconnected
    
    var body: some View {
        
        ZStack(alignment: .top) {
            Color.white
                .ignoresSafeArea()
            
            if let networkStatus {
                NetworkStatusBanner(status: networkStatus)
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.top, AppSpacing.lg)
            }
            
            VStack {
                
                Spacer()
                    .frame(height: 200)
                
                NoActiveTripsCard()
                
                Spacer()
            }
        
            .padding(.horizontal, AppSpacing.lg)
        }
        .safeAreaInset(edge: .bottom) {
            AppTabBar(selectedTab: $selectedTab)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.sm)
                .background(Color.white)
        }
    }
}

#Preview {
    HomeTemplate()
}
