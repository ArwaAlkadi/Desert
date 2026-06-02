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
    var hasActiveTrip: Bool = false
    
    var onStartTrip: () -> Void = {}
    
    @ViewBuilder var content: Content
    
    var body: some View {
        
        ZStack {
            
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                
                headerSection
                
                if hasTrips {
                    ScrollView(showsIndicators: false) {
                        content
                            .padding(.bottom, 240)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    emptyStateSection
                }
            }
            .padding(.top, AppSpacing.lg)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color.Background)
            
        }
    }
}

private extension HistoryTemplate {
    
    var headerSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            
            Text("history.title".localized)
                .font(AppTypography.title1)
                .foregroundStyle(Color.black)
            
            Text(String.localizedStringWithFormat(NSLocalizedString("history.tripsCount", tableName: "PluralStrings", comment: ""), tripsCount))
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
                style: hasActiveTrip ? .disabled : .primary,
                size: .small
            ) {
                guard !hasActiveTrip else { return }
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
                titleKey: "Al Thumamah Trip",
                destinationKey: "Al Thumamah",
                statusKey: "No Alert Sent",
                badgeStyle: .positive,
                durationKey: "4h 25m",
                distanceKey: "78 km",
                peopleKey: "3 People",
                dateKey: "1 Jun 2026"
            )
            
            HistoryTripCard(
                titleKey: "Desert Camp",
                destinationKey: "Al Rumah",
                statusKey: "Alert Sent",
                badgeStyle: .destructive,
                durationKey: "2 Days",
                distanceKey: "34Km",
                peopleKey: "3 people",
                dateKey: "28 May, 5:30PM"
            )
        }
        .padding(.horizontal, AppSpacing.lg)
    }
}
