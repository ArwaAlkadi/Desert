//
//  NetworkMonitorHelper.swift
//  Desert
//

import Network
import Combine
import SwiftUI

/// Monitors network connectivity and drives the offline/online toast banners.
///
/// ## Responsibilities
/// 1. Detecting connectivity changes via `NWPathMonitor`
/// 2. Showing an offline toast when the connection drops (auto-dismisses after 4s)
/// 3. Showing an online toast when the connection is restored (auto-dismisses after 2s)
///
/// ## Notes
/// - The online toast only appears if the device was previously offline — not on first connect.
class NetworkMonitorHelper: ObservableObject {

    // MARK: - Published

    @Published var isConnected = true
    @Published var showOfflineToast = false
    @Published var showOnlineToast = false

    // MARK: - Private

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    /// Tracks whether the device went offline at least once this session.
    private var wasOffline = false

    /// Starts listening for connectivity changes.
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.handleConnectionChange(path.status == .satisfied)
            }
        }
        monitor.start(queue: queue)
    }

    /// Stops the network monitor. Call from `onDisappear`.
    func stopMonitoring() {
        monitor.cancel()
    }

    /// Manually dismisses the offline toast — e.g. when the user taps it.
    func dismissOfflineToast() {
        withAnimation {
            showOfflineToast = false
        }
    }

    /// Handles a connectivity state change and updates toast visibility accordingly.
    private func handleConnectionChange(_ isConnected: Bool) {
        self.isConnected = isConnected

        if !isConnected {
            wasOffline = true

            withAnimation {
                showOfflineToast = true
                showOnlineToast = false
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in
                withAnimation { self?.showOfflineToast = false }
            }

        } else if wasOffline {
            withAnimation {
                showOfflineToast = false
                showOnlineToast = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                withAnimation { self?.showOnlineToast = false }
            }

            wasOffline = false
        }
    }
}
