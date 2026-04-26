//
//  AppSettings.swift
//  Desert
//
//  Created by Arwa Alkadi on 21/04/2026.
//

import SwiftData
import Foundation


@Model
class AppSettings {
    
    var isFirstLaunch: Bool
    var hasActiveTrip: Bool
    
    // the ID of the current active trip
    // matches the trip ID in Firebase
    var currentTripId: String
    
    // last time a location was uploaded to the server
    // used to decide when to upload next
    var lastUploadDate: Date?
    
    init() {
        self.isFirstLaunch = true
        self.hasActiveTrip = false
        self.currentTripId = ""
        self.lastUploadDate = nil
    }
}
