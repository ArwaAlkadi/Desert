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

            HStack(spacing: AppSpacing.sm) {

                Image(systemName: "arrow.counterclockwise")
                    .frame(width: 24 ,height: 24)

                Text(title)
                    .font(AppTypography.caption2Semibold)
                    .lineLimit(1)
                    .font(
                        Font(
                            UIFont(
                                name: "thmanyahsans",
                                size: 17
                            ) ?? .systemFont(ofSize: 17)
                        )
                    )                    //.font(AppTypography.title3)
            }
            .foregroundStyle(.white)
            .padding(.vertical, AppSpacing.sm)
            .padding(.horizontal, AppSpacing.md)
            .background(Color.Secondary02)
            .cornerRadius(AppRadius.xxl)
        }
    }
}

#Preview {
    RepeatTripButton { }
    
}
