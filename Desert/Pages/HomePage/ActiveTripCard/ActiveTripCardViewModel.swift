//
//  ActiveTripCardViewModel.swift
//  Desert
//

import Foundation
import SwiftUI
import SwiftData
import Network
import Combine

class ActiveTripCardViewModel: ObservableObject {

    @Published var returnTimeUploadStatus: UploadStatus = .idle
    @Published var isConnected = true

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "ActiveTripNetworkMonitor")

    enum UploadStatus {
        case idle
        case uploading
        case uploaded
        case pending

        var label: String {
            switch self {
            case .idle: return ""
            case .uploading: return "uploading".localized
            case .uploaded: return "uploaded".localized
            case .pending: return "pending_upload".localized
            }
        }
    }

    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }

        monitor.start(queue: queue)
    }

    func stopMonitoring() {
        monitor.cancel()
    }

    func daysLeftText(for returnTime: Date) -> String {

        let seconds = returnTime.timeIntervalSince(Date())

        if seconds <= 0 {

            let overdueSeconds = abs(seconds)

            let days = Int(overdueSeconds / 86400)
            let hours = Int(overdueSeconds / 3600)
            let minutes = Int(overdueSeconds / 60)

            if days > 0 {
                return String(format: "activeTrip.daysOverdue".localized, days)
            } else if hours > 0 {
                return String(format: "activeTrip.hoursOverdue".localized, hours)
            } else {
                return String(format: "activeTrip.minutesOverdue".localized, minutes)
            }
        }

        let days = Int(seconds / 86400)
        let hours = Int(seconds / 3600)

        if days > 0 {
            return String(format: "activeTrip.daysLeft".localized, days)
        } else {
            return String(format: "activeTrip.hoursLeft".localized, hours)
        }
    }

    func rescheduleReturnTimeReminder(returnTime: Date) {
        TripSessionManager.shared.rescheduleReturnTimeReminder(returnTime: returnTime)
    }

    func endTrip(_ trip: Trip, context: ModelContext) {
        TripSessionManager.shared.finishTrip(trip: trip, context: context)
    }

    func saveReturnTime(
        trip: Trip,
        editedReturnTime: Date
    ) {
        guard editedReturnTime > Date() else { return }

        returnTimeUploadStatus = isConnected ? .uploading : .pending

        TripSessionManager.shared.updateReturnTime(
            trip: trip,
            newReturnTime: editedReturnTime
        ) { [weak self] in
            DispatchQueue.main.async {
                self?.returnTimeUploadStatus = .uploaded
            }
        } onFailure: { [weak self] in
            DispatchQueue.main.async {
                self?.returnTimeUploadStatus = .pending
            }
        }
    }
}
