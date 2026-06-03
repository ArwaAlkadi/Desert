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
    
    enum TrailingButton {
        case none
        case trash
    }
    
    var titleKey: String? = nil
    
    var leadingButton: LeadingButton = .back
    var trailingButton: TrailingButton = .none
    
    var action: () -> Void = {}
    var trailingAction: () -> Void = {}
    
    init(
        titleKey: String? = nil,
        leadingButton: LeadingButton = .back,
        trailingButton: TrailingButton = .none,
        action: @escaping () -> Void = {},
        trailingAction: @escaping () -> Void = {}
    ) {
        self.titleKey = titleKey
        self.leadingButton = leadingButton
        self.trailingButton = trailingButton
        self.action = action
        self.trailingAction = trailingAction
    }
    
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
                
                trailingView
            }
            
            if let titleKey {
                Text(titleKey.localized)
                    .font(AppTypography.title3)
                    .foregroundStyle(Color.black)
                    .lineLimit(1)
            }
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
        
        @ViewBuilder
        var trailingView: some View {
            
            switch trailingButton {
                
            case .none:
                Color.clear
                    .frame(width: 44, height: 44)
                
            case .trash:
                ToolbarButton(
                    style: .primary,
                    icon: .trash
                ) {
                    trailingAction()
                }
            }
        }
    }
    
    #Preview {
        VStack(spacing: 24) {
            
            HeaderView(
                titleKey: "trip.personalDetails"
            )
            
            HeaderView(
                titleKey: "trip.personalDetails",
                leadingButton: .close
            )
            
            HeaderView(
                trailingButton: .trash
            )
        }
        .padding()
    }


