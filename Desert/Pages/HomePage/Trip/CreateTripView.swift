//
//  CreateTripView.swift
//  Desert
//
//  Multi-step form for creating a new trip or repeating an existing one.
//
//  Steps:
//  1. Trip Details   — name, destination, time, group
//  2. Personal Info  — name, phone, emergency contacts
//  3. Vehicle Info   — car model, color, 4WD, plate
//
//  Navigation rules:
//  - Progress bar taps only navigate backward (to completed steps).
//  - Next button validates the current step before advancing.
//  - Repeat trip: form is pre-filled and opens directly on Summary.
//  - Back button shows a discard confirmation alert.
//
//  Permission alert:
//  - Triggered when the user taps Start Trip without Always Allow permission.
//  - Directs the user to Settings.
//
//  Layout direction:
//  - All HStack elements respect the system language direction automatically (LTR/RTL).
//


import SwiftUI
import SwiftData
import ContactsUI

struct CreateTripView: View {

    @Binding var showParentSheet: Bool
    var tripToRepeat: Trip? = nil
    var onTripStarted: (() -> Void)? = nil
    var onCancel: (() -> Void)? = nil

    @Environment(\.modelContext) private var context
    @Environment(\.layoutDirection) private var layoutDirection
    @Environment(\.dismiss) private var dismiss

    @Query var savedInfo: [SavedInfo]
    @StateObject private var vm = TripsViewModel()

    @State private var currentStep = 0
    @State private var showSummary = false
    @State private var initialSummaryShown = false
    @State private var showExitAlert = false

    @FocusState private var focusedPlateNumber: Int?
    
    private let totalSteps = 3
    var stepTitles: [String] {
        [
            "step_trip_details".localized,
            "step_personal_details".localized,
            "step_vehicle_details".localized
        ]
    }

    var body: some View {
        VStack(spacing: 0) {

            HStack(spacing: 8) {
                ForEach(0..<totalSteps, id: \.self) { step in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(step <= currentStep ? Color.primary : Color(.systemGray5))
                        .frame(height: 4)
                        .animation(.easeInOut, value: currentStep)
                        .onTapGesture {
                            if step < currentStep {
                                currentStep = step
                            }
                        }
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Group {
                switch currentStep {
                case 0:
                    step1TripDetails
                case 1:
                    step2PersonalInfo
                case 2:
                    step3CarAndContacts
                default:
                    EmptyView()
                }
            }
            .animation(.easeInOut, value: currentStep)

            HStack(spacing: 12) {
                if currentStep > 0 {
                    Button("back".localized) {
                        currentStep -= 1
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(14)
                }

                Button(currentStep == totalSteps - 1 ? "review".localized : "next".localized) {
                    if currentStep == totalSteps - 1 {
                        showSummary = true
                    } else {
                        if canProceedFromStep(currentStep) {
                            currentStep += 1
                        } else {
                            vm.showErrors = true
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.primary)
                .foregroundColor(Color(UIColor.systemBackground))
                .cornerRadius(14)
            }
            .padding()
        }
        .navigationTitle(stepTitles[currentStep])
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    showExitAlert = true
                }) {
                    Image(systemName: layoutDirection == .rightToLeft ? "chevron.right" : "chevron.left")
                        .foregroundColor(.primary)
                }
            }
        }
        .alert("discard_changes_title".localized, isPresented: $showExitAlert) {
            Button("cancel".localized, role: .cancel) { }

            Button("discard".localized, role: .destructive) {
                if let onCancel {
                    onCancel()
                } else {
                    showParentSheet = false
                    dismiss()
                }
            }
        } message: {
            Text("discard_changes_message".localized)
        }
        .navigationDestination(isPresented: $showSummary) {
            TripSummaryView(
                vm: vm,
                isRepeat: tripToRepeat != nil,
                onTripStarted: {
                    showParentSheet = false
                    onTripStarted?()
                }
            )
        }
        .onAppear {
            if let trip = tripToRepeat {
                vm.loadTripData(from: trip)

                if !initialSummaryShown {
                    initialSummaryShown = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        showSummary = true
                    }
                }
            } else {
                vm.loadSavedInfo(savedInfo.first)
            }
        }
        .sheet(isPresented: $vm.showDestinationPicker) {
            DestinationPickerView(
                destination: $vm.destination,
                lat: $vm.destinationLat,
                lng: $vm.destinationLng
            )
        }
        .sheet(isPresented: $vm.showEmergencyContactPicker) {
            ContactPickerSheet {
                vm.importEmergencyContact($0)
            }
        }
        .sheet(isPresented: $vm.showGroupContactPicker) {
            ContactPickerSheet {
                vm.importGroupContact($0)
            }
        }
        .alert("location_permission_required".localized, isPresented: $vm.showLocationAlert) {
            Button("open_settings".localized) {
                vm.openAppSettings()
            }

            Button("cancel".localized, role: .cancel) { }
        } message: {
            Text(vm.locationAlertMessage)
        }
    }

    func canProceedFromStep(_ step: Int) -> Bool {
        switch step {
        case 0:
            return vm.destinationIsValid && vm.returnTimeIsValid
        case 1:
            return vm.userNameIsValid && vm.phoneNumberIsValid && vm.emergencyContactsIsValid
        case 2:
            return true
        default:
            return true
        }
    }
}

