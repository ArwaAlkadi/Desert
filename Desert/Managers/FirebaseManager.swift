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
        get { UserDefaults.standard.string(forKey: "anonymousUserId") }
        set { UserDefaults.standard.set(newValue, forKey: "anonymousUserId") }
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
    /// `c-lastKnownLocation` is intentionally excluded here —
    /// it is added later by ``updateLocation(tripId:lat:lng:direction:onSuccess:onFailure:)``
    /// when the first GPS update arrives after the trip starts.
    ///
    /// - Parameters:
    ///   - trip: The `Trip` model containing all trip details.
    ///   - tripId: The ID generated by ``createTripId(completion:)``.
    func saveTrip(_ trip: Trip, tripId: String) {
        db.collection("trips").document(tripId).setData([

            "a-userId": userId ?? "unknown",

            "b-status": trip.status,

            "c-userInfo": [
                "userName": trip.userName,
                "phoneNumber": trip.phoneNumber,
            ],

            "d-emergencyContacts": trip.emergencyContacts.map {[
                "name": $0.name,
                "phone": $0.phone
            ]},

            "e-tripInfo": [
                "tripId": tripId,
                "tripName": trip.tripName,
                "startTime": trip.startTime.timeIntervalSince1970,
                "startTimeReadable": formatDate(trip.startTime),
                "returnTime": trip.returnTime.timeIntervalSince1970,
                "returnTimeReadable": formatDate(trip.returnTime),
                "hasGroup": trip.hasGroup,
                "groupSize": trip.groupSize,
                "groupContacts": trip.groupContacts.map {[
                    "name": $0.name,
                    "phone": $0.phone
                ]},
                "destination": trip.destination,
                "destinationCoordinates": [
                    "lat": trip.destinationLat,
                    "lng": trip.destinationLng
                ],
            ],

            "f-carInfo": [
                "carName": trip.carName,
                "carColor": trip.carColor,
                "is4WD": trip.is4WD,
                "plateLetters": trip.plateLetters,
                "plateNumbers": trip.plateNumbers,
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
    /// Called by `TripSessionManager` every 2km moved or every 30 minutes, whichever comes first.
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
        var location: [String: Any] = [
            "lat": lat,
            "lng": lng,
            "lastUploadTime": Date().timeIntervalSince1970,
            "lastUploadTimeReadable": formatDate(Date())
        ]
        
        if let direction = direction {
            location["direction"] = direction
        }
        
        db.collection("trips").document(tripId).updateData([
            "c-lastKnownLocation": location
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
            "e-tripInfo.returnTime": returnTime.timeIntervalSince1970,
            "e-tripInfo.returnTimeReadable": formatDate(returnTime)
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
    /// Updates `b-status` to `"completed"` only — does not modify any other fields.
    ///
    /// - Parameter tripId: The Firebase trip ID to mark as completed.
    func endTrip(tripId: String) {
        db.collection("trips").document(tripId).updateData([
            "b-status": "completed"
        ]) { error in
            if error == nil {
                print("trip ended")
            } else {
                print("failed to end trip: \(error!.localizedDescription)")
            }
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
    /// Firebase/server is the source of truth for whether the SMS alert was actually sent.

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
            let alertStatus = data?["h-alertStatus"] as? [String: Any]
            let alertSent = alertStatus?["alertSent"] as? Bool ?? false

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
