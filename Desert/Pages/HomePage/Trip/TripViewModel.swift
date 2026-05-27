//
//  TripsViewModel.swift
//  Desert
//

import SwiftUI
import SwiftData
import CoreLocation
import Contacts
import Combine

class TripsViewModel: ObservableObject {

    // MARK: - Form Fields

    @Published var tripName: String = {
        let f = DateFormatter()
        f.dateFormat = "d MMM"
        return f.string(from: Date()) + " Trip"
    }()

    @Published var destination: String = ""
    @Published var destinationLat: Double = 0
    @Published var destinationLng: Double = 0

    @Published var returnTime: Date = Date() 
    
    @Published var isGroup: Bool = false
    @Published var groupCount: Int = 1

    @Published var fullName: String = ""
    @Published var phoneNumber: String = ""

    @Published var emergencyContacts: [Contact] = []
    @Published var groupContacts: [Contact] = []

    @Published var carModel: String = ""
    @Published var selectedColor: String = ""
    @Published var isFourWheelDrive: Bool = false

    @Published var firstPlateLetter: String = ""
    @Published var secondPlateLetter: String = ""
    @Published var thirdPlateLetter: String = ""

    @Published var plateDigits: [String] = ["", "", "", ""]

    @Published var plateLetters: String = ""
    @Published var plateNumbers: String = ""

    // MARK: - UI State

    @Published var showEmergencyContactPicker = false
    @Published var showGroupContactPicker = false
    @Published var showDestinationPicker = false
    @Published var showLocationAlert = false
    @Published var locationAlertTitle = ""
    @Published var locationAlertMessage = ""
    @Published var showErrors = false
    @Published var showStep0Errors = false
    @Published var showStep1Errors = false
    @Published var showStep2Errors = false
    @Published var showContactError = false
    @Published var contactErrorMessage = ""

    // MARK: - Validation

    var destinationIsValid: Bool { !destination.isEmpty }
    var fullNameIsValid: Bool { !fullName.isEmpty }
    var phoneNumberIsValid: Bool {
        let digits = phoneNumber.filter { $0.isNumber }
        return digits.hasPrefix("9665") && digits.count == 12
    }
    var returnTimeIsValid: Bool { returnTime > Date() }
    var emergencyContactsIsValid: Bool { !emergencyContacts.isEmpty }
    var carModelIsValid: Bool { !carModel.isEmpty }
    var selectedColorIsValid: Bool {
        !selectedColor.isEmpty && selectedColor != "vehicle.color.placeholder"
    }
    var plateLettersIsValid: Bool { plateLetters.count == 3 }
    var tripNameIsValid: Bool { !tripName.isEmpty }
    var plateNumbersIsValid: Bool {
        let digits = plateNumbers.filter { $0.isNumber }
        return digits.count >= 1 && digits.count <= 4
    }

    var plateNumbersDisplay: String {
        let digits = plateNumbers.filter { $0.isNumber }
        return digits + String(repeating: "-", count: max(0, 4 - digits.count))
    }

    func updatePlateInfoFromTemplate() {
        plateLetters = firstPlateLetter + secondPlateLetter + thirdPlateLetter
        plateNumbers = plateDigits.joined()
    }
    
    func loadPlateInfoToTemplate() {
        let letters = Array(plateLetters)

        if letters.count == 3 {
            firstPlateLetter = String(letters[0])
            secondPlateLetter = String(letters[1])
            thirdPlateLetter = String(letters[2])
        }

        let numbers = Array(plateNumbers)

        plateDigits = (0..<4).map { index in
            index < numbers.count ? String(numbers[index]) : ""
        }
    }
    
   
    var formIsValid: Bool {
        destinationIsValid &&
        fullNameIsValid &&
        phoneNumberIsValid &&
        returnTimeIsValid &&
        emergencyContactsIsValid &&
        carModelIsValid &&
        selectedColorIsValid &&
        plateLettersIsValid &&
        plateNumbersIsValid
    }
    
    func formatUserPhoneInput(_ value: String) {

        let digits = value.filter { $0.isNumber }

        var localNumber = digits

        if localNumber.hasPrefix("966") {
            localNumber = String(localNumber.dropFirst(3))
        }

        if localNumber.hasPrefix("0") {
            localNumber = String(localNumber.dropFirst())
        }

        localNumber = String(localNumber.prefix(9))

        if localNumber.isEmpty {
            phoneNumber = ""
        } else {
            phoneNumber = "+966 " + localNumber
        }
    }
}

// MARK: - Load Data

extension TripsViewModel {

    func loadSavedInfo(_ savedInfo: SavedInfo?) {
        guard let saved = savedInfo else { return }

        fullName = saved.userName
        phoneNumber = saved.phoneNumber
        carModel = saved.carName
        selectedColor = saved.carColor
        isFourWheelDrive = saved.is4WD
        plateLetters = saved.plateLetters
        plateNumbers = saved.plateNumbers

        emergencyContacts = saved.defaultEmergencyContacts.map {
            Contact(name: $0.name, phone: $0.phone)
        }

        groupContacts = saved.defaultGroupContacts.map {
            Contact(name: $0.name, phone: $0.phone)
        }

        loadPlateInfoToTemplate()
    }

    func loadTripData(from trip: Trip) {
        tripName = trip.tripName
        destination = trip.destination
        destinationLat = trip.destinationLat
        destinationLng = trip.destinationLng
        isGroup = trip.hasGroup
        groupCount = trip.groupSize
        fullName = trip.userName
        phoneNumber = trip.phoneNumber
        carModel = trip.carName
        selectedColor = trip.carColor
        isFourWheelDrive = trip.is4WD
        plateLetters = trip.plateLetters
        plateNumbers = trip.plateNumbers

        emergencyContacts = trip.emergencyContacts.map {
            Contact(name: $0.name, phone: $0.phone)
        }

        groupContacts = trip.groupContacts.map {
            Contact(name: $0.name, phone: $0.phone)
        }

        returnTime = trip.returnTime
        loadPlateInfoToTemplate()
    }
}

