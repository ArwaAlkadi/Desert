//
//  Desert
//
//  Created by Samar A on 09/12/1447 AH.
//

// تعديلات

import SwiftUI

struct GroupSection: View {

    @Binding var isGroup: Bool
    @Binding var groupCount: Int
    @Binding var groupContacts: [Contact]

    var contactErrorMessage: String = ""
    var onAddGroupContact: () -> Void = {}

    var body: some View {

        VStack(alignment: .leading, spacing: AppSpacing.sm) {

            Text("trip.group".localized)
                .font(AppTypography.headline)
                .foregroundStyle(Color.Primary)

            VStack(spacing: 0) {

                InquiryRow(
                    titleKey: "trip.group.question",
                    isOn: $isGroup
                )
                .frame(maxWidth: .infinity)
                .frame(height: 52)

                AppDivider()
                    .opacity(isGroup ? 1 : 0)

                GroupNumberRow(
                    count: $groupCount
                )
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .opacity(isGroup ? 1 : 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: isGroup ? 105 : 52, alignment: .top)
            .background(Color.white)
            .clipShape(
                RoundedRectangle(cornerRadius: AppRadius.md)
            )
            .onChange(of: isGroup) { newValue in
                if newValue {
                    groupCount = max(groupCount, 2)
                }
            }

            if isGroup {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {

                    Text("trip.groupContact.optional".localized)
                        .font(AppTypography.headline)
                        .foregroundStyle(Color.Primary)

                    VStack(spacing: 0) {

                        ForEach(groupContacts, id: \.name) { contact in

                            ContactRow(
                                initial: String(contact.name.prefix(1)),
                                titleKey: contact.name,
                                captionKey: contact.phone
                            ) {
                                groupContacts.removeAll { $0.name == contact.name }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 64)

                            if contact.name != groupContacts.last?.name {
                                AppDivider()
                            }
                        }

                        AddContactRow(titleKey: "trip.groupContact.select") {
                            onAddGroupContact()
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                    }
                    .background(Color.white)
                    .clipShape(
                        RoundedRectangle(cornerRadius: AppRadius.md)
                    )

                    if !contactErrorMessage.isEmpty {
                        ErrorMessageRow(messageKey: contactErrorMessage)
                    }
                }
                .padding(.top, AppSpacing.md)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
