//
//  RepeatTripButton.swift
//  Desert
//
//  Created by Samar A on 04/12/1447 AH.
//

import SwiftUI

struct RepeatTripButton: View {

    var title: String = "button.repeatTrip".localized
    var action: () -> Void

    var body: some View {

        Button(action: action) {

            HStack(spacing: AppSpacing.sx) {

                Image(systemName: "arrow.counterclockwise")
                    .frame(width: 20 ,height: 20)

                Text(title)
                    .font(AppTypography.caption2Semibold)
                    .lineLimit(1)
            }
            .foregroundStyle(.white)
            .frame(width: 105, height: 32)
            .background(Color.Secondary02)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    RepeatTripButton { }
    
}
