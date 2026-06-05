//
//  CreateTripViewModel.swift
//  Desert
//

import SwiftUI
import SwiftData
import CoreLocation
import Contacts
import Combine
import MapKit

class CreateTripViewModel: ObservableObject {

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

    @Published var emergencyContactErrorMessage = ""
    @Published var groupContactErrorMessage = ""

    // MARK: - Load Guard

    /// Prevents re-loading saved info on every `onAppear` (e.g. back navigation).
    private(set) var hasLoadedInitialData: Bool = false

    // MARK: - Destination Picker State

    @Published var destinationSearchText: String = ""
    @Published var destinationSearchResults: [MKMapItem] = []
    @Published var pinCoordinate: CLLocationCoordinate2D? = nil
    @Published var pinName: String = ""
    @Published var destinationRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 24.7136, longitude: 46.6753),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    // MARK: - Validation

    var destinationIsValid: Bool { !destination.isEmpty }
    var fullNameIsValid: Bool { !fullName.isEmpty }

    var phoneNumberIsValid: Bool {
        let digits = phoneNumber.filter(\.isNumber)

        let local: String

        if digits.hasPrefix("966") {
            local = String(digits.dropFirst(3))
        } else if digits.hasPrefix("0") {
            local = String(digits.dropFirst())
        } else {
            local = digits
        }

        return local.hasPrefix("5") && local.count == 9
    }

    var displayCarColor: String {
        selectedColor.localized
    }
    
    var phoneError: PhoneError {
        phoneNumber.isEmpty ? .required : .invalid
    }

    var formattedSearchResults: [(item: MKMapItem, subtitle: String?)] {
        let userLoc: CLLocation? = {
            guard let coord = LocationManager.shared.currentUserLocation else { return nil }
            return CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        }()

        return destinationSearchResults.map { item in
            var parts: [String] = []
            if let city = item.placemark.locality { parts.append(city) }
            if let userLoc {
                let itemLoc = CLLocation(
                    latitude: item.placemark.coordinate.latitude,
                    longitude: item.placemark.coordinate.longitude
                )
                let km = Int(userLoc.distance(from: itemLoc) / 1000)
                if km > 0 { parts.append("\(km) km") }
            }
            return (item: item, subtitle: parts.isEmpty ? nil : parts.joined(separator: ", "))
        }
    }

    var returnTimeIsValid: Bool {
        returnTime >= Date().addingTimeInterval(60 * 60)
    }
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

    var hasUserEnteredData: Bool {
        !fullName.isEmpty ||
        !phoneNumber.isEmpty ||
        !emergencyContacts.isEmpty ||
        !carModel.isEmpty ||
        !selectedColor.isEmpty ||
        isFourWheelDrive ||
        !firstPlateLetter.isEmpty ||
        !secondPlateLetter.isEmpty ||
        !thirdPlateLetter.isEmpty ||
        plateDigits.contains { !$0.isEmpty } ||
        !destination.isEmpty ||
        isGroup ||
        !groupContacts.isEmpty
    }

    var plateNumbersDisplay: String {
        let digits = plateNumbers.filter { $0.isNumber }
        return digits + String(repeating: "-", count: max(0, 4 - digits.count))
    }

    func canProceedFromStep(_ step: Int) -> Bool {
        switch step {

        case 0:
            if fullNameIsValid && phoneNumberIsValid && emergencyContactsIsValid {
                return true
            } else {
                showStep0Errors = true
                return false
            }

        case 1:
            updatePlateInfoFromTemplate()

            if carModelIsValid &&
                selectedColorIsValid &&
                plateLettersIsValid &&
                plateNumbersIsValid {
                return true
            } else {
                showStep1Errors = true
                return false
            }

        case 2:
            if destinationIsValid &&
                returnTimeIsValid &&
                tripNameIsValid {
                return true
            } else {
                showStep2Errors = true
                return false
            }

        default:
            return true
        }
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
    
    var localPhoneBinding: Binding<String> {
        Binding(
            get: {
                let digits = self.phoneNumber.filter(\.isNumber)
                if digits.hasPrefix("966") {
                    return String(digits.dropFirst(3).prefix(9))
                }
                if digits.hasPrefix("0") {
                    return String(digits.dropFirst().prefix(9))
                }
                return String(digits.prefix(9))
            },
            set: { newValue in
                self.formatUserPhoneInput(newValue)
            }
        )
    }

    func formatUserPhoneInput(_ value: String) {
        let digits = value.filter { $0.isNumber }
        var local = digits

        if local.hasPrefix("966") {
            local = String(local.dropFirst(3))
        }
        if local.hasPrefix("0") {
            local = String(local.dropFirst())
        }
        local = String(local.prefix(9))
        phoneNumber = local.isEmpty ? "" : "+966\(local)"
    }
}

// MARK: - Load Data

extension CreateTripViewModel {

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

        loadPlateInfoToTemplate()
        hasLoadedInitialData = true
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

extension CreateTripViewModel {

