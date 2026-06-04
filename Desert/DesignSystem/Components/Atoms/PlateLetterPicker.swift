//
//  PlateInfo.swift
//  Desert
//
//  Created by Samar A on 05/12/1447 AH.

import SwiftUI

struct PlateLetterPicker: View {

    @Binding var selectedLetter: String

    let letters: [String] = [
        "A", "B", "J", "D", "R", "S", "X", "T",
        "E", "G", "K", "L", "Z", "N", "H", "U", "V"
    ]

    var body: some View {

        Menu {

            ForEach(letters, id: \.self) { letter in

                Button("plate.letter.\(letter)".localized) {
                    selectedLetter = letter
                }
            }

        } label: {

            HStack(spacing: AppSpacing.md) {

                Image(systemName: "chevron.up.chevron.down")
                    .foregroundStyle(Color.Primary)

                Text(selectedLetter.isEmpty ? "-" : "plate.letter.\(selectedLetter)".localized)
                    .font(AppTypography.body)
                    .foregroundStyle(Color.Primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.sm)
                    .stroke(Color.Grey100, lineWidth: 1)
            )
        }
    }
}

#Preview {
    PlateLetterPicker(selectedLetter: .constant("A"))
}
