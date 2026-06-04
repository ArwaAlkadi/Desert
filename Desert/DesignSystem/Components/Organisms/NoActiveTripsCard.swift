//
//  NoActiveTripsCard.swift
//  Desert
//
//  Created by Samar A on 10/12/1447 AH.
//

import SwiftUI

struct NoActiveTripsCard: View {

    var onStartTrip: () -> Void

    var body: some View {

        VStack(spacing: AppSpacing.sm) {

            Image("noPreviousTrip")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 400)

            Text("noActiveTrips.title".localized)
                .font(AppTypography.title3)
                .foregroundStyle(Color.black)
                .multilineTextAlignment(.center)

            CTAButton(title: "noActiveTrips.startTrip".localized) {
                onStartTrip()
            }
            .padding(.top, AppSpacing.lg)
        }
        .frame(maxWidth: .infinity)
        .frame(maxWidth: 370)
        .frame(minHeight: 400)
        .background(Color.Background)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .shadow(
            color: .black.opacity(0.10),
            radius: 15,
            x: 0,
            y: -1
        )
    }
}

#Preview {

    ZStack {
        Color.black
            .ignoresSafeArea()

        NoActiveTripsCard {

        }
    }
}
