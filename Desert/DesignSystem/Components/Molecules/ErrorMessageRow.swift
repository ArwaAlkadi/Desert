//
//  ErrorMessageRow.swift
//  Desert
//
//  Created by Samar A on 07/12/1447 AH.
//

// شلت البادنق .. يتنادى من برا

import SwiftUI

struct ErrorMessageRow: View {

    var messageKey: String

    var body: some View {

        HStack(spacing: AppSpacing.sm) {

            Text(messageKey.localized)
                .font(AppTypography.caption)
                .foregroundStyle(Color.Destructive)

        }
        
    }
}

#Preview {
    ErrorMessageRow(messageKey: "error.requiredField")
        .padding()
}
