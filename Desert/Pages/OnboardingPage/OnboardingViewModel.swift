//
//  OnboardingViewModel.swift
//  Desert
//
//  Handles onboarding completion logic.
//
//  Permissions Flow:
//  - Location (When In Use): Requested here during onboarding.
//  - Notifications: Requested on the second app visit (handled in HomeView.onAppear).
//  - Location (Always Allow): Requested when the user starts a trip.
//

import SwiftUI
import SwiftData

struct OnboardingViewModel {

    /// Completes onboarding: requests When In Use location permission
    /// and marks first launch as done in SwiftData.
    func completeOnboarding(context: ModelContext) {
        markOnboardingComplete(context: context)
    }

    /// Saves isFirstLaunch = false to AppSettings in SwiftData.
    private func markOnboardingComplete(context: ModelContext) {
        let descriptor = FetchDescriptor<AppSettings>()
        if let existing = try? context.fetch(descriptor).first {
            existing.isFirstLaunch = false
        } else {
            let settings = AppSettings()
            settings.isFirstLaunch = false
            context.insert(settings)
        }
    }
}
