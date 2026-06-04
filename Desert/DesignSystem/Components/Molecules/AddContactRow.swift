//
//  AddContactRow.swift
//  Desert
//
//  Created by Samar A on 07/12/1447 AH.
//

import SwiftUI

struct AddContactRow: View {

    var titleKey: String

    var action: () -> Void

    var body: some View {

        Button(action: action) {

            HStack(spacing: AppSpacing.sm) {

                CounterButton(style: .add) {

                }

                Text(titleKey.localized)
                    .font(AppTypography.body)
                    .foregroundStyle(Color.Primary)
                    .lineLimit(1)

                Spacer()
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
        }
        .buttonStyle(.plain)
    }
}

#Preview {

    AddContactRow(
        titleKey: "contact.add"
    ) {

    }
    .padding()
}