// MARK: - Steps

extension CreateTripView {

    /// Step 1: Trip name, destination, start/return time, group size.
    var step1TripDetails: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                FieldSection(title: "trip_name") {
                    TextField(defaultTripName(), text: $vm.tripName)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }

                FieldSection(title: "destination") {
                    Button(action: { vm.showDestinationPicker = true }) {
                        HStack {
                            Text(vm.destination.isEmpty
                                 ? "destination_placeholder".localized
                                 : vm.destination)
                                .foregroundColor(vm.destination.isEmpty ? .secondary : .primary)
                            Spacer()
                            // Chevron flips automatically with RTL layout
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    if vm.showErrors && !vm.destinationIsValid {
                        Text("destination_required".localized)
                            .font(.caption).foregroundColor(.red)
                    }
                }

                FieldSection(title: "time") {
                    HStack(spacing: 12) {
                        // Start time — read-only, auto-filled with current time
                        VStack(alignment: .leading, spacing: 4) {
                            Text("start_time".localized)
                                .font(.caption).foregroundColor(.secondary)
                            Text(formatDate(Date()))
                                .font(.subheadline).foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)

                        // Return time — editable by the user
                        VStack(alignment: .leading, spacing: 4) {
                            Text("end_time".localized)
                                .font(.caption).foregroundColor(.secondary)
                            DatePicker(
                                "",
                                selection: $vm.returnTime,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .labelsHidden()
                            .scaleEffect(0.85, anchor: .leading)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    if vm.showErrors && !vm.returnTimeIsValid {
                        Text("return_time_invalid".localized)
                            .font(.caption).foregroundColor(.red)
                    }
                }

                FieldSection(title: "group") {
                    HStack {
                        Text("group_question".localized).font(.subheadline)
                        Spacer()
                        Toggle("", isOn: $vm.hasGroup).labelsHidden()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    if vm.hasGroup {
                        Stepper(
                            String(format: "group_size".localized, vm.groupSize),
                            value: $vm.groupSize, in: 2...20
                        )
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
            }
            .padding()
        }
    }

    /// Step 2: User name, phone number, emergency contacts, optional group contacts.
    var step2PersonalInfo: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                FieldSection(title: "name") {
                    TextField("full_name_placeholder".localized, text: $vm.userName)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    if vm.showErrors && !vm.userNameIsValid {
                        Text("name_required".localized)
                            .font(.caption).foregroundColor(.red)
                    }
                }

                FieldSection(title: "phone_number") {
                    TextField("phone_placeholder".localized, text: $vm.phoneNumber)
                        .keyboardType(.phonePad)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    if vm.showErrors && !vm.phoneNumberIsValid {
                        Text("phone_required".localized)
                            .font(.caption).foregroundColor(.red)
                    }
                }

                FieldSection(title: "emergency_contacts") {
                    VStack(spacing: 8) {
                        ForEach(vm.emergencyContacts, id: \.name) { contact in
                            ContactRow(contact: contact)
                        }

                        if vm.emergencyContacts.count < 3 {
                            AddContactButton { vm.showEmergencyContactPicker = true }
                        }

                        if vm.showContactError {
                            Text(vm.contactErrorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                        }

                        if vm.emergencyContacts.count >= 3 {
                            Text("max_contacts_reached".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        if vm.showErrors && !vm.emergencyContactsIsValid {
                            Text("emergency_contact_required".localized)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }

                if vm.hasGroup {
                    FieldSection(title: "group_contacts_optional") {
                        VStack(spacing: 8) {
                            ForEach(vm.groupContacts, id: \.name) { contact in
                                ContactRow(contact: contact)
                            }
                            AddContactButton { vm.showGroupContactPicker = true }
                        }
                    }
                }
            }
            .padding()
        }
    }

    /// Step 3: Car model, color, 4WD toggle, and Saudi plate info (3 letters + 4 numbers).
    var step3CarAndContacts: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                FieldSection(title: "car_model") {
                    TextField("car_model_placeholder".localized, text: $vm.carName)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }

                FieldSection(title: "car_color") {
                    TextField("car_color_placeholder".localized, text: $vm.carColor)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }

                FieldSection(title: "4wd") {
                    HStack {
                        Text("4wd_question".localized).font(.subheadline)
                        Spacer()
                        Toggle("", isOn: $vm.is4WD).labelsHidden()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }

                FieldSection(title: "plate_info") {
                    VStack(spacing: 10) {

                        HStack(spacing: 8) {
                            ForEach(0..<3, id: \.self) { index in
                                PlateLetterPicker(
                                    selectedLetters: $vm.plateLetters,
                                    index: index,
                                    letters: vm.saudiPlateLetters,
                                    isArabic: layoutDirection == .rightToLeft
                                )
                            }
                        }

                        HStack(spacing: 8) {
                            ForEach(0..<4, id: \.self) { index in
                                PlateNumberInput(
                                    numbers: $vm.plateNumbers,
                                    index: index,
                                    focusedIndex: $focusedPlateNumber
                                )
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }
            .padding()
        }
    }

    func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "d MMM, h:mm a"
        return f.string(from: date)
    }
    
    func defaultTripName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"

        return "\(formatter.string(from: Date())) Trip"
    }
}
