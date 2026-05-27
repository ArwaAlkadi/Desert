//
//  PersonalDetailsTemplate.swift
//  Desert
//
//  Created by Samar A on 07/12/1447 AH.
//

//استبدلت الستيت بالفيو مودلز

import SwiftUI

struct PersonalDetailsTemplate: View {
    
    @ObservedObject var vm: TripsViewModel

    var body: some View {


            ScrollView(showsIndicators: false) {

                VStack(spacing: AppSpacing.lg) {
                    fullNameSection
                    phoneNumberSection
                    EmergencyContactsSectiona
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, AppSpacing.sm)
                .padding(.bottom, AppSpacing.xxl)
                .padding(.horizontal, AppSpacing.lg)
            }
        .background(Color.Background)
    }
    
}






private extension PersonalDetailsTemplate {
    
    var fullNameSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("trip.fullName".localized)
                .font(AppTypography.headline)
                .foregroundStyle(Color.Primary)
            
            AppTextField(
                placeholderKey: "trip.fullName.placeholder",
                text: $vm.fullName,
                state: vm.showErrors && !vm.fullNameIsValid ? .error : .normal
            )
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))

            if vm.showStep0Errors && !vm.fullNameIsValid {
                ErrorMessageRow(messageKey: "name_required")
            }
        }
    }
    
    var phoneNumberSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("trip.phone".localized)
                .font(AppTypography.headline)
                .foregroundStyle(Color.Primary)

            AppTextField(
                placeholderKey: "trip.phone.placeholder",
                text: $vm.phoneNumber,
                state: vm.showErrors && !vm.phoneNumberIsValid ? .error : .normal
            )
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))

            if vm.showStep0Errors && !vm.phoneNumberIsValid {
                ErrorMessageRow(messageKey: "phone_required")
            }
        }
    }
    
    
    var EmergencyContactsSectiona : some View {
        EmergencyContactsSection(
                    emergencyContacts: $vm.emergencyContacts,
                    showErrors: vm.showStep0Errors,
                    onAddContact: { vm.showEmergencyContactPicker = true }
                )
        }
    
    
}

#Preview {
    PersonalDetailsTemplate(vm: TripsViewModel())
}
