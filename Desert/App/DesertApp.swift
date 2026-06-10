//
//  DesertApp.swift
//  Desert
//
import SwiftUI
import Firebase
import SwiftData
import Combine
import Network
import CoreText

@main
struct DesertApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    init() {
        registerFonts()
        
        if UserDefaults.standard.object(forKey: "AppLanguageSet") == nil {
            UserDefaults.standard.set(["ar"], forKey: "AppleLanguages")
            UserDefaults.standard.set(true, forKey: "AppLanguageSet")
        }
        
        print("Current Language:", Locale.current.language.languageCode?.identifier ?? "nil")
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.light)
                .environment(
                    \.layoutDirection,
                     AppLanguage.isArabic ? .rightToLeft : .leftToRight
                )
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
    
    private func registerFonts() {
        let fontNames = [
            "thmanyahsans-Regular",
            "thmanyahsans-Bold",
            "thmanyahsans-Light",
            "thmanyahsans-Black"
        ]
        
        for fontName in fontNames {
            guard let fontURL = Bundle.main.url(forResource: fontName, withExtension: "otf") else {
                print("Font file not found:", fontName)
                continue
            }
            
            CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
        }
    }
}
