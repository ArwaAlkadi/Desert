//
//  PersonalDetailsTemplate.swift
//  Desert
//
//  Created by Samar A on 07/12/1447 AH.
//

//استبدلت الستيت بالفيو مودلز

import SwiftUI

struct PersonalDetailsTemplate: View {
    
    @Binding var fullName: String
    @Binding var phoneNumber: String
    @Binding var emergencyContacts: [Contact]
    var showErrors: Bool = false
    var onAddContact: () -> Void = {}
    
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
                text: $fullName,
                state: showErrors && fullName.isEmpty ? .error : .normal
            )
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))

            if showErrors && fullName.isEmpty {
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
                text: $phoneNumber,
                state: showErrors && !phoneNumberIsValid ? .error : .normal
            )
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))

            if showErrors && !phoneNumberIsValid {
                ErrorMessageRow(messageKey: "phone_required")
            }
        }
    }
    
    
    var EmergencyContactsSectiona : some View {
        EmergencyContactsSection(
            emergencyContacts: $emergencyContacts,
            showErrors: showErrors,
            onAddContact: onAddContact
        )
        }
    
   
    var phoneNumberIsValid: Bool {
            let digits = phoneNumber.filter { $0.isNumber }
            return digits.hasPrefix("9665") && digits.count == 12
        }
}

#Preview {
    PersonalDetailsTemplate(
        fullName: .constant(""),
        phoneNumber: .constant(""),
        emergencyContacts: .constant([])
    )
}

