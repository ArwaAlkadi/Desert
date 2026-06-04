//
//  SearchBar.swift
//  Desert
//
//  Created by Samar A on 11/12/1447 AH.
//

import SwiftUI

struct SearchBar: View {
    
    enum Style {
        case normal
        case withBackButton
    }
    
    var style: Style = .normal
    
    var placeholderKey: String
    @Binding var text: String
    
    var backAction: () -> Void = {}
    var searchAction: () -> Void = {}
    
    var body: some View {
        
        HStack(spacing: AppSpacing.sm) {
            
            if style == .withBackButton {
                
                ToolbarButton(
                    style: .primary,
                    icon: .back
                ) {
                    backAction()
                }
            }
            
            HStack(spacing: AppSpacing.md) {
                
                TextField(
                    placeholderKey.localized,
                    text: $text
                )
                .font(AppTypography.body)
                .foregroundStyle(Color.Primary)
                .multilineTextAlignment(.leading)
                .onSubmit {
                    searchAction()
                }
                
                Button {
                    searchAction()
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Color.Primary)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .background(Color.white)
            .clipShape(Capsule())
            
        }
    }
}

#Preview {
    
    VStack(spacing: 24) {
        
        SearchBar(
            placeholderKey: "search.destination",
            text: .constant("")
        )
        
        SearchBar(
            style: .withBackButton,
            placeholderKey: "search.destination",
            text: .constant("")
        )
    }
    .padding()
    .background(Color.Background)
}
