//
//  TripDetailsTemplate.swift
//  Desert
//
//  Created by Samar A on 08/12/1447 AH.
//

//استبدلت الستيت بالفيو مودلز

import SwiftUI

struct TripDetailsTemplate: View {

        @Binding var tripName: String
        @Binding var destination: String
        @Binding var returnTime: Date
        @Binding var isGroup: Bool
        @Binding var groupCount: Int
        @Binding var groupContacts: [Contact]
        var contactErrorMessage: String = ""
        var showErrors: Bool = false
        var onSelectDestination: () -> Void = {}
        var onAddGroupContact: () -> Void = {}
  
    var body: some View {

        ScrollView(showsIndicators: false) {

            VStack(spacing: AppSpacing.lg) {
                tripNameSection
                destinationSection
                timeSection
                groupSection
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, AppSpacing.sm)
            .padding(.bottom, AppSpacing.xxl)
            .padding(.horizontal, AppSpacing.lg)
        }
        .background(Color.Background)
    }
}

// MARK: - Sections

private extension TripDetailsTemplate {

    var tripNameSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {

            Text("trip.name".localized)
                .font(AppTypography.headline)
                .foregroundStyle(Color.Primary)

            AppTextField(
                placeholderKey: "trip.name.placeholder",
                text: $tripName
            )
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            
            if showErrors && tripName.isEmpty {
                    ErrorMessageRow(messageKey: "trip_name_required")
                }
        }
        
    }

    var destinationSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {

            Text("trip.destination".localized)
                .font(AppTypography.headline)
                .foregroundStyle(Color.Primary)

            Button {
                onSelectDestination()
            } label: {
                DestinationRow(
                    titleKey: "trip.destination.placeholder",
                    valueKey: destination.isEmpty ? nil : destination
                )
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))

            if showErrors && destination.isEmpty {
                ErrorMessageRow(messageKey: "destination_required")
            }
        }
    }

    var timeSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {

            Text("trip.time".localized)
                .font(AppTypography.headline)
                .foregroundStyle(Color.Primary)

            DateRangeRow(
                startLabelKey: "trip.startTime",
                startDate: .constant(Date()),
                endLabelKey: "trip.endTime",
                returnTime: $returnTime,
                isEndRequired: true,
                displayedComponents: [.date, .hourAndMinute],
                compactStyle: false
            )
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))

            if showErrors && returnTime <= Date() {
                ErrorMessageRow(messageKey: "return_time_invalid")
            }
        }
    }

    var groupSection: some View {
        GroupSection(
            isGroup: $isGroup,
            groupCount: $groupCount,
            groupContacts: $groupContacts,
            contactErrorMessage: contactErrorMessage,
            onAddGroupContact: onAddGroupContact
        )
    }
}

#Preview {
    TripDetailsTemplate(
        tripName: .constant(""),
        destination: .constant(""),
        returnTime: .constant(Date().addingTimeInterval(3600)),
        isGroup: .constant(false),
        groupCount: .constant(2),
        groupContacts: .constant([])
    )
}
