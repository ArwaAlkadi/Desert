//
//  StatusBadge.swift
//  Desert
//
//  Created by Samar A on 07/12/1447 AH.
//

import SwiftUI

struct StatusBadge: View {

    enum Style {
        case positive
        case destructive
    }

    var titleKey: String
    var style: Style = .positive
    var size: Size = .large

    enum Size {
        case small
        case large
    }

    var body: some View {

        Text(titleKey.localized)
            .font(AppTypography.caption2Semibold)
            .foregroundStyle(textColor)
            .padding(.horizontal, size == .large ? 16 : 12)
            .frame(minHeight: 24)
            .background(backgroundColor)
            .clipShape(Capsule())
    }
}

private extension StatusBadge {

    var textColor: Color {
        style == .positive ? Color.Positive : Color.Destructive
    }

    var backgroundColor: Color {
        style == .positive ? Color.PositiveBg : Color.DestructiveBg
    }

//    var width: CGFloat {
//        size == .large ? 97 : 64
//    }
}

#Preview {
    VStack(spacing: 16) {
        StatusBadge(titleKey: "status.label", style: .positive, size: .large)
        StatusBadge(titleKey: "status.label", style: .destructive, size: .large)
        StatusBadge(titleKey: "status.label", style: .positive, size: .small)
        StatusBadge(titleKey: "status.label", style: .destructive, size: .small)
    }
    .padding()
}
