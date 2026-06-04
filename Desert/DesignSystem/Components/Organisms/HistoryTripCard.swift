//
//   HistoryTripCard.swift
//  Desert
//
//  Created by Samar A on 11/12/1447 AH.
//
import SwiftUI

struct HistoryTripCard: View {
    
    enum HistoryPeopleType {
        case solo
        case group

        var icon: String {
            switch self {
            case .solo:
                return "person.fill"
            case .group:
                return "person.3.fill"
            }
        }
    }

    var titleKey: String
    var destinationKey: String
    var statusKey: String
    var badgeStyle: StatusBadge.Style = .positive
    var durationKey: String
    var distanceKey: String
    var peopleType: HistoryPeopleType = .group
    var peopleKey: String
    var dateKey: String
    var repeatAction: () -> Void = {}
    var hasActiveTrip: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            headerSection
                .padding(.bottom, 12)
            
            AppDivider()
            
            infoSection
                .frame(minHeight: 52)
            
            AppDivider()
            
            footerSection
                .padding(.top, 12)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }
}

private extension HistoryTripCard {
    
    var headerSection: some View {
        HStack(alignment: .center, spacing: AppSpacing.sm) {
            
            VStack(alignment: .leading, spacing: 2) {
                Text(titleKey.localized)
                    .font(AppTypography.headline)
                    .foregroundStyle(Color.Primary)
                    .lineLimit(1)
                
                Text(destinationKey.localized)
                    .font(AppTypography.caption)
                    .foregroundStyle(Color.lableSec)
                    .lineLimit(1)
            }
            
            Spacer(minLength: AppSpacing.sm)
            
            statusBadge
        }
    }
    
    var statusBadge: some View {
        StatusBadge(
            titleKey: statusKey,
            style: badgeStyle,
            size: .large
        )
    }
    
    var infoSection: some View {
        HStack(spacing: 0) {
            
            infoItem(icon: "clock.fill", textKey: durationKey)
            
            verticalDivider
            
            infoItem(icon: "car.fill", textKey: distanceKey)
            
            verticalDivider
            
            infoItem(icon: peopleType.icon, textKey: peopleKey)
        }
    }
    
    var footerSection: some View {
        HStack(spacing: AppSpacing.sm) {
            
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.system(size: 15, weight: .semibold))
                
                Text(dateKey.localized)
                    .font(AppTypography.caption)
                    .lineLimit(1)
            }
            .foregroundStyle(Color.Primary)
            
            Spacer(minLength: AppSpacing.sm)
            
            RepeatTripButton {
                guard !hasActiveTrip else { return }
                repeatAction()
            }
            .disabled(hasActiveTrip)
            .opacity(hasActiveTrip ? 0.8 : 1)
        }
    }
    
    var verticalDivider: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.18))
            .frame(width: 1, height: 40)
    }
    
    func infoItem(icon: String, textKey: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
            
            Text(textKey.localized)
                .font(AppTypography.caption)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(Color.Primary)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    VStack(spacing: 16) {
        
        HistoryTripCard(
            titleKey: "Al Thumamah Trip",
            destinationKey: "Al Thumamah",
            statusKey: "No Alert Sent",
            badgeStyle: .positive,
            durationKey: "4h 25m",
            distanceKey: "78 km",
            peopleKey: "8 People",
            dateKey: "1 Jun, 04:30PM"
        )
        
        HistoryTripCard(
            titleKey: "Empty Quarter Trip",
            destinationKey: "Rub' al Khali",
            statusKey: "Alert Sent",
            badgeStyle: .destructive,
            durationKey: "8h 10m",
            distanceKey: "240 km",
            peopleKey: "5 People",
            dateKey: "24 May, 09:15AM"
        )
    }
    .padding()
    .background(Color.Background)
}
