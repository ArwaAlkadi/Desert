//
//  SplashViewModel.swift
//  Desert
//
//  Created by Arwa Alkadi on 21/04/2026.
//

import Foundation
import SwiftUI

struct SplashView: View {
    
    @Binding var showSplash: Bool
    
    var body: some View {
        VStack {
            Spacer()
            
            Image(systemName: "location.fill")
                .font(.system(size: 48))
                .foregroundColor(.primary)
            
            Spacer()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showSplash = false
                }
            }
        }
    }
}
