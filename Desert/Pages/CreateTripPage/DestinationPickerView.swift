//
//  DestinationPickerView.swift
//  Desert
//
//  Shown when the user taps the Destination field in CreateTripStepsView.
//
//  Flow:
//  1. User types in the search bar → MKLocalSearch returns suggestions
//  2. User taps a suggestion → map jumps to that location, pin drops
//  3. Alternatively, user taps anywhere on the map → pin drops, reverse geocode fills name
//  4. User taps "Select" → vm updates destination/lat/lng → sheet dismisses
//
//  All logic lives in CreateTripViewModel — this view is UI only.
//

import SwiftUI
import MapKit

struct DestinationPickerView: View {

    // MARK: - Input

    @ObservedObject var vm: CreateTripViewModel

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        SelectDestinationTemplate(
            searchText: $vm.destinationSearchText,
            searchResults: vm.formattedSearchResults,
            canConfirm: vm.pinCoordinate != nil,
            mapContent: {
                DestinationPickerView.MapView(
                    region: $vm.destinationRegion,
                    pinCoordinate: $vm.pinCoordinate,
                    onTap: { coordinate in
                        vm.pinCoordinate = coordinate
                        vm.reverseGeocode(coordinate)
                    }
                )
            },
            onBack: { dismiss() },
            onSearch: { vm.searchDestination() },
            onSelectResult: { item in vm.selectDestination(item) },
            onConfirm: {
                vm.confirmDestination()
                dismiss()
            }
        )
        .onChange(of: vm.destinationSearchText) { _, newValue in
            if newValue.isEmpty { vm.destinationSearchResults = [] }
        }
    }
}

// MARK: - Preview

#Preview {
    let vm = CreateTripViewModel()
    vm.destination = "Al Thumamah"
    vm.destinationLat = 24.9
    vm.destinationLng = 46.7

    return NavigationStack {
        DestinationPickerView(vm: vm)
    }
}

// MARK: - Embedded Map

extension DestinationPickerView {

    /// Input-only map for destination selection — built for tap and drag, not for display or reuse.
    struct MapView: UIViewRepresentable {

        // MARK: - Input

        @Binding var region: MKCoordinateRegion
        @Binding var pinCoordinate: CLLocationCoordinate2D?
        var onTap: (CLLocationCoordinate2D) -> Void

        // MARK: - UIViewRepresentable

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

        func makeCoordinator() -> Coordinator {
            Coordinator(region: $region, pinCoordinate: $pinCoordinate, onTap: onTap)
        }

        // MARK: - Coordinator

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

            /// Converts a tap gesture location to a map coordinate and fires `onTap`.
            @objc func handleTap(_ gesture: UITapGestureRecognizer) {
                let mapView = gesture.view as! MKMapView
                let coordinate = mapView.convert(
                    gesture.location(in: mapView),
                    toCoordinateFrom: mapView
                )
                onTap(coordinate)
            }

            /// Renders the dropped pin as a draggable marker.
            func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
                guard !(annotation is MKUserLocation) else { return nil }
                let view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "pin")
                view.markerTintColor = .secondary02
                view.isDraggable = true
                view.canShowCallout = false
                return view
            }

            /// Updates `pinCoordinate` when the user finishes dragging the pin.
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
}
