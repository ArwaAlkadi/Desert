//
//  ActiveTripCardView.swift
//  Desert
//
//  Collapsible card shown at the bottom of the map during an active trip.
//
//  Collapsed: trip name, destination, Active/Overdue badge.
//  Expanded:  return time (editable), last upload time, GPS point count,
//             emergency contacts, upload status, end trip button.
//
//  Tapping the header toggles between collapsed and expanded states.
//  "I'm Back Safely" ends the trip via HomeViewModel → TripSessionManager.
//  Return time edits are saved locally and synced to Firebase if online.
//
//  Layout direction:
//  - All HStack elements respect the system language direction automatically (LTR/RTL).
//

import SwiftUI
import SwiftData
import Network

struct ActiveTripCardView: View {

    var trip: Trip
    @Environment(\.modelContext) private var context
    @State private var isExpanded = false

    // Return time editing
    @State private var isEditingReturnTime = false
    @State private var editedReturnTime: Date = Date()

    // Upload status
    @State private var returnTimeUploadStatus: UploadStatus = .idle
    private let monitor = NWPathMonitor()
    @State private var isConnected = true

    private let vm = HomeViewModel()

    // MARK: - Upload Status

    enum UploadStatus {
        case idle
        case uploading
        case uploaded
        case pending  // saved locally, waiting for connection

        var label: String {
            switch self {
            case .idle:      return ""
            case .uploading: return "uploading".localized
            case .uploaded:  return "uploaded".localized
            case .pending:   return "pending_upload".localized
            }
        }

        var color: Color {
            switch self {
            case .idle:      return .clear
            case .uploading: return .secondary
            case .uploaded:  return .green
            case .pending:   return .orange
            }
        }

        var icon: String {
            switch self {
            case .idle:      return ""
            case .uploading: return "arrow.up.circle"
            case .uploaded:  return "checkmark.circle.fill"
            case .pending:   return "clock.arrow.circlepath"
            }
        }
    }

    private var daysLeftText: String {
        let seconds = trip.returnTime.timeIntervalSince(Date())

        if seconds <= 0 {
            return "activeTrip.overdue".localized
        }

        let days = Int(seconds / 86400)
        let hours = Int(seconds / 3600)

        if days > 0 {
            return String(format: "activeTrip.daysLeft".localized, days)
        } else {
            return String(format: "activeTrip.hoursLeft".localized, hours)
        }
    }
    
        var body: some View {
            ActiveTripCard(
                tripName: trip.tripName,
                daysLeft: daysLeftText,
                isUploaded: returnTimeUploadStatus == .uploaded,
                returnTime: trip.returnTime,
                isOverdue: trip.isOverdue,
                emergencyContacts: trip.emergencyContacts,
                onUpdateReturnTime: { newTime in
                    editedReturnTime = newTime
                    saveReturnTime()
                },
                onEndTrip: {
                    vm.endTrip(trip, context: context)
                }
            )
            .onAppear {
                monitor.pathUpdateHandler = { path in
                    DispatchQueue.main.async {
                        isConnected = path.status == .satisfied
                    }
                }
                monitor.start(queue: DispatchQueue(label: "ActiveTripNetworkMonitor"))
            }
            .onDisappear {
                monitor.cancel()
            }
        }
  

    // MARK: - Save Return Time

    /// Saves the updated return time locally (SwiftData) and syncs to Firebase if online.
    /// If offline, marks status as pending — will sync when connection is restored.
    private func saveReturnTime() {
        guard editedReturnTime > Date() else { return }

        // Save locally first — always succeeds
        trip.returnTime = editedReturnTime
        isEditingReturnTime = false

        // Reschedule via HomeViewModel — no direct Manager access from View
        vm.rescheduleReturnTimeReminder(returnTime: editedReturnTime)

        if isConnected {
            // Online — upload to Firebase immediately
            returnTimeUploadStatus = .uploading
            FirebaseManager.shared.updateReturnTime(
                tripId: trip.tripId,
                returnTime: editedReturnTime
            ) {
                DispatchQueue.main.async {
                    returnTimeUploadStatus = .uploaded
                    // Reset status after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        returnTimeUploadStatus = .idle
                    }
                }
            } onFailure: {
                DispatchQueue.main.async {
                    returnTimeUploadStatus = .pending
                }
            }
        } else {
            // Offline — mark as pending
            returnTimeUploadStatus = .pending
        }
    }

    func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "dd/MM - hh:mm a"
        return f.string(from: date)
    }
}
