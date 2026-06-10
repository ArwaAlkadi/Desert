//
//  AppSettings.swift
//  Desert
//

import SwiftData
import Foundation

/// Persists global app state — one instance per install.
///
/// ## Responsibilities
/// 1. Tracking whether the user has completed onboarding
/// 2. Storing the active trip ID so the session can be resumed after the app restarts
@Model
class AppSettings {

    // MARK: - Stored

    /// `false` once the user completes onboarding. Controls which screen `RootView` shows.
    var isFirstLaunch: Bool

    /// The ID of the currently active trip. Empty string means no trip is in progress.
    var currentTripId: String

    // MARK: - Init

    init() {
        self.isFirstLaunch = true
        self.currentTripId = ""
    }

    // MARK: - Computed

    /// `true` if a trip is currently active.
    var hasActiveTrip: Bool { !currentTripId.isEmpty }
}
