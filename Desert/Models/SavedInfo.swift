//
//  SavedInfo.swift
//  Desert
//

import SwiftData
import Foundation

/// Stores the user's default trip data for auto-filling future trips.
///
/// ## Responsibilities
/// 1. Holding personal and vehicle details entered during previous trips
/// 2. Storing default emergency contacts that are pre-filled on new trips
///
/// Updated at the end of each trip start via `CreateTripViewModel.saveUserInfo`.
@Model
class SavedInfo {

    // MARK: - Stored

    var userName: String
    var phoneNumber: String
    var carName: String
    var carColor: String
    var is4WD: Bool
    var plateLetters: String
    var plateNumbers: String

    /// Pre-filled emergency contacts — copied into new trips as `Contact` objects.
    var defaultEmergencyContacts: [SavedContact]

    // MARK: - Init

    init(
        userName: String,
        phoneNumber: String,
        carName: String,
        carColor: String,
        is4WD: Bool,
        plateLetters: String,
        plateNumbers: String
    ) {
        self.userName = userName
        self.phoneNumber = phoneNumber
        self.carName = carName
        self.carColor = carColor
        self.is4WD = is4WD
        self.plateLetters = plateLetters
        self.plateNumbers = plateNumbers
        self.defaultEmergencyContacts = []
    }
}


// MARK: - SavedContact

/// A persisted contact inside `SavedInfo` — converted to `Contact` when a new trip starts.
@Model
class SavedContact {

    // MARK: - Stored

    var name: String
    var phone: String

    // MARK: - Init

    init(name: String, phone: String) {
        self.name = name
        self.phone = phone
    }
}
