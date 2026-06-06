//
//  TripMapView.swift
//  Desert
//
//  Live trip map — shown in HomeView during an active trip.
//
//  Displays:
//  - Local GPS track (red polyline, saved every 250m, never uploaded)
//  - Last uploaded location (blue pin)
//  - Destination pin (orange pin)
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

    var localTrack: [CLLocationCoordinate2D]
    var lastUploadedLocation: CLLocationCoordinate2D?
    var destinationLocation: CLLocationCoordinate2D?
    var userLocation: CLLocationCoordinate2D?
    var mapType: MKMapType = .standard
    var centerTrigger: Int = 0
    var resetNorthTrigger: Int = 0

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
            compassButton.trailingAnchor.constraint(equalTo: mapView.trailingAnchor, constant: -30),
            compassButton.topAnchor.constraint(equalTo: mapView.safeAreaLayoutGuide.topAnchor, constant: 16),
            scaleView.leadingAnchor.constraint(equalTo: mapView.leadingAnchor, constant: 16),
            scaleView.topAnchor.constraint(equalTo: mapView.safeAreaLayoutGuide.topAnchor, constant: 16)
        ])

        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        context.coordinator.userLocation = userLocation

        if context.coordinator.lastCenterTrigger != centerTrigger {
            context.coordinator.lastCenterTrigger = centerTrigger
            context.coordinator.centerOnUser()
        }

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

        if userLocation == nil && mapView.overlays.isEmpty && mapView.annotations.isEmpty {
            fitMapToContent(mapView)
        }

        if let loc = userLocation, mapView.annotations.isEmpty {
            let region = MKCoordinateRegion(
                center: loc,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
            mapView.setRegion(region, animated: true)
        }

        let existingPolylines = mapView.overlays.compactMap { $0 as? MKPolyline }
        let existingPointCount = existingPolylines.first?.pointCount ?? 0

        if localTrack.count > 1 && localTrack.count != existingPointCount {
            let newPolyline = MKPolyline(coordinates: localTrack, count: localTrack.count)
            newPolyline.title = "Local"
            mapView.removeOverlays(existingPolylines)
            mapView.addOverlay(newPolyline)
        }

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

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator: NSObject, MKMapViewDelegate {

        weak var mapView: MKMapView?
        var userLocation: CLLocationCoordinate2D?
        var lastCenterTrigger = 0
        var lastResetNorthTrigger = 0

        func centerOnUser() {
            guard let mapView, let userLocation else { return }

            let region = MKCoordinateRegion(
                center: userLocation,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )

            mapView.setRegion(region, animated: true)
        }

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

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard !(annotation is MKUserLocation) else { return nil }

            let reuseId = annotation.title ?? "pin"

            let view = MKMarkerAnnotationView(
                annotation: annotation,
                reuseIdentifier: reuseId
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