// MARK: - Contacts

extension TripsViewModel {

    func importEmergencyContact(_ contact: CNContact) {

        guard emergencyContacts.count < 3 else {
            contactErrorMessage = "max_contacts_reached".localized
            showContactError = true
            return
        }

        let rawPhone = contact.phoneNumbers.first?.value.stringValue ?? ""

        guard let formattedPhone = formatSaudiPhone(rawPhone) else {
            contactErrorMessage = "contact_phone_invalid".localized
            showContactError = true
            return
        }

        let name = "\(contact.givenName) \(contact.familyName)"
            .trimmingCharacters(in: .whitespaces)

        let alreadyExists = emergencyContacts.contains {
            $0.phone == formattedPhone
        }

        guard !alreadyExists else {
            contactErrorMessage = "contact_already_added".localized
            showContactError = true
            return
        }

        showContactError = false
        emergencyContacts.append(Contact(name: name, phone: formattedPhone))
    }

    func importGroupContact(_ contact: CNContact) {

        guard let email = contact.emailAddresses.first?.value as String?,
              !email.isEmpty else {

            contactErrorMessage = "contact_phone_invalid".localized
            showContactError = true
            return
        }

        let name = "\(contact.givenName) \(contact.familyName)"
            .trimmingCharacters(in: .whitespaces)

        let alreadyExists = groupContacts.contains {
            $0.phone.lowercased() == email.lowercased()
        }

        guard !alreadyExists else {
            contactErrorMessage = "contact_already_added".localized
            showContactError = true
            return
        }

        showContactError = false

        groupContacts.append(Contact(
            name: name,
            phone: email
        ))
    }

    private func formatSaudiPhone(_ rawPhone: String?) -> String? {
        guard let rawPhone, !rawPhone.isEmpty else { return nil }

        let digits = rawPhone.filter { $0.isNumber }

        if digits.hasPrefix("966"), digits.count == 12 {
            return "+\(digits)"
        }

        if digits.hasPrefix("05"), digits.count == 10 {
            return "+966\(digits.dropFirst())"
        }

        if digits.hasPrefix("5"), digits.count == 9 {
            return "+966\(digits)"
        }

        return nil
    }
}

// MARK: - Start Trip

extension TripsViewModel {

    @discardableResult
    func startTrip(context: ModelContext) -> Bool {

        let status = CLLocationManager.authorizationStatus()

        switch status {

        case .notDetermined, .denied, .restricted:
            locationAlertTitle = "location_permission_required".localized
            locationAlertMessage = "Please enable location access in Settings to start a trip."
            showLocationAlert = true
            return false

        case .authorizedWhenInUse:
            locationAlertTitle = "location_permission_required".localized
            locationAlertMessage = "Please enable Always Allow location permission in Settings to start a trip."
            showLocationAlert = true
            return false

        case .authorizedAlways:
            break

        @unknown default:
            locationAlertTitle = "location_permission_required".localized
            locationAlertMessage = "Please enable location access in Settings to start a trip."
            showLocationAlert = true
            return false
        }

        
        updatePlateInfoFromTemplate()

        guard formIsValid else {
            showErrors = true
            return false
        }

        let trip = Trip(
            tripId: "",
            tripName: tripName.isEmpty ? defaultTripName() : tripName,
            userName: fullName,
            phoneNumber: phoneNumber,
            destination: destination,
            destinationLat: destinationLat,
            destinationLng: destinationLng,
            returnTime: returnTime,
            hasGroup: isGroup,
            groupSize: groupCount,
            carName: carModel,
            carColor: selectedColor,
            is4WD: isFourWheelDrive,
            plateLetters: plateLetters,
            plateNumbers: plateNumbers
        )

        trip.emergencyContacts = emergencyContacts
        trip.groupContacts = groupContacts

        saveUserInfo(context: context)
        TripSessionManager.shared.startTrip(trip: trip, context: context)

        return true
    }

    func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private func defaultTripName() -> String {
        let f = DateFormatter()
        f.dateFormat = "d MMM"
        return f.string(from: Date())
    }

    private func saveUserInfo(context: ModelContext) {
        let descriptor = FetchDescriptor<SavedInfo>()

        if let existing = (try? context.fetch(descriptor))?.first {
            existing.userName = fullName
            existing.phoneNumber = phoneNumber
            existing.carName = carModel
            existing.carColor = selectedColor
            existing.is4WD = isFourWheelDrive
            existing.plateLetters = plateLetters
            existing.plateNumbers = plateNumbers

            existing.defaultEmergencyContacts = emergencyContacts.map {
                SavedContact(name: $0.name, phone: $0.phone, contactType: "emergency")
            }

            existing.defaultGroupContacts = groupContacts.map {
                SavedContact(name: $0.name, phone: $0.phone, contactType: "group")
            }

        } else {
            let saved = SavedInfo(
                userName: fullName,
                phoneNumber: phoneNumber,
                carName: carModel,
                carColor: selectedColor,
                is4WD: isFourWheelDrive,
                plateLetters: plateLetters,
                plateNumbers: plateNumbers
            )

            saved.defaultEmergencyContacts = emergencyContacts.map {
                SavedContact(name: $0.name, phone: $0.phone, contactType: "emergency")
            }

            saved.defaultGroupContacts = groupContacts.map {
                SavedContact(name: $0.name, phone: $0.phone, contactType: "group")
            }

            context.insert(saved)
        }
    }
}
