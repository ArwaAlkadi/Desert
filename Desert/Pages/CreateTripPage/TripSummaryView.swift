//
//  TripSummaryView.swift
//  Desert
//

import SwiftUI
import SwiftData

struct TripSummaryView: View {

    @ObservedObject var vm: CreateTripViewModel
    
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.onTripStarted) private var goToMap
    
    @StateObject private var networkMonitor = NetworkMonitorHelper()
    @State private var isLoading = false
    @State private var showTerms = false

    var onTripStarted: () -> Void
    var onReturnTimeInvalid: () -> Void = {}
    
    var isConnected: Bool {
        networkMonitor.isConnected
    }

    var body: some View {
        
        ZStack(alignment: .top) {
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

                let didStart = vm.startTrip(context: context) {
                    onTripStarted()
                    goToMap()
                }

                if !didStart {
                    isLoading = false

                    if !vm.returnTimeIsValid {
                        onReturnTimeInvalid()
                    }
                }
            },
            onTermsTapped: {
                showTerms = true
            },
            isLoading: $isLoading
        )
        .sheet(isPresented: $showTerms) {
            SafariView(url: URL(string: "https://your-terms-url.com")!)
        }
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
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            
            if isLoading {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                
                ProgressView()
                    .scaleEffect(1.3)
            }
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
