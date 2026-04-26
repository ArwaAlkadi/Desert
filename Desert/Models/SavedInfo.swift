//
//  SavedInfo.swift
//  Desert
//
//  Created by Arwa Alkadi on 21/04/2026.
//

import SwiftData
import Foundation

// SavedInfo — stores user's default data
// filled automatically from the first trip
// updated when user enables "Save my info"
@Model
class SavedInfo {
    
    // user
    var userName: String
    var phoneNumber: String
    
    // car
    var carName: String
    var carColor: String
    var is4WD: Bool
    var plateLetters: String
    var plateNumbers: String
    
    // default contacts
    var defaultGroupContacts: [SavedContact]        // group members
    var defaultEmergencyContacts: [SavedContact]    // emergency contacts
    
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
        self.defaultGroupContacts = []
        self.defaultEmergencyContacts = []
    }
}

// SavedContact — default contact
// lives inside SavedInfo
// auto-filled in every new trip
@Model
class SavedContact {
    var name: String
    var phone: String
    var contactType: String
    
    init(name: String, phone: String, contactType: String) {
        self.name = name
        self.phone = phone
        self.contactType = contactType
    }
}
