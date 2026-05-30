//
//  TripSummaryView.swift
//  Desert
//

import SwiftUI
import SwiftData

struct TripSummaryView: View {

    @ObservedObject var vm: CreateTripViewModel
    var onTripStarted: () -> Void

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @StateObject private var networkMonitor = NetworkMonitorHelper()
    @State private var isLoading = false

    var isConnected: Bool {
        networkMonitor.isConnected
    }

    var body: some View {
        SummaryTemplate(
            tripName: vm.tripName,
            startTime: Date(),
            returnTime: vm.returnTime,
            destination: vm.destination,
            carDetails: vm.carModel.isEmpty ? "—" : "\(vm.selectedColor.localized) \(vm.carModel)",
            plateNumber: vm.plateLetters.isEmpty ? "—" : "\(vm.plateNumbers) | \(vm.plateLetters)",
            isGroup: vm.isGroup,
            groupCount: vm.groupCount,
            emergencyContacts: vm.emergencyContacts,
            groupContacts: vm.groupContacts,
            isConnected: isConnected,
            onBack: {
                dismiss()
            },
            onStartTrip: {
                guard !TripSessionManager.shared.hasActiveTrip else {
                    isLoading = false
                    return
                }
                _ = vm.startTrip(context: context) {
                    onTripStarted()
                }
            },
            isLoading: $isLoading
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .alert(vm.locationAlertTitle, isPresented: $vm.showLocationAlert) {
            Button("open_settings".localized) {
                vm.openAppSettings()
            }
            Button("cancel".localized, role: .cancel) { }
        } message: {
            Text(vm.locationAlertMessage)
        }
        .onChange(of: vm.showLocationAlert) { _, isShowing in
            if isShowing { isLoading = false }
        }
        .onAppear {
            networkMonitor.startMonitoring()
        }
        .onDisappear {
            networkMonitor.stopMonitoring()
        }
    }
}


#Preview {
    let vm = CreateTripViewModel()
    vm.tripName = "Desert Trip"
    vm.destination = "Al Thumamah"
    vm.returnTime = Date().addingTimeInterval(3600 * 8)
    vm.fullName = "Samar"
    vm.phoneNumber = "+966501234567"
    vm.carModel = "Toyota"
    vm.selectedColor = "White"
    vm.plateLetters = "ABC"
    vm.plateNumbers = "1234"
    vm.emergencyContacts = [
        Contact(name: "Ahmed", phone: "+966501234567")
    ]

    return NavigationStack {
        TripSummaryView(
            vm: vm,
            onTripStarted: {}
        )
    }
    .modelContainer(for: [
        Trip.self,
        SavedInfo.self,
        SavedContact.self,
        LocationPoint.self,
        AppSettings.self
    ], inMemory: true)
}
