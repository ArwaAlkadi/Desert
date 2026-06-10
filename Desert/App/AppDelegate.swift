//
//  AppDelegate.swift
//  Desert
//

import Firebase

// MARK: - AppDelegate

/// Entry point for app-level setup — runs before any view appears.
class AppDelegate: NSObject, UIApplicationDelegate {

    /// Bootstraps Firebase, anonymous auth, location delegation, and force-quit recovery.
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {

        // 1. Configure Firebase
        FirebaseApp.configure()

        // 2. Sign in anonymously — persists userId on device across sessions
        FirebaseManager.shared.signInAnonymously()

        // 3. Set ActiveTripSession as LocationManager delegate — wires GPS updates to trip logic
        LocationManager.shared.delegate = ActiveTripSession.shared

        // 4. If iOS relaunched due to a background location update — restore the active session
        if launchOptions?[.location] != nil {
            LocationManager.shared.restoreSessionAfterForceQuit()
        }

        return true
    }
}
