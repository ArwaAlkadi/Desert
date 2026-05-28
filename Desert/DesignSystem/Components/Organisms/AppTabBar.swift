//
//  AppTabBar.swift
//  Desert
//
//  Created by Samar A on 10/12/1447 AH.
//

import SwiftUI

struct AppTabBar: View {
    
    @Binding var selectedTab: AppPage
    
    var body: some View {
        HStack(spacing: 0) {
            tabButton(tab: .history, icon: "doc.text.fill", titleKey: "tab.history")
            tabButton(tab: .map, icon: "map.fill", titleKey: "tab.map")
        }
        .padding(6)
        .frame(maxWidth: .infinity)
        .frame(height: 64)
        .background(Color.Secondary)
        .clipShape(Capsule())
    }
    
    private func tabButton(
        tab: AppPage,
        icon: String,
        titleKey: String
    ) -> some View {
        
        let isSelected = selectedTab == tab
        
        return Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                
                Text(titleKey.localized)
                    .font(AppTypography.caption2)
            }
            .foregroundStyle(isSelected ? Color.Primary : Color.TabNotSelected)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(isSelected ? Color.TabSelected : Color.clear)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
