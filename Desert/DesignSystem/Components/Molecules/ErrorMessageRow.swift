//
//  ErrorMessageRow.swift
//  Desert
//
//  Created by Samar A on 07/12/1447 AH.
//

import SwiftUI

struct ErrorMessageRow: View {
    var messageKey: String
    var body: some View {
        HStack(spacing: AppSpacing.sm) {

            Text(messageKey.localized)
                .font(AppTypography.caption)
                .foregroundStyle(Color.Destructive)

            Spacer()

            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Color.Destructive)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    VStack(spacing: 24) {
        ErrorMessageRow(messageKey: "error.requiredField")
        ErrorMessageRow(messageKey: "Phone number is required")
    }
    .padding()
}
