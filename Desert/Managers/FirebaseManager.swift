//
//  FirebaseManager.swift
//  Desert
//
//  Created by Arwa Alkadi on 06/05/2026.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

/// Single point of contact between the app and Firebase Firestore.
///
/// ## Summary
/// - All database writes go through this file only
/// - No other file in the app writes to Firebase directly
/// - Uses `FieldValue.increment` for atomic trip ID generation — safe for concurrent users
/// - Uses Anonymous Auth — no sign-in required, UID persists on device
/// - Trip ID format: `trip_001_8f3k9mp2` — sequential + random for security
///
/// ## Responsibilities
/// 1. Signing in anonymously to get a persistent user ID
/// 2. Generating a unique secure trip ID using an atomic Firebase counter
/// 3. Saving full trip data to Firestore when a trip starts
/// 4. Updating the last known location every 2km or 1 hour
/// 5. Marking a trip as completed when it ends
/// 6. Listening to trip status changes from Cloud Functions
///
/// ## Usage
/// ```swift
///     // 0. Sign in anonymously — call once on app launch
///     FirebaseManager.shared.signInAnonymously()
///
///     // 1. Generate a trip ID before saving anything
///     FirebaseManager.shared.createTripId { tripId in
///
///     // 2. Save full trip data on start
///     FirebaseManager.shared.saveTrip(trip, tripId: tripId)
///
///     // 3. Update location during the trip
///     FirebaseManager.shared.updateLocation(tripId: tripId, lat: lat, lng: lng, direction: nil)
///
///     // 4. Mark trip as completed on end
///     FirebaseManager.shared.endTrip(tripId: tripId)
/// }
/// ```
///
/// - Important: Always call ``signInAnonymously()`` first on app launch,
///   then call ``createTripId(completion:)`` before saving any trip data.
class FirebaseManager {
    
    /// Shared singleton — use this throughout the app.
    static let shared = FirebaseManager()
    
    /// The Firestore database instance.
    private let db = Firestore.firestore()
    
    /// The current anonymous user ID — persists on device across sessions.
    /// `nil` until ``signInAnonymously()`` completes.
    private(set) var userId: String? {
        get { UserDefaults.standard.string(forKey: UserDefaultsKeys.anonymousUserId) }
        set { UserDefaults.standard.set(newValue, forKey: UserDefaultsKeys.anonymousUserId) }
    }
    
    // MARK: - Remote Config Models

    struct AppUpdateConfig {
        let minimumVersion: String
        let message: String
        let appStoreURL: String
    }

    struct MaintenanceConfig {
        let isEnabled: Bool
        let title: String
        let message: String
    }

    // MARK: - Version Compare

    static func isOlderVersion(current: String, required: String) -> Bool {
        current.compare(required, options: .numeric) == .orderedAscending
    }
    
    // MARK: - Anonymous Auth
    /// Signs in anonymously using Firebase Auth.
    ///
    /// Creates a persistent anonymous UID tied to this device.
    /// The UID survives app restarts and updates — only cleared on device reset.
    ///
    /// Safe to call multiple times — if already signed in, returns the existing user.
    ///
    /// - Note: Call this once in `AppDelegate.application(_:didFinishLaunchingWithOptions:)`
    func signInAnonymously() {
        if let current = Auth.auth().currentUser {
            userId = current.uid
            print("Already signed in: \(current.uid)")
            return
        }
        
        Auth.auth().signInAnonymously { [weak self] result, error in
            guard let self else { return }
            if let error {
                print("Anonymous sign-in failed: \(error.localizedDescription)")
                return
            }
            self.userId = result?.user.uid
            print("Anonymous sign-in success: \(self.userId ?? "")")
        }
    }
    
    // MARK: - Trip Counter
    /// Generates a unique secure trip ID using an atomic Firestore counter.
    ///
    /// Format: `trip_001_8f3k9mp2`
    /// - `001` — sequential number from Firebase counter (sortable in console)
    /// - `8f3k9mp2` — 8-char random UUID fragment (prevents guessing)
    ///
    /// Uses `FieldValue.increment` to avoid race conditions when multiple
    /// users create trips simultaneously.
    ///
    /// - Parameter completion: Called with the generated trip ID on success.
    ///
    /// - Note: If the Firestore write fails, the completion is not called.
    func createTripId(completion: @escaping (String) -> Void) {
        let counterRef = db.collection("meta").document("tripCounter")
        
        counterRef.setData(
            ["total": FieldValue.increment(Int64(1))],
            merge: true
        ) { error in
            guard error == nil else {
                print("failed to create trip ID")
                return
            }
            
            counterRef.getDocument { doc, _ in
                let total = doc?.data()?["total"] as? Int ?? 1
                
                let sequential = String(format: "%03d", total)
                let random = UUID().uuidString
                    .replacingOccurrences(of: "-", with: "")
                    .prefix(8)
                    .lowercased()
                
                let tripId = "trip_\(sequential)_\(random)"
                
                print("trip ID created: \(tripId)")
                completion(tripId)
            }
        }
    }
    
