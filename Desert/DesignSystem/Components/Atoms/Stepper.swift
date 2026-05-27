//
//  Stepper.swift
//  Desert
//
//  Created by Samar A on 04/12/1447 AH.
//

import SwiftUI

struct Stepper: View {

    enum Style {
        case active
        case disabled
    }

    @Binding var count: Int

    var style: Style = .active
    private let minimumCount = 2

    var body: some View {

        HStack(spacing: AppSpacing.md) {

            Button {
                if canDecrease {
                    count -= 1
                }
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(minusColor)
            }
            .disabled(!canDecrease)

            Text("\(count)")
                .font(AppTypography.body)
                .foregroundStyle(foregroundColor)

            Button {
                count += 1
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(foregroundColor)
            }
            .disabled(style == .disabled)
        }
        .frame(width: 108, height: 32)
        .background(backgroundColor)
        .clipShape(Capsule())
    }
}

private extension Stepper {

    var canDecrease: Bool {
        style == .active && count > minimumCount
    }

    var backgroundColor: Color {
        switch style {
        case .active:
            return .Secondary02
        case .disabled:
            return .Background
        }
    }

    var foregroundColor: Color {
        switch style {
        case .active:
            return .white
        case .disabled:
            return .Disabled2
        }
    }

    var minusColor: Color {
        canDecrease ? foregroundColor : Color.Disabled
    }
}

