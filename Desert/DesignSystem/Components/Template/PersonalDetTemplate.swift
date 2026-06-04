//
//  PersonalDetailsTemplate.swift
//  Desert
//
//  Created by Samar A on 07/12/1447 AH.
//

// هنا عدلت رسالة الايرور لانه فيه نوعين

import SwiftUI

struct PersonalDetailsTemplate: View {

    @Binding var fullName: String
    @Binding var phoneNumber: String
    @Binding var emergencyContacts: [Contact]
    var contactErrorMessage: String = ""
    var showErrors: Bool = false
    var isPhoneNumberValid: Bool = true
    var phoneError: PhoneError = .required
    var onAddContact: () -> Void = {}

    var body: some View {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    fullNameSection
                    phoneNumberSection
                    emergencyContactsSection
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, AppSpacing.sm)
                .padding(.bottom, AppSpacing.xxl)
                .padding(.horizontal, AppSpacing.md)
            }
        
        .background(Color.Background)
    }
}


private extension PersonalDetailsTemplate {

    var fullNameSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sx) {
            Text("trip.fullName".localized)
                .font(AppTypography.headline)
                .foregroundStyle(Color.Primary)

            AppTextField(
                placeholderKey: "trip.fullName.placeholder",
                text: $fullName,
                state: showErrors && fullName.isEmpty ? .error : .normal
            )
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))

            if showErrors && fullName.isEmpty {
                ErrorMessageRow(messageKey: "name_required")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var phoneNumberSection: some View {

        VStack(alignment: .leading, spacing: AppSpacing.sx) {

            Text("trip.phone".localized)
                .font(AppTypography.headline)
                .foregroundStyle(Color.Primary)

            HStack(spacing: AppSpacing.sm) {

                Text("trip.phone.countryCode".localized)
                    .font(AppTypography.body)
                    .foregroundStyle(Color.Primary)

                Rectangle()
                    .fill(Color.Grey100)
                    .frame(width: 1)
                    .frame(maxHeight: 24)
                AppTextField(
                    placeholderKey: "trip.phone.placeholder",
                    text: $phoneNumber,
                    state: showErrors && !isPhoneNumberValid ? .error : .normal
                )
                .keyboardType(.numberPad)
            }
            .padding(.horizontal, AppSpacing.md)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))

            if showErrors && !isPhoneNumberValid {
                ErrorMessageRow(messageKey: phoneError.messageKey)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    var emergencyContactsSection: some View {
        EmergencyContactsSection(
            emergencyContacts: $emergencyContacts,
            showErrors: showErrors,
            contactErrorMessage: contactErrorMessage,
            onAddContact: onAddContact
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }

}

#Preview {
    PersonalDetailsTemplate(
        fullName: .constant("Samar Alqahtani"),
        phoneNumber: .constant("512345678"),
        emergencyContacts: .constant([
            Contact(name: "Om Saqr", phone: "+966 5X XXX XXXX"),
            Contact(name: "Fajer", phone: "+966 5X XXX XXXX"),
            Contact(name: "Nouf", phone: "+966 5X XXX XXXX")
        ])
    )
}