    func importEmergencyContact(_ contact: CNContact) {

        guard emergencyContacts.count < 3 else {
            showTemporaryEmergencyError("max_contacts_reached".localized)
            return
        }

        let rawPhone = contact.phoneNumbers.first?.value.stringValue ?? ""

        guard let formattedPhone = formatSaudiPhone(rawPhone) else {
            showTemporaryEmergencyError("contact_phone_invalid".localized)
            return
        }

        let name = "\(contact.givenName) \(contact.familyName)"
            .trimmingCharacters(in: .whitespaces)

        let alreadyExists = emergencyContacts.contains {
            $0.phone == formattedPhone
        }

        guard !alreadyExists else {
            showTemporaryEmergencyError("contact_already_added".localized)
            return
        }

        emergencyContactErrorMessage = ""

        emergencyContacts.append(
            Contact(name: name, phone: formattedPhone)
        )
    }

    func importGroupContact(_ contact: CNContact) {

        let rawPhone = contact.phoneNumbers.first?.value.stringValue ?? ""

        guard let formattedPhone = formatSaudiPhone(rawPhone) else {
            showTemporaryGroupError("contact_phone_invalid".localized)
            return
        }

        let name = "\(contact.givenName) \(contact.familyName)"
            .trimmingCharacters(in: .whitespaces)

        let alreadyExists = groupContacts.contains {
            $0.phone == formattedPhone
        }

        guard !alreadyExists else {
            showTemporaryGroupError("contact_already_added".localized)
            return
        }

        groupContactErrorMessage = ""

        groupContacts.append(
            Contact(name: name, phone: formattedPhone)
        )
    }

    private func showTemporaryEmergencyError(_ message: String) {
        emergencyContactErrorMessage = message

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            guard self?.emergencyContactErrorMessage == message else { return }
            self?.emergencyContactErrorMessage = ""
        }
    }

    private func showTemporaryGroupError(_ message: String) {
        groupContactErrorMessage = message

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            guard self?.groupContactErrorMessage == message else { return }
            self?.groupContactErrorMessage = ""
        }
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

extension CreateTripViewModel {

    @discardableResult
    func startTrip(
        context: ModelContext,
        completion: @escaping () -> Void = {}
    ) -> Bool {

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
            carColor: displayCarColor,
            is4WD: isFourWheelDrive,
            plateLetters: plateLetters,
            plateNumbers: plateNumbers
        )

        trip.emergencyContacts = emergencyContacts
        trip.groupContacts = groupContacts

        saveUserInfo(context: context)

        TripSessionManager.shared.startTrip(
            trip: trip,
            context: context,
            completion: completion
        )

        return true
    }
    
    func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    func loadTripForRepeat(_ trip: Trip) {
        loadTripData(from: trip)
        returnTime = Date()
        hasLoadedInitialData = true
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
            existing.carColor = displayCarColor
            existing.is4WD = isFourWheelDrive
            existing.plateLetters = plateLetters
            existing.plateNumbers = plateNumbers

            existing.defaultEmergencyContacts = emergencyContacts.map {
                SavedContact(name: $0.name, phone: $0.phone, contactType: "emergency")
            }

          

        } else {
            let saved = SavedInfo(
                userName: fullName,
                phoneNumber: phoneNumber,
                carName: carModel,
                carColor: displayCarColor,
                is4WD: isFourWheelDrive,
                plateLetters: plateLetters,
                plateNumbers: plateNumbers
            )

            saved.defaultEmergencyContacts = emergencyContacts.map {
                SavedContact(name: $0.name, phone: $0.phone, contactType: "emergency")
            }

           
            context.insert(saved)
        }
    }
}


// MARK: - Destination Picker

extension CreateTripViewModel {

    func searchDestination() {
        guard !destinationSearchText.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = destinationSearchText
        request.region = destinationRegion
        MKLocalSearch(request: request).start { [weak self] response, _ in
            self?.destinationSearchResults = response?.mapItems ?? []
        }
    }

    func selectDestination(_ item: MKMapItem) {
        pinCoordinate = item.placemark.coordinate
        pinName = item.name ?? destinationSearchText
        destinationRegion.center = item.placemark.coordinate
        destinationSearchResults = []
        destinationSearchText = item.name ?? ""
    }

    func reverseGeocode(_ coordinate: CLLocationCoordinate2D) {
        CLGeocoder().reverseGeocodeLocation(
            CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        ) { [weak self] placemarks, _ in
            guard let self else { return }
            self.pinName = placemarks?.first?.name ?? self.coordinateText()
        }
    }

    func confirmDestination() {
        guard let coord = pinCoordinate else { return }
        destination = pinName.isEmpty ? coordinateText() : pinName
        destinationLat = coord.latitude
        destinationLng = coord.longitude
    }

    private func coordinateText() -> String {
        guard let pin = pinCoordinate else { return "" }
        return String(format: "%.4f, %.4f", pin.latitude, pin.longitude)
    }
}
