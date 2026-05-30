//
//  HistoryTemplate.swift
//  Desert
//
//  Created by Samar A on 12/12/1447 AH.
//

import SwiftUI

struct HistoryTemplate<Content: View>: View {
    
    @Binding var selectedTab: AppPage
    
    var hasTrips: Bool
    var tripsCount: Int
    
    var onStartTrip: () -> Void = {}
    
    @ViewBuilder var content: Content
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            
            headerSection
            
            if hasTrips {
                content
            } else {
                emptyStateSection
            }
        }
        .padding(.top, AppSpacing.lg)
        .background(Color.Background)
        .safeAreaInset(edge: .bottom) {
            
            VStack(spacing: 0) {
                
                AppTabBar(selectedTab: $selectedTab)
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.top, AppSpacing.md)
                    .padding(.bottom, AppSpacing.sm)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

private extension HistoryTemplate {
    
    var headerSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            
            Text("history.title".localized)
                .font(AppTypography.title1)
                .foregroundStyle(Color.black)
            
            Text(String(format: "history.tripsCount".localized, tripsCount))
                .font(AppTypography.caption)
                .foregroundStyle(Color.lableSec)
        }
        .padding(.horizontal, AppSpacing.lg)
    }
    
    var emptyStateSection: some View {
        
        VStack(spacing: AppSpacing.xl) {
            
            Spacer(minLength: 40)
            
            Image("noPreviousTrip")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 400)
            
            VStack(spacing: AppSpacing.sx) {
                
                Text("history.noPreviousTrips".localized)
                    .font(AppTypography.title2)
                    .foregroundStyle(Color.black)
                
                Text("history.noTripsDescription".localized)
                    .font(AppTypography.caption)
                    .foregroundStyle(Color.lableSec)
            }
            
            CTAButton(
                title: "history.startNewTrip".localized,
                style: .primary,
                size: .small
            ) {
                onStartTrip()
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    HistoryTemplate(
        selectedTab: .constant(.history),
        hasTrips: true,
        tripsCount: 2
    ) {
        VStack(spacing: AppSpacing.md) {
            HistoryTripCard(
                titleKey: "history.mock.title",
                destinationKey: "history.mock.destination",
                statusKey: "history.status.noAlert",
                badgeStyle: .positive,
                durationKey: "history.mock.duration",
                distanceKey: "history.mock.distance",
                peopleKey: "history.mock.people",
                dateKey: "history.mock.date"
            )
            
            HistoryTripCard(
                titleKey: "history.mock.title",
                destinationKey: "history.mock.destination",
                statusKey: "history.status.alertSent",
                badgeStyle: .destructive,
                durationKey: "history.mock.duration",
                distanceKey: "history.mock.distance",
                peopleKey: "history.mock.people",
                dateKey: "history.mock.date"
            )
        }
        .padding(.horizontal, AppSpacing.lg)
    }
}
