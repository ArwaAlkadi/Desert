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
                .frame(width: 400, height: 200)

            Text("No Active Trips")
                .font(AppTypography.title3)
                .foregroundStyle(Color.Primary)

            CTAButton(title: "Start new trip") {
                onStartTrip()
            }

        }
        .frame(
            width: UIScreen.main.bounds.width - 32,
            height: 470
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
