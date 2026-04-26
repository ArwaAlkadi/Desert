//
//  DesertApp.swift
//  Desert
//

import SwiftUI

import SwiftUI
import Firebase
import SwiftData

@main
struct DesertApp: App {
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
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
}
