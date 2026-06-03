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

        VStack(spacing: 24) {

            Image("noPreviousTrip")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 400)

            Text("noActiveTrips.title".localized)
                .font(AppTypography.title3)
                .foregroundStyle(Color.black)

            CTAButton(title: "noActiveTrips.startTrip".localized) {
                onStartTrip()
            }

        }
        .frame(
            width: UIScreen.main.bounds.width - 32,
            height: 330
        )
        .background(Color.Background)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl))
        .shadow(
            color: .black.opacity(0.04),
            radius: 12,
            y: 4
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
