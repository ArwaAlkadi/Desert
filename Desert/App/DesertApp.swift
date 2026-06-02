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
        
        for family in UIFont.familyNames.sorted() {
            if family.lowercased().contains("thmanyah") {
                print("Family:", family)
                
                for name in UIFont.fontNames(forFamilyName: family) {
                    print("   Font:", name)
                }
            }
        }
    }
}
