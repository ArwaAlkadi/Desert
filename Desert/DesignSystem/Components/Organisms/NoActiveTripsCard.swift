//
//  NoActiveTripsCard.swift
//  Desert
//
//  Created by Samar A on 10/12/1447 AH.
//

import SwiftUI

struct NoActiveTripsCard: View {
    
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
                
            }
            .padding(.horizontal, 24)
        }
        .frame(width: 370, height: 470)
        .background(Color.Background)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl))        .shadow(
            color: .black.opacity(0.04),
            radius: 12,
            y: 4
        )
    }
}

#Preview {
    
    ZStack {
        Color.white
            .ignoresSafeArea()
        
        NoActiveTripsCard()
    }
}
