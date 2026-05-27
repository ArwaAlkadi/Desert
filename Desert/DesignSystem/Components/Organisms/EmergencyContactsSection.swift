//
//  EmergencyContactsSection.swift
//  Desert
//

// اضفته جديد لانه منطقه يختلف عن الطوارئ

import SwiftUI

struct EmergencyContactsSection: View {

    @Binding var emergencyContacts: [Contact]
    var showErrors: Bool = false
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
                        captionKey: contact.phone
                    ) {
                        emergencyContacts.removeAll { $0.name == contact.name }
                    }
                    .frame(height: 64)

                    if contact.name != emergencyContacts.last?.name {
                        AppDivider()
                            .padding(.horizontal, AppSpacing.md)
                    }
                }

                if emergencyContacts.count < 3 {
                    AddContactRow(titleKey: "trip.addContact") {
                        onAddContact()
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                }
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))

            if showErrors && emergencyContacts.isEmpty {
                ErrorMessageRow(messageKey: "emergency_contact_required")
            }

            Text("trip.contactsLimit".localized)
                .font(AppTypography.caption)
                .foregroundStyle(Color.Disabled)
        }
    }
}

#Preview {
    EmergencyContactsSection(
        emergencyContacts: .constant([]),
        onAddContact: {}
    )
    .padding()
}
