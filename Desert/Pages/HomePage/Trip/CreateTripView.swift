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
            "step_personal_details".localized,
            "step_vehicle_details".localized,
            "step_trip_details".localized,
        ]
    }


    var body: some View {
        VStack(spacing: 0) {
            
            HeaderView(titleKey: stepTitles[currentStep]) {

                if currentStep == 0 {
                    showExitAlert = true
                } else {
                    currentStep -= 1
                }
            }
            .padding(.top, AppSpacing.sm)
            .padding(.bottom, AppSpacing.md)

            ProgressBar(currentStep: currentStep + 1)
                .padding(.bottom, AppSpacing.xl)
            
            Group {
                switch currentStep {

                case 0:
                    PersonalDetailsTemplate(
                        fullName: $vm.fullName,
                        phoneNumber: $vm.phoneNumber,
                        emergencyContacts: $vm.emergencyContacts,
                        showErrors: vm.showStep0Errors,
                        onAddContact: { vm.showEmergencyContactPicker = true }
                    )
                   

                case 1:
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

                case 2:
                    TripDetailsTemplate(
                        tripName: $vm.tripName,
                        destination: $vm.destination,
                        returnTime: $vm.returnTime,
                        isGroup: $vm.isGroup,
                        groupCount: $vm.groupCount,
                        groupContacts: $vm.groupContacts,
                        showErrors: vm.showStep2Errors,
                        onSelectDestination: { vm.showDestinationPicker = true },
                        onAddGroupContact: { vm.showGroupContactPicker = true }
                    )

                default:
                    EmptyView()
                }
            }
            .animation(.easeInOut, value: currentStep)
        }
        .padding(.horizontal, AppSpacing.lg)
        .background(Color.Background)
        .safeAreaInset(edge: .bottom) {
            CTAButton(
                title: currentStep == totalSteps - 1
                    ? "review".localized
                    : "common.next".localized
            ) {
                if canProceedFromStep(currentStep) {
                    if currentStep == totalSteps - 1 {
                        showSummary = true
                    } else {
                        currentStep += 1
                    }
                } else {
                    vm.showErrors = true
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.lg)
            .padding(.bottom, AppSpacing.sm)
            .background(Color.Background)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
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
            DestinationPickerViewA(
                destination: $vm.destination,
                lat: $vm.destinationLat,
                lng: $vm.destinationLng
            )
        }
        .sheet(isPresented: $vm.showEmergencyContactPicker) {
            ContactPickerSheetA {
                vm.importEmergencyContact($0)
            }
        }
        .sheet(isPresented: $vm.showGroupContactPicker) {
            ContactPickerSheetB { contacts in
                contacts.forEach { vm.importGroupContact($0) }
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
            if vm.fullNameIsValid && vm.phoneNumberIsValid && vm.emergencyContactsIsValid {
                return true
            } else {
                vm.showStep0Errors = true
                return false
            }

        case 1:
            vm.updatePlateInfoFromTemplate()
            if vm.carModelIsValid && vm.selectedColorIsValid && vm.plateLettersIsValid && vm.plateNumbersIsValid {
                return true
            } else {
                vm.showStep1Errors = true
                return false
            }

        case 2:
            if vm.destinationIsValid && vm.returnTimeIsValid && vm.tripNameIsValid {
                return true
            } else {
                vm.showStep2Errors = true
                return false
            }

        default:
            return true
        }
    }
}

#Preview {
    NavigationStack {
        CreateTripView(showParentSheet: .constant(true))
    }
    .modelContainer(for: [
        SavedInfo.self,
        SavedContact.self,
        Trip.self
    ], inMemory: true)
}
