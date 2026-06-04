//
//  PlateInfoRow.swift
//  Desert
//
//  Created by Samar A on 07/12/1447 AH.
//

import SwiftUI

struct PlateInfoRow: View {

    @Binding var firstLetter: String
    @Binding var secondLetter: String
    @Binding var thirdLetter: String

    @Binding var digits: [String]

    var body: some View {

        VStack(spacing: AppSpacing.sm) {

            HStack(spacing: AppSpacing.sm) {

                PlateLetterPicker(selectedLetter: $firstLetter)

                PlateLetterPicker(selectedLetter: $secondLetter)

                PlateLetterPicker(selectedLetter: $thirdLetter)
            }

            PlateNumberFields(
                digits: $digits
            )
        }
        .padding(.horizontal, AppSpacing.md)
           .padding(.vertical, AppSpacing.md)
    }
}

#Preview {

    PlateInfoRow(
        firstLetter: .constant("A"),
        secondLetter: .constant("B"),
        thirdLetter: .constant("J"),
        digits: .constant(["1", "2", "", ""])
    )
    .padding()
}
