//
//  HeaderView.swift
//  Desert
//
//  Created by Samar A on 07/12/1447 AH.
//

import SwiftUI

struct HeaderView: View {
    
    enum LeadingButton {
        case back
        case close
    }

    var titleKey: String
    var leadingButton: LeadingButton = .back
    var action: () -> Void = {}

    var body: some View {

        ZStack {

            HStack {

                ToolbarButton(
                    style: toolbarStyle,
                    icon: toolbarIcon
                ) {
                    action()
                }

                Spacer()

                Color.clear
                    .frame(width: 44, height: 44)
            }

            Text(titleKey.localized)
                .font(AppTypography.title3)
                .foregroundStyle(Color.Primary)
                .lineLimit(1)
        }
    }
}

private extension HeaderView {
    
    var toolbarIcon: ToolbarButton.Icon {
        switch leadingButton {
        case .back:
            return .back
        case .close:
            return .close
        }
    }
    
    var toolbarStyle: ToolbarButton.Style {
        switch leadingButton {
        case .back:
            return .primary
        case .close:
            return .secondary
        }
    }
}

#Preview {
    VStack(spacing: 24) {
        HeaderView(titleKey: "trip.personalDetails")
        
        HeaderView(
            titleKey: "trip.personalDetails",
            leadingButton: .close
        )
    }
    .padding()
}

