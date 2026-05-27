//
//  Untitled.swift
//  Desert
//
//  Created by Samar A on 07/12/1447 AH.
//

// هنا اضفت حد للسطور

import SwiftUI

struct DestinationRow: View {

    var titleKey: String
    var valueKey: String? = nil

    var body: some View {

        HStack {

            Text(titleKey.localized)
                .font(AppTypography.body)
                .foregroundStyle(Color.Primary)

            Spacer()

            if let valueKey {

                Text(valueKey.localized)
                    .font(AppTypography.body)
                    .foregroundStyle(Color.Secondary02)
                    .lineLimit(1)

            } else {

                Image(systemName: "chevron.forward")
                    .foregroundStyle(Color.Primary)
            }
        }
        .padding(.horizontal, AppSpacing.md)
    }
}

#Preview {

    VStack(spacing: 20) {

        DestinationRow(
            titleKey: "destination.title"
        )

        DestinationRow(
            titleKey: "destination.title",
            valueKey: "destination.riyadh"
        )
    }
    .padding()
    .environment(\.locale, Locale(identifier: "en"))
    .environment(\.layoutDirection, .leftToRight)
}
