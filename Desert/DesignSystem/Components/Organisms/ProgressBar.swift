//
//  ProgressBar.swift
//  Desert
//
//  Created by Samar A on 07/12/1447 AH.
//

import SwiftUI

struct ProgressBar: View {

    var currentStep: Int
    var totalSteps: Int = 3

    var body: some View {

        HStack(spacing: AppSpacing.sm) {

            ForEach(0..<totalSteps, id: \.self) { index in
                ProgressSegment(
                    style: index < currentStep ? .active : .inactive
                )
                .frame(maxWidth: .infinity, minHeight: 4, maxHeight: 4)
            }
        }

    }
}

#Preview {

    VStack(spacing: 24) {

        ProgressBar(currentStep: 1)

        ProgressBar(currentStep: 2)

        ProgressBar(currentStep: 3)
    }
}
