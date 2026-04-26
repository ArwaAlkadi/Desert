//
//  Trip.swift
//  Desert
//
//  Created by Arwa Alkadi on 21/04/2026.
//

import Foundation
import SwiftData

@Model
class Trip {
    
    // identity
    var id: String
    var tripName: String
    
    // user info
    var userName: String
    var phoneNumber: String
    
    // destination
    var destination: String
    var destinationLat: Double
    var destinationLng: Double
    
    // time
    var startTime: Date
    var returnTime: Date
    
    // group
    var hasGroup: Bool
    var groupSize: Int
    
    // car
    var carName: String
    var carColor: String
    var is4WD: Bool
    var plateLetters: String
    var plateNumbers: String
    
    // last known location — sent to contacts if overdue
    var lastKnownLat: Double
    var lastKnownLng: Double
    var lastUploadTime: Date?
    
    // status
    // "active"    → trip is running
    // "completed" → user tapped "I'm back safely"
    var status: String
    
    // contacts
    var groupContacts: [Contact]        // people travelling with user
    var emergencyContacts: [Contact]    // family — receive SMS if overdue
    
    // local GPS track — drawn on map only
    var locations: [LocationPoint]
    
    init(
        id: String,
        tripName: String,
        userName: String,
        phoneNumber: String,
        destination: String,
        destinationLat: Double,
        destinationLng: Double,
        returnTime: Date,
        hasGroup: Bool,
        groupSize: Int,
        carName: String,
        carColor: String,
        is4WD: Bool,
        plateLetters: String,
        plateNumbers: String
    ) {
        self.id = id
        self.tripName = tripName
        self.userName = userName
        self.phoneNumber = phoneNumber
        self.destination = destination
        self.destinationLat = destinationLat
        self.destinationLng = destinationLng
        self.startTime = Date()
        self.returnTime = returnTime
        self.hasGroup = hasGroup
        self.groupSize = groupSize
        self.carName = carName
        self.carColor = carColor
        self.is4WD = is4WD
        self.plateLetters = plateLetters
        self.plateNumbers = plateNumbers
        self.lastKnownLat = 0
        self.lastKnownLng = 0
        self.lastUploadTime = nil
        self.status = "active"
        self.groupContacts = []
        self.emergencyContacts = []
        self.locations = []
    }
    
    var isActive: Bool { status == "active" }
    var isCompleted: Bool { status == "completed" }
}

// Contact — used for both group and emergency
// groupContacts    → people travelling with user
// emergencyContacts → family — receive SMS if overdue
@Model
class Contact {
    var name: String
    var phone: String
    
    init(name: String, phone: String) {
        self.name = name
        self.phone = phone
    }
}

// LocationPoint — local GPS track only
// drawn on map — NOT uploaded to server
@Model
class LocationPoint {
    var index: Int
    var lat: Double
    var lng: Double
    var timestamp: Date
    
    init(index: Int, lat: Double, lng: Double) {
        self.index = index
        self.lat = lat
        self.lng = lng
        self.timestamp = Date()
    }
}
