//
//  TripDetailsTemplate.swift
//  Desert
//
//  Created by Samar A on 08/12/1447 AH.
//

//استبدلت الستيت بالفيو مودلز

import SwiftUI

struct TripDetailsTemplate: View {

    @ObservedObject var vm: TripsViewModel

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
                text: $vm.tripName
            )
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            
            if vm.showStep2Errors && !vm.tripNameIsValid {
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
                vm.showDestinationPicker = true
            } label: {
                DestinationRow(
                    titleKey: "trip.destination.placeholder",
                    valueKey: vm.destination.isEmpty ? nil : vm.destination
                )
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))

            if vm.showStep2Errors && !vm.destinationIsValid {
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
                returnTime: $vm.returnTime,
                isEndRequired: true,
                displayedComponents: [.date, .hourAndMinute],
                compactStyle: false
            )
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))

            if vm.showStep2Errors && !vm.returnTimeIsValid {
                ErrorMessageRow(messageKey: "return_time_invalid")
            }
        }
    }

    var groupSection: some View {
        GroupSection(
            isGroup: $vm.isGroup,
            groupCount: $vm.groupCount,
            groupContacts: $vm.groupContacts
        ) {
            vm.showGroupContactPicker = true
        }
    }
}

#Preview {
    TripDetailsTemplate(vm: TripsViewModel())
}
