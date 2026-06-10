//
//  RootView.swift
//  Desert
//

import Foundation
import SwiftUI
import SwiftData
import UIKit

/// The app's root view — decides which screen to show based on app state.
///
/// ## Screen Routing
/// | Condition | Screen Shown |
/// |---|---|
/// | `showSplash == true` | `SplashView` |
/// | Maintenance mode ON (no active trip) | `MaintenanceView` |
/// | First launch / no settings | `OnboardingView` |
/// | Default | `HomeView` |
///
/// ## Responsibilities
/// 1. Routing to the correct screen on launch
/// 2. Checking maintenance mode and app version from Firebase on appear
/// 3. Showing a forced update alert when the installed version is too old
/// 4. Displaying the offline/online toast banner globally
struct RootView: View {

    @StateObject private var networkMonitor = NetworkMonitorHelper()

    @Query var settings: [AppSettings]
    @Query(filter: #Predicate<Trip> { $0.status == "active" || $0.status == "overdue" })
    
    var activeTrips: [Trip]
    
    @State private var showSplash = true

    @State private var showUpdateAlert = false
    @State private var updateMessage = ""
    @State private var appStoreURL = ""

    @State private var maintenanceEnabled = false
    @State private var maintenanceTitle = "Maintenance Mode"
    @State private var maintenanceMessage = "Desert is currently under maintenance."

    var appSettings: AppSettings? { settings.first }

    var body: some View {
        Group {
            if showSplash {
                SplashView(showSplash: $showSplash)

            } else if maintenanceEnabled && activeTrips.isEmpty {
                MaintenanceView(
                    title: maintenanceTitle,
                    message: maintenanceMessage
                )

            } else if appSettings == nil || appSettings?.isFirstLaunch == true {
                OnboardingView()

            } else {
                HomeView()
            }
        }
        .overlay(alignment: .top) {
            ZStack(alignment: .top) {
                if networkMonitor.showOfflineToast {
                    NetworkStatusBanner(status: .disconnected)
                        .padding(.horizontal, AppSpacing.md)
                        .onTapGesture {
                            networkMonitor.dismissOfflineToast()
                        }
                }

                if networkMonitor.showOnlineToast {
                    NetworkStatusBanner(status: .connected)
                        .padding(.horizontal, AppSpacing.md)
                }
            }
        }
        .onAppear {
            networkMonitor.startMonitoring()
        }
        .onDisappear {
            networkMonitor.stopMonitoring()
        }
        .task {
            await checkMaintenance()
            await checkVersion()
        }
        .alert("update_required.title".localized, isPresented: $showUpdateAlert) {
            Button("update_required.button".localized) {
                openAppStore()
            }
        } message: {
            Text(updateMessage)
        }
        .simultaneousGesture(
            TapGesture().onEnded { hideKeyboard() }
        )
    }
}


// MARK: - Remote Checks

extension RootView {

    /// Fetches maintenance config from Firebase and updates the screen state.
    private func checkMaintenance() async {
        do {
            let config = try await FirebaseManager.shared.fetchMaintenanceConfig()
            await MainActor.run {
                maintenanceEnabled = config.isEnabled
                maintenanceTitle = config.title
                maintenanceMessage = config.message
            }
        } catch {
            print("RootView: failed to check maintenance — \(error.localizedDescription)")
        }
    }

    /// Compares the installed version against the Firebase minimum version.
    /// Shows a forced update alert if the app is too old — skipped during an active trip.
    private func checkVersion() async {
        let currentVersion =
            Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"

        do {
            let config = try await FirebaseManager.shared.fetchAppUpdateConfig()

            if FirebaseManager.isOlderVersion(current: currentVersion, required: config.minimumVersion)
                && !ActiveTripSession.shared.hasActiveTrip {
                await MainActor.run {
                    updateMessage = config.message
                    appStoreURL = config.appStoreURL
                    showUpdateAlert = true
                }
            }
        } catch {
            print("RootView: failed to check app version — \(error.localizedDescription)")
        }
    }

    /// Opens the App Store URL from the Firebase config.
    private func openAppStore() {
        guard let url = URL(string: appStoreURL), !appStoreURL.isEmpty else { return }
        UIApplication.shared.open(url)
    }
}
