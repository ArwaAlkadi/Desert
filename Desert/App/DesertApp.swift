//
//  DesertApp.swift
//  Desert
//

import SwiftUI
import Firebase
import SwiftData
import Combine
import Network

/// App entry point — configures Firebase and registers SwiftData models.
@main
struct DesertApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.light)
        }
        .modelContainer(for: [
            AppSettings.self,
            SavedInfo.self,
            SavedContact.self,
            Trip.self,
            Contact.self,
            LocationPoint.self
        ])
    }
    
    init() {
        if UserDefaults.standard.object(forKey: "AppLanguageSet") == nil {
            UserDefaults.standard.set(["en"], forKey: "AppleLanguages")
            UserDefaults.standard.set(true, forKey: "AppLanguageSet")
        }
    }
}

// MARK: - AppDelegate

class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {

        // 1. configure Firebase
        FirebaseApp.configure()

        // 2. sign in anonymously — persists userId on device
        FirebaseManager.shared.signInAnonymously()

        // 3. set TripSessionManager as LocationManager delegate
        LocationManager.shared.delegate = TripSessionManager.shared

        // 4. if iOS relaunched due to location update — restore session
        if launchOptions?[.location] != nil {
            LocationManager.shared.restoreSessionAfterForceQuit()
        }

        return true
    }
}



