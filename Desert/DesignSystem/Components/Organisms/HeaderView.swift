//
//  HeaderView.swift
//  Desert
//
//  Created by Samar A on 07/12/1447 AH.
//

import SwiftUI

struct HeaderView: View {

    var titleKey: String
    var backAction: () -> Void = {}

    var body: some View {

        ZStack {

            HStack {

                BackButton(style: .primary) {
                    backAction()
                }

                Spacer()

                Color.clear
                    .frame(width: 44, height: 44)
            }

            Text(titleKey.localized)
                .font(AppTypography.title3)
                .foregroundStyle(Color.Primary)
                .lineLimit(1)
        }
        .padding(.horizontal, AppSpacing.lg) //هنا اضفت بادنق.. كنت بخليه ميديم بس شفتك حاطة بالباقي لارج

    }
}

#Preview {

    HeaderView(
        titleKey: "trip.personalDetails"
    )
}
