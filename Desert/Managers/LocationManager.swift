//
//  LocationManager.swift
//  Desert
//

import Foundation
import CoreLocation
import SwiftData
import Combine

// MARK: - LocationManagerDelegate

protocol LocationManagerDelegate: AnyObject {
    /// يُستدعى كلما وصل موقع جديد صالح — فقط أثناء رحلة نشطة
    func onNewLocationReceived(_ location: CLLocation)
    /// يُستدعى عندما يعود المستخدم لنقطة البداية
    func onUserReturnedToStartPoint()
}

// MARK: - LocationManager

/// مسؤول عن GPS فقط.
///
/// ## القاعدة الأساسية
/// - التتبع في الخلفية يعمل **فقط** أثناء رحلة نشطة
/// - بدون رحلة = لا background updates = لا battery drain
///
/// ## Responsibilities
/// 1. طلب صلاحية الموقع
/// 2. تتبع الموقع أثناء الرحلة فقط
/// 3. مراقبة نقطة البداية (CLMonitor)
/// 4. إرسال updates للـ delegate (TripSessionManager)
/// 5. استعادة الجلسة بعد force quit
///
/// ## ما لا يفعله
/// - لا يحفظ في SwiftData
/// - لا يرفع لـ Firebase
/// - لا يرسل إشعارات
/// - لا يبدأ background tracking بدون رحلة
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    static let shared = LocationManager()

    private let clManager = CLLocationManager()

    /// هل التتبع نشط الآن
    @Published var isTrackingActive = false

    /// آخر موقع للمستخدم — لتوسيط الخريطة فقط
    @Published var currentUserLocation: CLLocationCoordinate2D?

    /// صلاحية الموقع الحالية
    @Published var locationPermissionStatus: CLAuthorizationStatus = .notDetermined

    /// المستقبل لأحداث GPS — TripSessionManager
    weak var delegate: LocationManagerDelegate?

    var activeTripId: String = ""

    private let gpsDistanceFilter: CLLocationDistance = 100
    private let maxAcceptableAccuracy: CLLocationAccuracy = 150
    private var originMonitor: CLMonitor?
    private var originMonitorTask: Task<Void, Never>?
    private var originMonitoringStarted = false

    // MARK: - Init
    /// لا يبدأ أي tracking هنا — فقط إعداد الـ delegate
    override init() {
        super.init()
        clManager.delegate = self
        // لا requestLocation() هنا — ما في background tracking بدون رحلة
    }

    // MARK: - طلب صلاحية الموقع
    func requestLocationPermission() {
        clManager.requestAlwaysAuthorization()
    }

    // MARK: - طلب موقع مبدئي للخريطة فقط
    /// يُستدعى مرة واحدة بعد منح الصلاحية لتوسيط الخريطة
    /// لا يفعّل background tracking
    func requestInitialLocationForMap() {
        guard clManager.authorizationStatus == .authorizedWhenInUse ||
              clManager.authorizationStatus == .authorizedAlways else { return }
        clManager.desiredAccuracy = kCLLocationAccuracyKilometer
        clManager.requestLocation()  // مرة واحدة فقط — لا continuous updates
    }

    // MARK: - بدء تتبع رحلة نشطة
    /// يفعّل background tracking — يُستدعى فقط عند بدء رحلة
    func startTrackingForTrip(_ tripId: String) {
        stopOriginMonitoring()
        originMonitoringStarted = false

        UserDefaults.standard.set(tripId, forKey: "activeTripId")
        activeTripId = tripId
        isTrackingActive = true

        // battery optimizations
        clManager.activityType = .automotiveNavigation
        clManager.pausesLocationUpdatesAutomatically = true
        clManager.desiredAccuracy = kCLLocationAccuracyBest
        clManager.distanceFilter = gpsDistanceFilter

        // background tracking — فقط هنا
        clManager.allowsBackgroundLocationUpdates = true
        clManager.showsBackgroundLocationIndicator = true

        clManager.startUpdatingLocation()
        clManager.startMonitoringSignificantLocationChanges()

        if let origin = currentUserLocation {
            startMonitoringReturnToStart(lat: origin.latitude, lng: origin.longitude)
            originMonitoringStarted = true
        }

        print("LocationManager: بدأ التتبع — \(tripId)")
    }

    // MARK: - إيقاف التتبع
    /// يوقف كل شيء تماماً — لا background tracking بعدها
    func stopTracking() {
        clManager.stopUpdatingLocation()
        clManager.stopMonitoringSignificantLocationChanges()

        // أوقف background tracking تماماً
        clManager.allowsBackgroundLocationUpdates = false
        clManager.showsBackgroundLocationIndicator = false
        clManager.pausesLocationUpdatesAutomatically = false

        stopOriginMonitoring()

        isTrackingActive = false
        originMonitoringStarted = false
        activeTripId = ""

        UserDefaults.standard.removeObject(forKey: "activeTripId")

        print("LocationManager: أُوقف التتبع — لا background tracking")
    }

    // MARK: - استئناف التتبع عند العودة للتطبيق
    func resumeTrackingForTrip(_ tripId: String) {
        activeTripId = tripId
        isTrackingActive = true
        originMonitoringStarted = false

        clManager.activityType = .automotiveNavigation
        clManager.pausesLocationUpdatesAutomatically = true
        clManager.desiredAccuracy = kCLLocationAccuracyBest
        clManager.distanceFilter = gpsDistanceFilter
        clManager.allowsBackgroundLocationUpdates = true
        clManager.showsBackgroundLocationIndicator = true
        clManager.startUpdatingLocation()
        clManager.startMonitoringSignificantLocationChanges()

        print("LocationManager: استُؤنف التتبع — \(tripId)")
    }

    // MARK: - استعادة الجلسة بعد force quit
    func restoreSessionAfterForceQuit() {
        let tripId = UserDefaults.standard.string(forKey: "activeTripId") ?? ""
        guard !tripId.isEmpty else { return }

        activeTripId = tripId
        isTrackingActive = true
        originMonitoringStarted = false

        clManager.activityType = .automotiveNavigation
        clManager.pausesLocationUpdatesAutomatically = true
        clManager.desiredAccuracy = kCLLocationAccuracyBest
        clManager.distanceFilter = gpsDistanceFilter
        clManager.allowsBackgroundLocationUpdates = true
        clManager.showsBackgroundLocationIndicator = true
        clManager.startUpdatingLocation()
        clManager.startMonitoringSignificantLocationChanges()

        print("LocationManager: استُعيدت الجلسة — \(tripId)")
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        // دائماً حدّث الموقع للخريطة
        DispatchQueue.main.async { self.currentUserLocation = location.coordinate }

        // لا تُبلّغ الـ delegate إلا أثناء رحلة نشطة
        guard isTrackingActive, !activeTripId.isEmpty else { return }

        guard location.horizontalAccuracy > 0,
              location.horizontalAccuracy <= maxAcceptableAccuracy else { return }

        // ابدأ مراقبة نقطة البداية عند أول موقع صالح
        if !originMonitoringStarted {
            startMonitoringReturnToStart(
                lat: location.coordinate.latitude,
                lng: location.coordinate.longitude
            )
            originMonitoringStarted = true
        }

        // دقة ديناميكية — توفير البطارية
        clManager.desiredAccuracy = location.speed > 5.0
            ? kCLLocationAccuracyBest
            : kCLLocationAccuracyHundredMeters

        // أرسل للـ TripSessionManager فقط
        delegate?.onNewLocationReceived(location)
    }

    func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
        print("LocationManager: GPS متوقف مؤقتاً — الجهاز ثابت")
    }

    func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
        print("LocationManager: GPS استُؤنف — الجهاز يتحرك")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        locationPermissionStatus = manager.authorizationStatus

        // طلب موقع مبدئي للخريطة فقط عند منح الصلاحية
        // لا يفعّل background tracking
        if manager.authorizationStatus == .authorizedWhenInUse ||
           manager.authorizationStatus == .authorizedAlways {
            requestInitialLocationForMap()
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LocationManager: خطأ — \(error.localizedDescription)")
    }

    // MARK: - مراقبة نقطة البداية

    private func startMonitoringReturnToStart(lat: Double, lng: Double) {
        originMonitorTask = Task {
            let center = CLLocationCoordinate2D(latitude: lat, longitude: lng)
            let region = CLMonitor.CircularGeographicCondition(center: center, radius: 1000)
            let monitorName = "origin\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))"

            originMonitor = await CLMonitor(monitorName)
            await originMonitor?.add(region, identifier: "startPoint")

            guard let originMonitor else { return }
            var isFirstEvent = true

            do {
                for try await event in await originMonitor.events {
                    if isFirstEvent { isFirstEvent = false; continue }
                    if event.state == .satisfied {
                        delegate?.onUserReturnedToStartPoint()
                    }
                }
            } catch {
                print("LocationManager: خطأ في المراقبة — \(error.localizedDescription)")
            }
        }
    }

    private func stopOriginMonitoring() {
        originMonitorTask?.cancel()
        originMonitorTask = nil
        originMonitor = nil
    }
}