    // MARK: - Save Trip
    /// Saves the full trip data to Firestore when a trip starts.
    ///
    /// Writes a new document to `trips/{tripId}`.
    /// Fields are prefixed with letters (`a-`, `b-`, etc.) to control
    /// display order in the Firebase console.
    ///
    /// `04-lastKnownLocation` is initialized with empty values here —
    /// it is updated later by ``updateLocation(tripId:lat:lng:direction:onSuccess:onFailure:)``
    /// when the first GPS update arrives after the trip starts.
    ///
    /// - Parameters:
    ///   - trip: The `Trip` model containing all trip details.
    ///   - tripId: The ID generated by ``createTripId(completion:)``.
    func saveTrip(_ trip: Trip, tripId: String) {
        db.collection("trips").document(tripId).setData([

            "01-userId": userId ?? "unknown",

            "02-status": [
                "a-status": trip.status,
                "b-startedAt": trip.startTime.timeIntervalSince1970,
                "c-startedAtReadable": formatDate(trip.startTime),
                "d-endedAt": 0,
                "e-endedAtReadable": "",
                "f-alertSent": false,
                "g-alertSentAt": 0,
                "h-alertSentAtReadable": "",
                "i-alertReason": "",
                "j-pendingAlertAt": 0,
                "k-updatedAlertCount": 0,
            ],

            "03-userInfo": [
                "a-userName": trip.userName,
                "b-phoneNumber": trip.phoneNumber,
            ],

            "04-lastKnownLocation": [
                "a-lat": 0,
                "b-lng": 0,
                "c-direction": "",
                "d-lastUploadTime": 0,
                "e-lastUploadTimeReadable": "",
                "f-deviceBatteryLevel": -1,
            ],

            "05-emergencyContacts": trip.emergencyContacts.map {[
                "a-name": $0.name,
                "b-phone": $0.phone
            ]},

            "06-tripInfo": [
                "a-tripId": tripId,
                "b-startTime": trip.startTime.timeIntervalSince1970,
                "c-startTimeReadable": formatDate(trip.startTime),
                "d-returnTime": trip.returnTime.timeIntervalSince1970,
                "e-returnTimeReadable": formatDate(trip.returnTime),
                "f-destination": trip.destination,
                "g-destinationCoordinates": [
                    "lat": trip.destinationLat,
                    "lng": trip.destinationLng
                ],
                "h-hasGroup": trip.hasGroup,
                "i-groupSize": trip.groupSize,
                "j-groupContacts": trip.groupContacts.map {[
                    "a-name": $0.name,
                    "b-phone": $0.phone
                ]},
            ],

            "07-carInfo": [
                "a-carName": trip.carName,
                "b-carColor": trip.carColor,
                "c-is4WD": trip.is4WD,
                "d-plateLetters": trip.plateLetters,
                "e-plateNumbers": trip.plateNumbers,
            ],

        ]) { error in
            if error == nil {
                print("trip saved to Firebase")
            } else {
                print("failed to save trip: \(error!.localizedDescription)")
            }
        }
    }
    
    // MARK: - Update Location
    /// Updates the last known location in Firestore.
    ///
    /// Writes to `c-lastKnownLocation` only — does not rewrite the full document.
    /// Called by `ActiveTripSession` every 2km moved or every 30 minutes, whichever comes first.
    ///
    /// - Parameters:
    ///   - tripId: The Firebase trip ID to update.
    ///   - lat: The current latitude.
    ///   - lng: The current longitude.
    ///   - direction: The current heading in degrees, or `nil` if unavailable.
    ///   - onSuccess: Called when the Firestore write succeeds.
    ///   - onFailure: Called when the Firestore write fails.
    func updateLocation(
        tripId: String,
        lat: Double,
        lng: Double,
        direction: Double?,
        onSuccess: (() -> Void)? = nil,
        onFailure: (() -> Void)? = nil
    ) {
        
        let batteryLevel = UIDevice.current.batteryLevel
        let batteryPercentage = batteryLevel >= 0 ? Int(batteryLevel * 100) : -1

        var location: [String: Any] = [
            "a-lat": lat,
            "b-lng": lng,
            "c-direction": "",
            "d-lastUploadTime": Date().timeIntervalSince1970,
            "e-lastUploadTimeReadable": formatDate(Date()),
            "f-deviceBatteryLevel": batteryPercentage
        ]
        
        if let direction = direction {
            location["c-direction"] = readableDirection(from: direction)
        }
        
        db.collection("trips").document(tripId).updateData([
            "04-lastKnownLocation": location
        ]) { error in
            if error == nil {
                print("location updated")
                onSuccess?()
            } else {
                print("failed to update location: \(error!.localizedDescription)")
                onFailure?()
            }
        }
    }

