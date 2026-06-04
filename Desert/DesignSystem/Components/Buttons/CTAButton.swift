//
//  PrimaryButton.swift
//  Desert
//
//  Created by Samar A on 03/12/1447 AH.
//

import SwiftUI

struct CTAButton: View {

    enum Style {
        case primary
        case secondary
        case disabled
    }
    
    enum Size {
        case large
        case small
    }

    var title: String

    var style: Style = .primary
    var size: Size = .large

    var action: () -> Void

    var body: some View {

        Button(action: action) {

            Text(title)
                .font(AppTypography.headline)
                .foregroundStyle(foregroundColor)
                .frame(
                    width: size == .large ? 291 : 200,
                    height: size == .large ? 51 : 40
                )
                .background(backgroundColor)
                .cornerRadius(AppRadius.xxl)
        }
        .disabled(style == .disabled)
    }
}

private extension CTAButton {

    var backgroundColor: Color {

        switch style {

        case .primary:
            return .Primary

        case .secondary:
            return .Secondary02

        case .disabled:
            return .Disabled
        }
    }

    var foregroundColor: Color {

        switch style {

        case .disabled:
            return .white.opacity(0.7)

        default:
            return .white
        }
    }

    var width: CGFloat {
        size == .large ? 291 : 200
    }

    var height: CGFloat {
        size == .large ? 51 : 40
    }
}

#Preview {

    VStack(spacing: AppSpacing.md) {

        CTAButton(
            title: "summary.startNewTrip".localized,
            style: .primary,
            size: .large
        ) {

        }

        CTAButton(
            title: "summary.startNewTrip".localized,
            style: .primary,
            size: .small
        ) {

        }

        CTAButton(
            title: "summary.startNewTrip".localized,
            style: .secondary,
            size: .large
        ) {

        }

        CTAButton(
            title: "summary.startNewTrip".localized,
            style: .disabled,
            size: .large
        ) {

        }
    }
}
