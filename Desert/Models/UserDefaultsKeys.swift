//
//  UserDefaultsKeys.swift
//  Desert
//

/// All UserDefaults keys used across the app — single source of truth.
///
/// These values store lightweight app/session state that must survive
/// app restarts or force quits. They are not part of the main SwiftData models.
///
/// | Key | Type | Set By | Cleared By | Why is it stored? |
/// |-----|------|--------|------------|-------------------|
/// | `appLanguageSet` | Bool | `DesertApp.init` | Never | Prevents the one-time language setup from running on every launch. |
/// | `appleLanguages` | [String] | `DesertApp.init` | Never | Forces the app to start in English until Arabic layout support is complete. |
/// | `anonymousUserId` | String | `FirebaseManager` | Never | Keeps the same Firebase anonymous user identity across launches so trips remain linked to the same user. |
/// | `activeTripId` | String | `LocationManager` | `LocationManager.stopTracking` | Allows GPS tracking to resume if iOS terminates and later relaunches the app during an active trip. |
/// | `lastSavedLat/Lng` | Double | `TripSessionManager` | `clearActiveTripFromSettings` | Remembers the last GPS point saved locally to avoid creating duplicate track points after a restart. |
/// | `savedPointsCount` | Int | `TripSessionManager` | `clearActiveTripFromSettings` | Continues GPS point numbering from the correct index after a restart. |
/// | `lastUploadDate` | Double | `TripSessionManager` | `clearActiveTripFromSettings` | Preserves the last upload timestamp so the 30-minute fallback upload rule still works after a restart. |
/// | `lastUploadedLat/Lng` | Double | `TripSessionManager` | `clearActiveTripFromSettings` | Remembers the last uploaded coordinate to correctly measure movement distance after a restart. |
///
enum UserDefaultsKeys {

    // MARK: - App

    /// Guards the one-time language setup.
    static let appLanguageSet   = "AppLanguageSet"

    /// Forces the app language — set to `["en"]` until Arabic layout issues are resolved.
    static let appleLanguages   = "AppleLanguages"

    // MARK: - Auth

    /// Firebase anonymous UID — persists across app reinstalls.
    static let anonymousUserId  = "anonymousUserId"

    // MARK: - Trip Session

    /// Active trip ID — used to restore GPS tracking after a force quit.
    static let activeTripId     = "activeTripId"

    /// Last coordinate saved to the local GPS track.
    static let lastSavedLat     = "lastSavedLat"
    static let lastSavedLng     = "lastSavedLng"

    /// Index counter for `LocationPoint` entries — keeps indexes sequential across restarts.
    static let savedPointsCount = "savedPointsCount"

    /// Timestamp of last successful Firebase upload — enforces the 30-min fallback.
    static let lastUploadDate   = "lastUploadDate"

    /// Last coordinate successfully uploaded to Firebase — measures distance since last upload.
    static let lastUploadedLat  = "lastUploadedLat"
    static let lastUploadedLng  = "lastUploadedLng"
}
