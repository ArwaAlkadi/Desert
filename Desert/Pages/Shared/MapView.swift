//
//  MapView.swift
//  Desert
//
//  Live trip map — shown in HomeView during an active trip.
//
//  Displays:
//  - Local GPS track (polyline, saved every 250m, never uploaded)
//  - Last uploaded location pin
//  - Destination pin
//  - User's current location dot
//
//  Supports:
//  - Map type switching (standard / satellite / hybrid)
//  - Center on user (via centerTrigger increment)
//  - Reset north (via resetNorthTrigger increment)
//

import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {

    // MARK: - Input

    var localTrack: [CLLocationCoordinate2D]
    var lastUploadedLocation: CLLocationCoordinate2D?
    var destinationLocation: CLLocationCoordinate2D?
    var userLocation: CLLocationCoordinate2D?
    var mapType: MKMapType = .standard
    var centerTrigger: Int = 0
    var resetNorthTrigger: Int = 0

    // MARK: - UIViewRepresentable

    /// Builds the MKMapView with user location dot, custom compass, and scale view.
    /// Native compass and scale are hidden and replaced with manually positioned ones
    /// to allow precise layout control independent of safe area insets.
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        context.coordinator.mapView = mapView
        mapView.showsUserLocation = true
        mapView.showsCompass = false
        mapView.showsScale = false

        let compassButton = MKCompassButton(mapView: mapView)
        compassButton.compassVisibility = .visible
        compassButton.translatesAutoresizingMaskIntoConstraints = false
        mapView.addSubview(compassButton)

        let scaleView = MKScaleView(mapView: mapView)
        scaleView.translatesAutoresizingMaskIntoConstraints = false
        mapView.addSubview(scaleView)

        NSLayoutConstraint.activate([
            compassButton.trailingAnchor.constraint(equalTo: mapView.trailingAnchor, constant: -22),
            compassButton.topAnchor.constraint(equalTo: mapView.safeAreaLayoutGuide.topAnchor, constant: 16),
            scaleView.leadingAnchor.constraint(equalTo: mapView.leadingAnchor, constant: 16),
            scaleView.topAnchor.constraint(equalTo: mapView.safeAreaLayoutGuide.topAnchor, constant: 16)
        ])

        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        context.coordinator.userLocation = userLocation

        // Center on user if the trigger incremented
        if context.coordinator.lastCenterTrigger != centerTrigger {
            context.coordinator.lastCenterTrigger = centerTrigger
            context.coordinator.centerOnUser()
        }

        // Reset map heading to north if the trigger incremented
        if context.coordinator.lastResetNorthTrigger != resetNorthTrigger {
            context.coordinator.lastResetNorthTrigger = resetNorthTrigger
            mapView.setCamera(
                MKMapCamera(
                    lookingAtCenter: mapView.centerCoordinate,
                    fromDistance: mapView.camera.centerCoordinateDistance,
                    pitch: 0,
                    heading: 0
                ),
                animated: true
            )
        }

        // Fit map to show track + destination if no user location is available yet
        if userLocation == nil && mapView.overlays.isEmpty && mapView.annotations.isEmpty {
            fitMapToContent(mapView)
        }

        // Center on user location on first appearance (before any annotations are added)
        if let loc = userLocation, mapView.annotations.isEmpty {
            mapView.setRegion(
                MKCoordinateRegion(
                    center: loc,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                ),
                animated: true
            )
        }

        // Update polyline only if the track has new points — avoids unnecessary redraws
        let existingPolylines = mapView.overlays.compactMap { $0 as? MKPolyline }
        let existingPointCount = existingPolylines.first?.pointCount ?? 0

        if localTrack.count > 1 && localTrack.count != existingPointCount {
            let newPolyline = MKPolyline(coordinates: localTrack, count: localTrack.count)
            newPolyline.title = "Local"
            mapView.removeOverlays(existingPolylines)
            mapView.addOverlay(newPolyline)
        }

        // Remove and re-add annotations on every update — pins are lightweight
        let existingAnnotations = mapView.annotations.filter { !($0 is MKUserLocation) }
        mapView.removeAnnotations(existingAnnotations)

        if let dest = destinationLocation {
            let annotation = MKPointAnnotation()
            annotation.coordinate = dest
            annotation.title = "map.destination".localized
            mapView.addAnnotation(annotation)
        }

        if let uploaded = lastUploadedLocation {
            let annotation = MKPointAnnotation()
            annotation.coordinate = uploaded
            annotation.title = "map.lastSharedLocation".localized
            mapView.addAnnotation(annotation)
        }

        mapView.mapType = mapType
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    // MARK: - Helpers

    /// Fits the map region to show the full GPS track and destination pin.
    private func fitMapToContent(_ mapView: MKMapView) {
        var coordinates = localTrack
        if let dest = destinationLocation { coordinates.append(dest) }
        guard !coordinates.isEmpty else { return }

        var minLat = coordinates[0].latitude
        var maxLat = coordinates[0].latitude
        var minLng = coordinates[0].longitude
        var maxLng = coordinates[0].longitude

        for coord in coordinates {
            minLat = min(minLat, coord.latitude)
            maxLat = max(maxLat, coord.latitude)
            minLng = min(minLng, coord.longitude)
            maxLng = max(maxLng, coord.longitude)
        }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLng + maxLng) / 2
        )

        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.4, 0.01),
            longitudeDelta: max((maxLng - minLng) * 1.4, 0.01)
        )

        mapView.setRegion(MKCoordinateRegion(center: center, span: span), animated: true)
    }
}

// MARK: - Coordinator

extension MapView {

    class Coordinator: NSObject, MKMapViewDelegate {

        weak var mapView: MKMapView?
        var userLocation: CLLocationCoordinate2D?
        var lastCenterTrigger = 0
        var lastResetNorthTrigger = 0

        /// Centers the map on the user's current location at street level.
        func centerOnUser() {
            guard let mapView, let userLocation else { return }
            mapView.setRegion(
                MKCoordinateRegion(
                    center: userLocation,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                ),
                animated: true
            )
        }

        /// Renders the local GPS track as a solid polyline.
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                if polyline.title == "Local" {
                    renderer.strokeColor = .primary
                    renderer.lineWidth = 5
                }
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }

        /// Colors annotation pins by type: destination (orange), last upload (green).
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard !(annotation is MKUserLocation) else { return nil }

            let view = MKMarkerAnnotationView(
                annotation: annotation,
                reuseIdentifier: annotation.title ?? "pin"
            )
            view.canShowCallout = true

            switch annotation.title {
            case "map.destination".localized:
                view.markerTintColor = .secondary02
            case "map.lastSharedLocation".localized:
                view.markerTintColor = .positive
            default:
                view.markerTintColor = .systemBlue
                view.canShowCallout = false
            }

            return view
        }
    }
}
