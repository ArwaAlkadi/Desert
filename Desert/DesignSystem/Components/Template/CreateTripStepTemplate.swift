//
//  CreateTripStepTemplate.swift
//  Desert
//
//  Created by Samar A on 12/12/1447 AH.
//

import SwiftUI

struct CreateTripStepTemplate<Content: View>: View {
    
    var titleKey: String
    var currentStep: Int
    var totalSteps: Int = 3

    var buttonTitleKey: String
    var isLoading: Bool = false
    var leadingButton: HeaderView.LeadingButton
    var showsProgressBar: Bool = true
    
    var isInputFocused: Bool = false
    
    var onBack: () -> Void = {}
    var onNext: () -> Void = {}
    
    @ViewBuilder var content: Content
    
    var body: some View {
        
        VStack(spacing: 0) {
            
            HeaderView(
                titleKey: titleKey,
                leadingButton: leadingButton,
                action: onBack
            )
            .padding(.bottom, AppSpacing.md)
            .padding(.horizontal, AppSpacing.md)
            
            if showsProgressBar {
                ProgressBar(currentStep: currentStep)
                    .padding(.bottom, AppSpacing.xl)
                    .padding(.horizontal, AppSpacing.md)
            }
            
            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                if !isInputFocused {
                    CTAButton(
                        title: buttonTitleKey.localized
                    ) {
                        guard !isLoading else { return }
                        onNext()
                    }
                    .overlay {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        }
                    }
                    .disabled(isLoading)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, 0)
                    .padding(.bottom, AppSpacing.sm)
                }
            }
            .frame(maxWidth: .infinity)
            .background(Color.Background.ignoresSafeArea(edges: .bottom))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.Background.ignoresSafeArea())
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}