    // MARK: - Update Return Time
    /// Updates the trip's return time in Firestore.
    /// Called when the user edits the return time from ActiveTripCardView during an active trip.
    ///
    /// - Parameters:
    ///   - tripId: The Firebase trip ID to update.
    ///   - returnTime: The new return time selected by the user.
    ///   - onSuccess: Called when the Firestore write succeeds.
    ///   - onFailure: Called when the Firestore write fails (e.g. offline).
    func updateReturnTime(
        tripId: String,
        returnTime: Date,
        onSuccess: (() -> Void)? = nil,
        onFailure: (() -> Void)? = nil
    ) {
        db.collection("trips").document(tripId).updateData([
            "06-tripInfo.d-returnTime": returnTime.timeIntervalSince1970,
            "06-tripInfo.e-returnTimeReadable": formatDate(returnTime)
        ]) { error in
            if error == nil {
                print("return time updated — \(tripId)")
                onSuccess?()
            } else {
                print("failed to update return time: \(error!.localizedDescription)")
                onFailure?()
            }
        }
    }
    
    // MARK: - End Trip
    /// Marks a trip as completed in Firestore.
    ///
    /// Updates `b-status.status` to `"completed"` and records the end time.
    ///
    /// - Parameter tripId: The Firebase trip ID to mark as completed.
    func endTrip(tripId: String) {
        db.collection("trips").document(tripId).updateData([
            "02-status.a-status": "completed",
            "02-status.d-endedAt": Date().timeIntervalSince1970,
            "02-status.e-endedAtReadable": formatDate(Date())
        ]) { error in
            if error == nil {
                print("trip ended")
            } else {
                print("failed to end trip: \(error!.localizedDescription)")
            }
        }
    }

    // MARK: - Listen to Trip Status
    /// Listens to real-time changes on the trip document.
    ///
    /// Used by `ActiveTripSession` to detect when the Cloud Function
    /// marks the trip as completed after 3 updated alerts.
    ///
    /// - Parameters:
    ///   - tripId: The Firebase trip ID to listen to.
    ///   - onStatusChanged: Called with the new status whenever it changes.
    /// - Returns: A `ListenerRegistration` — must be removed when the trip ends.
    func listenToTripStatus(
        tripId: String,
        onStatusChanged: @escaping (String) -> Void
    ) -> ListenerRegistration {
        db.collection("trips").document(tripId).addSnapshotListener { snapshot, error in
            if let error {
                print("FirebaseManager: failed to listen to trip status — \(error.localizedDescription)")
                return
            }

            guard let data = snapshot?.data() else { return }
            let statusObj = data["02-status"] as? [String: Any]
            let status = statusObj?["a-status"] as? String ?? ""
            onStatusChanged(status)
        }
    }

    // MARK: - App Update Config

    func fetchAppUpdateConfig() async throws -> AppUpdateConfig {
        let doc = try await db
            .collection("remoteConfig")
            .document("appUpdate")
            .getDocument()

        let data = doc.data() ?? [:]

        return AppUpdateConfig(
            minimumVersion: data["minimumVersion"] as? String ?? "1.0.0",
            message: data["message"] as? String ?? "Please update the app to continue.",
            appStoreURL: data["appStoreURL"] as? String ?? ""
        )
    }

    // MARK: - Fetch Alert Status
    /// Reads the alert status from Firebase.
    /// Firebase/server is the source of truth for whether the WhatsApp alert was actually sent.
    func fetchAlertStatus(
        tripId: String,
        completion: @escaping (Bool) -> Void
    ) {
        db.collection("trips").document(tripId).getDocument { document, error in

            if let error {
                print("failed to fetch alert status: \(error.localizedDescription)")
                completion(false)
                return
            }

            let data = document?.data()
            let statusObj = data?["02-status"] as? [String: Any]
            let alertSent = statusObj?["f-alertSent"] as? Bool ?? false

            completion(alertSent)
        }
    }
    
    // MARK: - Maintenance Config

    func fetchMaintenanceConfig() async throws -> MaintenanceConfig {
        let doc = try await db
            .collection("remoteConfig")
            .document("maintenance")
            .getDocument()

        let data = doc.data() ?? [:]

        return MaintenanceConfig(
            isEnabled: data["isEnabled"] as? Bool ?? false,
            title: data["title"] as? String ?? "Maintenance Mode",
            message: data["message"] as? String ?? "Desert is currently under maintenance."
        )
    }

    // MARK: - Readable Direction
    /// Converts a heading in degrees to a human-readable compass direction.
    ///
    /// - Parameter course: The heading in degrees (0–360).
    /// - Returns: A compass direction string, e.g. "North", "Southeast".
    private func readableDirection(from course: Double) -> String {
        switch course {
        case 0..<22.5, 337.5...360: return "شمال"
        case 22.5..<67.5:           return "شمال شرقي"
        case 67.5..<112.5:          return "شرق"
        case 112.5..<157.5:         return "جنوب شرقي"
        case 157.5..<202.5:         return "جنوب"
        case 202.5..<247.5:         return "جنوب غربي"
        case 247.5..<292.5:         return "غرب"
        case 292.5..<337.5:         return "شمال غربي"
        default:                    return "غير معروف"
        }
    }

    // MARK: - Format Date
    /// Converts a `Date` to a human-readable string for the Firebase console.
    ///
    /// Format: `dd/MM/yyyy - hh:mm a` — example: `06/05/2026 - 03:45 PM`
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy - hh:mm a"
        return formatter.string(from: date)
    }
}
