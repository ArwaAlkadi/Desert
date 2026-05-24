//
//  TripSummaryView.swift
//  Desert
//

import SwiftUI
import SwiftData
import Network

struct TripSummaryView: View {

    @ObservedObject var vm: TripsViewModel
    var isRepeat: Bool = false
    var onTripStarted: () -> Void

    @Environment(\.modelContext) private var context

    @State private var goHome = false
    @State private var isConnected = true

    private let monitor = NWPathMonitor()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                if isRepeat && !vm.returnTimeIsValid {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.red)

                        Text("update_return_time_warning".localized)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.08))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }

                VStack(spacing: 0) {
                    SummaryRow(
                        label: "trip_name",
                        value: vm.tripName.isEmpty ? formatDefaultName() : vm.tripName
                    )

                    Divider().padding(.leading)

                    if isRepeat {
                        HStack {
                            Text("return_time".localized)
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Spacer()

                            DatePicker(
                                "",
                                selection: $vm.returnTime,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .labelsHidden()
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)

                        Divider().padding(.leading)

                    } else {
                        SummaryRow(label: "start_time", value: formatDate(Date()))
                        Divider().padding(.leading)

                        SummaryRow(label: "return_time", value: formatDate(vm.returnTime))
                        Divider().padding(.leading)
                    }

                    SummaryRow(
                        label: "destination",
                        value: vm.destination.isEmpty ? "—" : vm.destination
                    )

                    Divider().padding(.leading)

                    SummaryRow(
                        label: "car_details",
                        value: vm.carName.isEmpty ? "—" : "\(vm.carColor) \(vm.carName)"
                    )

                    Divider().padding(.leading)

                    SummaryRow(
                        label: "plate_number",
                        value: vm.plateLetters.isEmpty ? "—" : "\(vm.plateNumbers) | \(vm.plateLetters)"
                    )

                    Divider().padding(.leading)

                    SummaryRow(
                        label: "individuals",
                        value: vm.hasGroup
                            ? String(format: "people_count".localized, vm.groupSize)
                            : "solo".localized
                    )
                }
                .background(Color(UIColor.systemBackground))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(.systemGray5), lineWidth: 0.5)
                )
                .padding(.horizontal)

                if !vm.emergencyContacts.isEmpty {
                    contactSection(
                        title: "emergency_contacts".localized,
                        contacts: vm.emergencyContacts
                    )
                }

                if vm.hasGroup && !vm.groupContacts.isEmpty {
                    contactSection(
                        title: "group_contacts_optional".localized,
                        contacts: vm.groupContacts
                    )
                }

                Text("trip_safety_notice".localized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.yellow.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(.systemGray5), lineWidth: 0.5)
                    )
                    .cornerRadius(16)
                    .padding(.horizontal)

                if !isConnected {
                    Text("no_internet_connection".localized)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }

                Button(action: {
                    // Prevent starting a new trip if one is already active
                    guard !TripSessionManager.shared.hasActiveTrip else { return }

                    let started = vm.startTrip(context: context)

                    if started {
                        goHome = true
                        onTripStarted()
                    }
                }) {
                    Text("start_trip".localized)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background((vm.formIsValid && isConnected) ? Color.primary : Color(.systemGray4))
                        .foregroundColor(Color(UIColor.systemBackground))
                        .cornerRadius(14)
                }
                .disabled(!vm.formIsValid || !isConnected)
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .padding(.vertical)
        }
        .navigationTitle("summary".localized)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(UIColor.systemGroupedBackground))
        .navigationDestination(isPresented: $goHome) {
            HomeView()
        }
        .alert(vm.locationAlertTitle, isPresented: $vm.showLocationAlert) {
            Button("open_settings".localized) {
                vm.openAppSettings()
            }

            Button("cancel".localized, role: .cancel) { }

        } message: {
            Text(vm.locationAlertMessage)
        }
        .onAppear {
            monitor.pathUpdateHandler = { path in
                DispatchQueue.main.async {
                    isConnected = path.status == .satisfied
                }
            }

            let queue = DispatchQueue(label: "NetworkMonitor")
            monitor.start(queue: queue)
        }
        .onDisappear {
            monitor.cancel()
        }
    }

    @ViewBuilder
    func contactSection(title: String, contacts: [Contact]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 0) {
                ForEach(contacts, id: \.name) { contact in
                    ContactRow(contact: contact)

                    if contact.name != contacts.last?.name {
                        Divider().padding(.leading, 60)
                    }
                }
            }
            .background(Color(UIColor.systemBackground))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(.systemGray5), lineWidth: 0.5)
            )
            .padding(.horizontal)
        }
    }

    func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "d MMMM, h:mma"
        return f.string(from: date)
    }

    func formatDefaultName() -> String {
        let f = DateFormatter()
        f.dateFormat = "d MMM"
        return "\(f.string(from: Date())) Trip"
    }
}

