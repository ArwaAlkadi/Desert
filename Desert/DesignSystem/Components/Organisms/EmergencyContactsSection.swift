//
//  EmergencyContactsSection.swift
//  Desert
//

import SwiftUI

struct EmergencyContactsSection: View {

    @Binding var emergencyContacts: [Contact]

    var showErrors: Bool = false
    var contactErrorMessage: String = ""
    var onAddContact: () -> Void = {}

    var body: some View {

        VStack(alignment: .leading, spacing: AppSpacing.sm) {

            Text("trip.contacts".localized)
                .font(AppTypography.headline)
                .foregroundStyle(Color.Primary)

            VStack(spacing: 0) {

                ForEach(emergencyContacts, id: \.name) { contact in

                    ContactRow(
                        initial: String(contact.name.prefix(1)),
                        titleKey: contact.name,
                        captionKey: contact.phone,
                        isEditable: true,
                        deleteAction: {
                            if let index = emergencyContacts.firstIndex(where: {
                                $0.name == contact.name && $0.phone == contact.phone
                            }) {
                                emergencyContacts.remove(at: index)
                            }
                        }
                    )
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 64)
                    
                    if contact.name != emergencyContacts.last?.name {
                        AppDivider()
                            .padding(.horizontal, AppSpacing.md)
                    }
                }

                if emergencyContacts.count < 3 {
                    
                    if !emergencyContacts.isEmpty {
                        AppDivider()
                            .padding(.horizontal, AppSpacing.md)
                    }

                    AddContactRow(titleKey: "trip.addContact") {
                        onAddContact()
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .clipped()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            //.padding(.horizontal, -8)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))

            if !contactErrorMessage.isEmpty {
                ErrorMessageRow(messageKey: contactErrorMessage)
            } else if showErrors && emergencyContacts.isEmpty {
                ErrorMessageRow(messageKey: "emergency_contact_required")
            }

            Text("trip.contactsLimit".localized)
                .font(AppTypography.caption)
                .foregroundStyle(Color.Disabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
