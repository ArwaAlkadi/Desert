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

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                Spacer()

                Image(systemName: "location.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.primary)
                    .padding(.bottom, 24)

                Text("app_name".localized)
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("onboarding_subtitle".localized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                    .padding(.horizontal, 32)

                Spacer()

                Button(action: { vm.completeOnboarding(context: context) }) {
                    Text("get_started".localized)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.primary)
                        .foregroundColor(Color(UIColor.systemBackground))
                        .cornerRadius(14)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView()
        .modelContainer(for: [AppSettings.self], inMemory: true)
}
