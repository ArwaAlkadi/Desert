//
//  RootView.swift
//  Desert
//
//  Created by Arwa Alkadi on 21/04/2026.
//


import Foundation
import SwiftUI
import SwiftData

struct RootView: View {
    
    @Query var setting: [AppSettings]
    @State private var showSplash = true
    
    var body: some View {
        
        if showSplash {
            SplashView(showSplash: $showSplash)
        } else {
            let s = setting.first
            
            if s == nil || s?.isFirstLaunch == true {
                OnboardingView()
            } else {
                HomeView()
            }
        }
    }
}
