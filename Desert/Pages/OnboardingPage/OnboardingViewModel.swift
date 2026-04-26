//
//  OnboardingViewModel.swift
//  Desert
//
//  Created by Arwa Alkadi on 21/04/2026.
//

import Foundation
import SwiftUI
import SwiftData

struct OnboardingView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Query var settings: [AppSettings]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                Text("Onboarding Page")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                
                Spacer()
                
                
                Button("Start") {
                    markAsLaunched()
                   
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.black)
                .foregroundColor(.white)
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
        }
    }
    
    // mark isFirstLaunch as false
    // so next time user goes straight to home
    func markAsLaunched() {
        if let s = settings.first {
            s.isFirstLaunch = false
        } else {
            let s = AppSettings()
            s.isFirstLaunch = false
            modelContext.insert(s)
        }
    }
}

#Preview {
    OnboardingView()
}
