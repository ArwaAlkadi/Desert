//
//  CreateTripStepsView.swift
//  Desert
//

import SwiftUI
import SwiftData
import ContactsUI

struct CreateTripStepsView: View {

    @Binding var showParentSheet: Bool
    var tripToRepeat: Trip? = nil
    var onTripStarted: (() -> Void)? = nil
    var onCancel: (() -> Void)? = nil

    @Environment(\.modelContext) private var context
    @Environment(\.layoutDirection) private var layoutDirection
    @Environment(\.dismiss) private var dismiss

    @Query var savedInfo: [SavedInfo]
    @StateObject private var vm = CreateTripViewModel()

    @State private var currentStep = 0
    @State private var showSummary = false
    @State private var showExitAlert = false

    @FocusState private var isInputFocused: Bool

    private let totalSteps = 3

    var stepTitles: [String] {
        [
            "step_personal_details".localized,
            "step_vehicle_details".localized,
            "step_trip_details".localized,
        ]
    }

    // MARK: - Body
    var body: some View {
        CreateTripStepTemplate(
            titleKey: stepTitles[currentStep],
            currentStep: currentStep + 1,
            buttonTitleKey: currentStep == totalSteps - 1
                ? "review"
                : "common.next",
            leadingButton: currentStep == 0 ? .close : .back,
            isInputFocused: isInputFocused,
            onBack: {
                handleBackAction()
            },
            onNext: {
                handleNextAction()
            }
        ) {
            stepContent
                .animation(.easeInOut, value: currentStep)
        }
        .background(
            NavigationGestureDisabler()
        )
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .alert("discard_changes_title".localized, isPresented: $showExitAlert) {
            Button("cancel".localized, role: .cancel) { }

            Button("discard".localized, role: .destructive) {
                closeView()
            }
        } message: {
            Text("discard_changes_message".localized)
        }
        .navigationDestination(isPresented: $showSummary) {
            TripSummaryView(
                vm: vm,
                onTripStarted: {
                    showParentSheet = false
                    onTripStarted?()
                },
                onReturnTimeInvalid: {
                    showSummary = false
                    currentStep = 2
                }
            )
        }
        .navigationDestination(isPresented: $vm.showDestinationPicker) {
            DestinationPickerView(vm: vm)
        }
        .sheet(isPresented: $vm.showEmergencyContactPicker) {
            SingleContactPickerView {
                vm.importEmergencyContact($0)
            }
        }
        .sheet(isPresented: $vm.showGroupContactPicker) {
            MultiContactPickerView { contacts in
                contacts.forEach { vm.importGroupContact($0) }
            }
        }
        .alert("location_permission_required".localized, isPresented: $vm.showLocationAlert) {
            Button("open_settings".localized) { vm.openAppSettings() }
            Button("cancel".localized, role: .cancel) { }
        } message: {
            Text(vm.locationAlertMessage)
        }
        .onAppear {
            guard !vm.hasLoadedInitialData else { return }
            if let trip = tripToRepeat {
                vm.loadTripForRepeat(trip)
                currentStep = 2
            } else {
                vm.loadSavedInfo(savedInfo.first)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CreateTripStepsView(showParentSheet: .constant(true))
    }
    .modelContainer(for: [
        SavedInfo.self,
        SavedContact.self,
        Trip.self
    ], inMemory: true)
}

// MARK: - Steps

extension CreateTripStepsView {

    @ViewBuilder
    var stepContent: some View {
        switch currentStep {
        case 0: personalDetailsView
        case 1: vehicleDetailsView
        case 2: tripDetailsView
        default: EmptyView()
        }
    }

    var personalDetailsView: some View {
        PersonalDetailsTemplate(
            fullName: $vm.fullName,
            phoneNumber: vm.localPhoneBinding,
            emergencyContacts: $vm.emergencyContacts,
            contactErrorMessage: vm.emergencyContactErrorMessage,
            showErrors: vm.showStep0Errors,
            isPhoneNumberValid: vm.phoneNumberIsValid,
            phoneError: vm.phoneError,
            onAddContact: { vm.showEmergencyContactPicker = true }
        )
    }

    var vehicleDetailsView: some View {
        VehicleDetailsTemplate(
            carModel: $vm.carModel,
            selectedColor: $vm.selectedColor,
            isFourWheelDrive: $vm.isFourWheelDrive,
            firstPlateLetter: $vm.firstPlateLetter,
            secondPlateLetter: $vm.secondPlateLetter,
            thirdPlateLetter: $vm.thirdPlateLetter,
            plateDigits: $vm.plateDigits,
            showErrors: vm.showStep1Errors
        )
    }

    var tripDetailsView: some View {
        TripDetailsTemplate(
            tripName: $vm.tripName,
            destination: $vm.destination,
            returnTime: $vm.returnTime,
            isGroup: $vm.isGroup,
            groupCount: $vm.groupCount,
            groupContacts: $vm.groupContacts,
            contactErrorMessage: vm.groupContactErrorMessage,
            showErrors: vm.showStep2Errors,
            onSelectDestination: { vm.showDestinationPicker = true },
            onAddGroupContact: { vm.showGroupContactPicker = true }
        )
    }

    // MARK: - Actions

    private func handleBackAction() {
        guard currentStep == 0 else {
            currentStep -= 1
            return
        }
        if vm.hasUserEnteredData {
            showExitAlert = true
        } else {
            closeView()
        }
    }

    private func handleNextAction() {
        guard vm.canProceedFromStep(currentStep) else { return }
        if currentStep == totalSteps - 1 {
            showSummary = true
        } else {
            currentStep += 1
        }
    }

    private func closeView() {
        if let onCancel {
            onCancel()
        } else {
            showParentSheet = false
            dismiss()
        }
    }
}
