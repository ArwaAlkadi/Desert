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

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // MARK: - Header (always visible)
            Button(action: {
                withAnimation(.spring()) { isExpanded.toggle() }
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(trip.tripName)
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text(trip.destination)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()

                    HStack(spacing: 4) {
                        Circle()
                            .fill(trip.isOverdue ? Color.orange : Color.green)
                            .frame(width: 8, height: 8)
                        Text(trip.isOverdue ? "overdue".localized : "active".localized)
                            .font(.caption)
                            .foregroundColor(trip.isOverdue ? .orange : .green)
                    }
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background((trip.isOverdue ? Color.orange : Color.green).opacity(0.1))
                    .cornerRadius(8)

                    Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 4)
                }
            }

            // MARK: - Expanded Content
            if isExpanded {
                Divider().padding(.top, 10)

                VStack(alignment: .leading, spacing: 12) {

                    // Return Time — editable
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("return_time".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            // Upload status indicator
                            if returnTimeUploadStatus != .idle {
                                HStack(spacing: 4) {
                                    Image(systemName: returnTimeUploadStatus.icon)
                                        .font(.caption2)
                                    Text(returnTimeUploadStatus.label)
                                        .font(.caption2)
                                }
                                .foregroundColor(returnTimeUploadStatus.color)
                            }
                        }

                        if isEditingReturnTime {
                            HStack {
                                DatePicker(
                                    "",
                                    selection: $editedReturnTime,
                                    displayedComponents: [.date, .hourAndMinute]
                                )
                                .labelsHidden()

                                Spacer()

                                // Save button
                                Button(action: { saveReturnTime() }) {
                                    Text("save".localized)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.primary)
                                        .foregroundColor(Color(UIColor.systemBackground))
                                        .cornerRadius(8)
                                }

                                // Cancel button
                                Button(action: { isEditingReturnTime = false }) {
                                    Text("cancel".localized)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        } else {
                            HStack {
                                Text(formatDate(trip.returnTime))
                                    .font(.caption)
                                    .fontWeight(.medium)
                                Spacer()
                                // Edit button
                                Button(action: {
                                    editedReturnTime = trip.returnTime
                                    isEditingReturnTime = true
                                }) {
                                    Image(systemName: "pencil")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                    // Last Upload
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("last_upload".localized)
                                .font(.caption).foregroundColor(.secondary)
                            Text(trip.lastUploadTime != nil
                                 ? formatDate(trip.lastUploadTime!)
                                 : "not_yet".localized)
                                .font(.caption).fontWeight(.medium)
                        }
                        Spacer()
                        Text(String(format: "gps_points".localized, trip.gpsTrack.count))
                            .font(.caption).foregroundColor(.secondary)
                    }

                    // Connection status
                    if !isConnected {
                        HStack(spacing: 4) {
                            Image(systemName: "wifi.slash")
                                .font(.caption2)
                            Text("no_connection".localized)
                                .font(.caption2)
                        }
                        .foregroundColor(.orange)
                    }

                    if !trip.emergencyContacts.isEmpty {
                        Text("\("emergency".localized): \(trip.emergencyContacts.map { $0.name }.joined(separator: ", "))")
                            .font(.caption).foregroundColor(.secondary)
                    }

                    Divider()

                    Button(action: { vm.endTrip(trip, context: context) }) {
                        Text("im_back_safely".localized)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.primary)
                            .foregroundColor(Color(UIColor.systemBackground))
                            .cornerRadius(10)
                    }
                }
                .padding(.top, 10)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
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
