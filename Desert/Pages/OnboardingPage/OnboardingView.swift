//
//  OnboardingView.swift
//  Desert
//
//  Shown on first app launch after the splash screen.
//  Requests When In Use location permission and marks onboarding as complete.
//
//  Permissions Flow:
//  - Location (When In Use): Requested here during onboarding.
//  - Notifications: Requested on the second app visit (handled in HomeViewModel.onAppear).
//  - Location (Always Allow): Requested when the user starts a trip.
//

import SwiftUI
import SwiftData

struct OnboardingView: View {
    
    // MARK: - Environment
    
    @Environment(\.modelContext) private var context
    
    // MARK: - Private
    
    @State private var vm = OnboardingViewModel()
    @State private var currentPage = 0
    
    // MARK: - Onboarding Model & Data Source
    
    struct OnboardingItem {
        let image: String
        let title: String
        let description: String
    }
    
    private let onboardingItems: [OnboardingItem] = [
        .init(image: "onboarding1", title: "onboarding.title1".localized, description: "onboarding.description1".localized),
        .init(image: "onboarding2", title: "onboarding.title2".localized, description: "onboarding.description2".localized),
        .init(image: "onboarding3", title: "onboarding.title3".localized, description: "onboarding.description3".localized),
        .init(image: "onboarding4", title: "onboarding.title4".localized, description: "onboarding.description4".localized)
    ]
    
    // MARK: - Body
    
    private var buttonTitle: String {
        switch currentPage {
        case 0:
            return "onboarding.next".localized
        case 1:
            return "onboarding.next".localized
        case 2:
            return "onboarding.notifications".localized
        default:
            return "onboarding.getStarted".localized
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                
                Color.Background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    
                    HStack {
                        Spacer()
                        
                        Button("onboarding.skip".localized) {
                            withAnimation(.easeInOut(duration: 0.35)) {
                                currentPage = onboardingItems.count - 1
                            }
                        }
                        .font(AppTypography.body)
                        .foregroundStyle(Color.Secondary02)
                        .opacity(currentPage < onboardingItems.count - 1 ? 1 : 0)
                        .disabled(currentPage == onboardingItems.count - 1)
                    }
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.top, 16)
                    
                    
                    TabView(selection: $currentPage) {
                        ForEach(Array(onboardingItems.enumerated()), id: \.offset) { index, item in
                            VStack(spacing: 24) {
                                
                                Spacer()
                                
                                Text(item.title)
                                    .font(AppTypography.title1)
                                    .foregroundStyle(Color.Lableblack)
                                    .multilineTextAlignment(.center)
                                
                                Image(item.image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 270)
                                
                                Text(item.description)
                                    .font(AppTypography.body)
                                    .foregroundStyle(Color.Lableblack)
                                    .multilineTextAlignment(.center)
                                Spacer()
                            }
                            .padding(.horizontal,  AppSpacing.xl)
                            .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    
                    HStack(spacing: 8) {
                        ForEach(0..<onboardingItems.count, id: \.self) { index in
                            Capsule()
                                .fill(index == currentPage ? Color.Secondary02 : Color.Sec2.opacity(0.3))
                                .frame(width: index == currentPage ? 24 : 8, height: 8)
                        }
                    }
                    .padding(.bottom, 24)
                    
                    CTAButton(
                        title: buttonTitle
                    ) {
                        if currentPage == 2 {
                            NotificationsManager.shared.requestPermission {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                    withAnimation(.easeInOut(duration: 0.35)) {
                                        currentPage = 3
                                    }
                                }
                            }
                        } else if currentPage < onboardingItems.count - 1 {
                            withAnimation(.easeInOut(duration: 0.35)) {
                                currentPage += 1
                            }
                        } else {
                            vm.completeOnboarding(context: context)
                        }
                    }
                    .padding(.horizontal,  AppSpacing.xl)
                    .padding(.vertical, 32)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView()
        .modelContainer(for: [AppSettings.self], inMemory: true)
}