struct RepeatTripSummaryView: View {

    var trip: Trip
    var onTripStarted: () -> Void

    @Environment(\.modelContext) private var context
    @StateObject private var vm = TripsViewModel()

    @State private var returnTimeChanged = false
    @State private var originalReturnTime: Date = Date()
    @State private var goHome = false
    @State private var isConnected = true

    private let monitor = NWPathMonitor()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                VStack(alignment: .leading, spacing: 8) {
                    Text("update_return_time".localized)
                        .font(.headline)
                        .padding(.horizontal)

                    if !returnTimeChanged {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)

                            Text("update_return_time_warning".localized)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.08))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }

                    VStack(spacing: 0) {
                        HStack {
                            Text("return_time".localized)
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Spacer()

                            DatePicker(
                                "",
                                selection: $vm.returnTime,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .labelsHidden()
                        }
                        .padding(12)
                    }
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                returnTimeChanged ? Color(.systemGray5) : Color.red.opacity(0.4),
                                lineWidth: returnTimeChanged ? 0.5 : 1.5
                            )
                    )
                    .padding(.horizontal)

                    if returnTimeChanged {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)

                            Text("return_time_updated".localized)
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.green.opacity(0.08))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                }

                Divider().padding(.horizontal)

                SummarySection(title: "destination_group") {
                    SummaryRow(label: "destination", value: trip.destination)
                    Divider()

                    SummaryRow(
                        label: "group",
                        value: trip.hasGroup
                            ? String(format: "people_count".localized, trip.groupSize)
                            : "solo".localized
                    )
                }

                SummarySection(title: "car") {
                    SummaryRow(label: "car", value: "\(trip.carName) · \(trip.carColor)")
                    Divider()

                    SummaryRow(label: "4wd", value: trip.is4WD ? "yes".localized : "no".localized)
                    Divider()

                    SummaryRow(label: "plate", value: "\(trip.plateLetters) \(trip.plateNumbers)")
                }

                SummarySection(
                    title: String(
                        format: "emergency_contacts_count".localized,
                        trip.emergencyContacts.count
                    )
                ) {
                    ForEach(trip.emergencyContacts, id: \.name) { contact in
                        SummaryRow(label: contact.name, value: contact.phone)

                        if contact.name != trip.emergencyContacts.last?.name {
                            Divider()
                        }
                    }
                }

                Text("trip_safety_notice".localized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.yellow.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(.systemGray5), lineWidth: 0.5)
                    )
                    .cornerRadius(16)
                    .padding(.horizontal)

                if !isConnected {
                    Text("no_internet_connection".localized)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }

                Button(action: {
                    // Prevent starting a new trip if one is already active
                    guard !TripSessionManager.shared.hasActiveTrip else { return }

                    let started = vm.startTrip(context: context)

                    if started {
                        goHome = true
                        onTripStarted()
                    }
                }) {
                    Text("start_trip".localized)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background((returnTimeChanged && isConnected) ? Color.primary : Color(.systemGray4))
                        .foregroundColor(Color(UIColor.systemBackground))
                        .cornerRadius(14)
                }
                .disabled(!returnTimeChanged || !isConnected)
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .padding(.vertical)
        }
        .navigationTitle("repeat_trip".localized)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(UIColor.systemGroupedBackground))
        .navigationDestination(isPresented: $goHome) {
            HomeView()
        }
        .alert(vm.locationAlertTitle, isPresented: $vm.showLocationAlert) {
            Button("open_settings".localized) {
                vm.openAppSettings()
            }

            Button("cancel".localized, role: .cancel) { }

        } message: {
            Text(vm.locationAlertMessage)
        }
        .onAppear {
            vm.loadTripData(from: trip)
            originalReturnTime = vm.returnTime

            monitor.pathUpdateHandler = { path in
                DispatchQueue.main.async {
                    isConnected = path.status == .satisfied
                }
            }

            let queue = DispatchQueue(label: "NetworkMonitor")
            monitor.start(queue: queue)
        }
        .onDisappear {
            monitor.cancel()
        }
        .onChange(of: vm.returnTime) { _, newValue in
            returnTimeChanged = newValue != originalReturnTime
        }
    }
}
