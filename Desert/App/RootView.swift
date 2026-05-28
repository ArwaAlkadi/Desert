//
//  RootView.swift
//  Desert
//

import Foundation
import SwiftUI
import SwiftData
import UIKit

struct RootView: View {

    @StateObject private var networkMonitor = NetworkMonitorHelper()
    
    @Query var settings: [AppSettings]

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

            } else if maintenanceEnabled {
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

                #if DEBUG
                GridOverlay()
                #endif

                if networkMonitor.showOfflineToast {
                    NetworkStatusBanner(status: .disconnected)
                        .padding(.horizontal, AppSpacing.md)
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
        .alert("Update Required", isPresented: $showUpdateAlert) {
            Button("Update Now") {
                openAppStore()
            }
        } message: {
            Text(updateMessage)
        }
        .simultaneousGesture(
            TapGesture().onEnded {
                hideKeyboard()
            }
        )
        
    }
    

    // MARK: - Maintenance Check

    private func checkMaintenance() async {
        do {
            let config = try await FirebaseManager.shared.fetchMaintenanceConfig()

            await MainActor.run {
                maintenanceEnabled = config.isEnabled
                maintenanceTitle = config.title
                maintenanceMessage = config.message
            }

        } catch {
            print("Failed to check maintenance: \(error.localizedDescription)")
        }
    }

    // MARK: - Version Check

    private func checkVersion() async {
        let currentVersion =
            Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"

        do {
            let config = try await FirebaseManager.shared.fetchAppUpdateConfig()

            if FirebaseManager.isOlderVersion(
                current: currentVersion,
                required: config.minimumVersion
            ) {
                await MainActor.run {
                    updateMessage = config.message
                    appStoreURL = config.appStoreURL
                    showUpdateAlert = true
                }
            }

        } catch {
            print("Failed to check app version: \(error.localizedDescription)")
        }
    }

    private func openAppStore() {
        guard let url = URL(string: appStoreURL),
              !appStoreURL.isEmpty else { return }

        UIApplication.shared.open(url)
    }
}
