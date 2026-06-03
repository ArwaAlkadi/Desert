//
//  MainContainerView.swift
//  Desert
//
//  Created by Samar A on 14/12/1447 AH.
//
//import SwiftUI
//
//struct MainTabContainer: View {
//
//    @State private var selectedTab: AppPage = .map
//
//    var body: some View {
//        ZStack(alignment: .bottom) {
//
//            Group {
//                switch selectedTab {
//                case .map:
//
//                case .history:
//                    HistoryTemplate()
//                }
//            }
//            .frame(maxWidth: .infinity, maxHeight: .infinity)
//
//            VStack(spacing: 0) {
//                AppTabBar(selectedTab: $selectedTab)
//                    .padding(.horizontal, AppSpacing.lg)
//                    .padding(.top, AppSpacing.md)
//                    .padding(.bottom, AppSpacing.sm)
//            }
//            .frame(maxWidth: .infinity)
//            .background(Color.Background.ignoresSafeArea(edges: .bottom))
//        }
//        .ignoresSafeArea(.keyboard, edges: .bottom)
//    }
//}
