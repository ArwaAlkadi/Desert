
//
//  DestinationPickerMapView.swift
//  Desert
//
//  Tappable map used inside DestinationPickerView.
//
//  Responsibilities:
//  - Drops a draggable pin wherever the user taps
//  - Zooms to a coordinate when driven externally (from search results)
//  - Returns the selected coordinate via onTap callback
//
//  Does NOT handle:
//  - Search UI (owned by DestinationPickerView)
//  - Reverse geocoding (owned by DestinationPickerView)
//  - Confirm / cancel actions (owned by DestinationPickerView)
//

import SwiftUI
import MapKit

// MARK: Standalone input-only map for destination selection. Independent from MapView — built specifically for tap and drag interaction, not for display or reuse.
struct DestinationPickerMapView: UIViewRepresentable {

    @Binding var region: MKCoordinateRegion
    @Binding var pinCoordinate: CLLocationCoordinate2D?
    var onTap: (CLLocationCoordinate2D) -> Void

    // MARK: - Make

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.setRegion(region, animated: false)

        let tap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        mapView.addGestureRecognizer(tap)

        return mapView
    }

    // MARK: - Update

    func updateUIView(_ mapView: MKMapView, context: Context) {
        if let coordinate = pinCoordinate {
            mapView.setRegion(
                MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                ),
                animated: true
            )
        }

        mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })

        if let coordinate = pinCoordinate {
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            mapView.addAnnotation(annotation)
        }
    }

    // MARK: - Coordinator

    func makeCoordinator() -> Coordinator {
        Coordinator(region: $region, pinCoordinate: $pinCoordinate, onTap: onTap)
    }

    class Coordinator: NSObject, MKMapViewDelegate {

        @Binding var region: MKCoordinateRegion
        @Binding var pinCoordinate: CLLocationCoordinate2D?
        var onTap: (CLLocationCoordinate2D) -> Void

        init(
            region: Binding<MKCoordinateRegion>,
            pinCoordinate: Binding<CLLocationCoordinate2D?>,
            onTap: @escaping (CLLocationCoordinate2D) -> Void
        ) {
            _region = region
            _pinCoordinate = pinCoordinate
            self.onTap = onTap
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            let mapView = gesture.view as! MKMapView
            let coordinate = mapView.convert(
                gesture.location(in: mapView),
                toCoordinateFrom: mapView
            )
            onTap(coordinate)
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard !(annotation is MKUserLocation) else { return nil }
            let view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "pin")
            view.markerTintColor = .secondary02
            view.isDraggable = true
            view.canShowCallout = false
            return view
        }

        func mapView(
            _ mapView: MKMapView,
            annotationView view: MKAnnotationView,
            didChange newState: MKAnnotationView.DragState,
            fromOldState oldState: MKAnnotationView.DragState
        ) {
            if newState == .ending, let coordinate = view.annotation?.coordinate {
                pinCoordinate = coordinate
                onTap(coordinate)
            }
        }
    }
}
