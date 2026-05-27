//
//  BackButton.swift
//  Desert
//
//  Created by Samar A on 04/12/1447 AH.
//
import SwiftUI

struct ToolbarButton: View {
    
    enum Style {
        case primary
        case secondary
        case disabled
    }
    
    enum Icon {
        case back
        case close
    }
    
    var style: Style = .primary
    var icon: Icon = .back
    var action: () -> Void
    
    var body: some View {
        
        Button(action: action) {
            
            Image(systemName: iconName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(foregroundColor)
                .frame(width: 44, height: 44)
                .background(backgroundColor)
                .clipShape(Circle())
        }
        .disabled(style == .disabled)
    }
}

private extension ToolbarButton {
    
    var iconName: String {
        switch icon {
        case .back:
            return "chevron.left"
        case .close:
            return "xmark"
        }
    }
    
    var backgroundColor: Color {
        switch style {
        case .primary:
            return Color.Secondary
            
        case .secondary:
            return Color.Secondary
            
        case .disabled:
            return Color.Disabled
        }
    }

    var foregroundColor: Color {
        switch style {
        case .primary:
            return Color.black
            
        case .secondary:
            return Color.black
            
        case .disabled:
            return Color.white.opacity(0.7)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ToolbarButton(style: .primary, icon: .back) { }
        ToolbarButton(style: .secondary, icon: .close) { }
        ToolbarButton(style: .disabled, icon: .back) { }
    }
}

