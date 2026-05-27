//
//  Components.swift
//  Desert
//
//  All shared UI components used across the app.
//
//  Component usage map:
//  - FieldSection:           CreateTripView (all steps)
//  - SummaryRow:             TripSummaryView, TripHistoryInDetailsView, RepeatTripSummaryView
//  - ContactRow:             CreateTripView (step 2), TripSummaryView
//  - AddContactButton:       CreateTripView (step 2)
//  - StatItem:               TripHistoryInDetailsView
//  - LetterPicker:           CreateTripView (step 3 — plate letters)
//  - NumberBox:              CreateTripView (step 3 — plate numbers)
//  - SummarySection:         TripSummaryView, RepeatTripSummaryView
//  - CustomTabBar:           HomeView, TripHistoryView
//  - ContactPickerSheet:     CreateTripView (emergency + group contacts)
//  - DestinationPickerView:  CreateTripView (step 1)
//  - TappableMapView:        DestinationPickerView
//  - SearchBar:              DestinationPickerView
//
//  Layout direction:
//  - All HStack elements respect system language direction automatically (LTR/RTL).
//  - Use .leading / .trailing instead of .left / .right throughout.
//

import SwiftUI
import MapKit
import ContactsUI

// MARK: - Field Section
// Labeled container for a form field. Used in all CreateTripView steps.

struct FieldSectionA<Content: View>: View {
    var title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.localized)
                .font(.subheadline)
                .fontWeight(.semibold)
            content()
        }
    }
}

// MARK: - Summary Row
// Single label-value row. Used in TripSummaryView and TripHistoryInDetailsView.

struct SummaryRowA: View {
    var label: String
    var value: String

    var body: some View {
        HStack {
            Text(label.localized)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(12)
    }
}

// MARK: - Contact Row
// Displays a contact avatar, name, and phone. Used in CreateTripView and TripSummaryView.

struct ContactRowA: View {
    var contact: Contact

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(.systemGray5))
                .frame(width: 36, height: 36)
                .overlay(
                    Text(String(contact.name.prefix(1)).uppercased())
                        .font(.subheadline)
                        .fontWeight(.medium)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(contact.name).font(.subheadline)
                Text(contact.phone).font(.caption).foregroundColor(.secondary)
                
            }
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Add Contact Button
// Button to open the contact picker. Used in CreateTripView step 2.

struct AddContactButtonA: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.primary)
                    .font(.title3)
                Text("add_contact".localized)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

// MARK: - Stat Item
// Icon + value + label stat block. Used in TripHistoryInDetailsView.

struct StatItemA: View {
    var icon: String
    var value: String
    var label: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.caption).foregroundColor(.secondary)
                Text(value).font(.subheadline).fontWeight(.medium)
            }
            Text(label.localized).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Letter Picker
// Single plate letter picker with up/down chevrons. Used in CreateTripView step 3.

struct LetterPickerA: View {
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "chevron.up").font(.caption2).foregroundColor(.secondary)
            Text("A").font(.subheadline).fontWeight(.medium)
            Image(systemName: "chevron.down").font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Number Box
// Single plate digit box. Used in CreateTripView step 3.

struct NumberBoxA: View {
    var body: some View {
        Text("0")
            .font(.subheadline)
            .fontWeight(.medium)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(8)
    }
}

// MARK: - Summary Section
// Titled card container with styled border. Used in TripSummaryView and RepeatTripSummaryView.

struct SummarySectionA<Content: View>: View {
    var title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title.localized)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.bottom, 6)
            VStack(spacing: 0) { content() }
                .background(Color(UIColor.systemBackground))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.systemGray5), lineWidth: 0.5))
        }
        .padding(.horizontal)
    }
}

// MARK: - Custom Tab Bar
// Capsule-style tab bar with Map and History tabs. Used in HomeView and TripHistoryView.

struct CustomTabBarA: View {

    @Binding var currentPage: AppPage

    var body: some View {
        HStack(spacing: 8) {
            tabItem(icon: "map.fill", labelKey: "tab_map", page: .map)
            tabItem(icon: "clock.fill", labelKey: "tab_history", page: .history)
        }
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .clipShape(Capsule())
    }

    @ViewBuilder
    func tabItem(icon: String, labelKey: String, page: AppPage) -> some View {
        let isSelected = currentPage == page

        Button(action: { currentPage = page }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                Text(labelKey.localized)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .primary : .secondary)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, maxHeight: 56)
            .background(isSelected ? Color(.systemGray5) : Color.clear)
            .clipShape(Capsule())
            .padding(5)
        }
    }
}

// MARK: - Contact Picker Sheet
// Wraps CNContactPickerViewController for native contact selection.
// Used in CreateTripView for emergency and group contacts.

struct ContactPickerSheetA: UIViewControllerRepresentable {

    var onSelect: (CNContact) -> Void

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onSelect: onSelect) }

    class Coordinator: NSObject, CNContactPickerDelegate {
        var onSelect: (CNContact) -> Void
        init(onSelect: @escaping (CNContact) -> Void) { self.onSelect = onSelect }
        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            onSelect(contact)
        }
    }
}

struct ContactPickerSheetB: UIViewControllerRepresentable {

    var onSelect: ([CNContact]) -> Void

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onSelect: onSelect)
    }

    class Coordinator: NSObject, CNContactPickerDelegate {

        var onSelect: ([CNContact]) -> Void

        init(onSelect: @escaping ([CNContact]) -> Void) {
            self.onSelect = onSelect
        }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
            onSelect(contacts)
        }
    }
}
// MARK: - Destination Picker View
// Full-screen map sheet for selecting a trip destination by tapping or searching.
// Used in CreateTripView step 1.

struct DestinationPickerViewA: View {

    @Environment(\.dismiss) private var dismiss
    @Binding var destination: String
    @Binding var lat: Double
    @Binding var lng: Double

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 24.7136, longitude: 46.6753),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var pinCoordinate: CLLocationCoordinate2D?
    @State private var pinName: String = ""

    var body: some View {
        NavigationView {
            ZStack {
                TappableMapViewA(
                    region: $region,
                    pinCoordinate: $pinCoordinate,
                    onTap: { coordinate in
                        pinCoordinate = coordinate
                        reverseGeocode(coordinate)
                    }
                )
                .ignoresSafeArea(edges: .bottom)

                VStack {
                    SearchBarA(text: $searchText, onSearch: search).padding()

                    if !searchResults.isEmpty {
                        List(searchResults, id: \.self) { item in
                            Button(item.name ?? "") { selectLocation(item) }
                        }
                        .frame(maxHeight: 200)
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }

                    Spacer()

                    if !pinName.isEmpty {
                        Text(pinName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }

                    if pinCoordinate != nil {
                        Button(action: {
                            destination = pinName.isEmpty ? coordinateText() : pinName
                            lat = pinCoordinate?.latitude ?? 0
                            lng = pinCoordinate?.longitude ?? 0
                            dismiss()
                        }) {
                            Text("confirm_destination".localized)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.primary)
                                .foregroundColor(Color(UIColor.systemBackground))
                                .cornerRadius(12)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("select_destination".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel".localized) { dismiss() }
                }
            }
        }
    }

    func search() {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = region
        MKLocalSearch(request: request).start { response, _ in
            searchResults = response?.mapItems ?? []
        }
    }

    func selectLocation(_ item: MKMapItem) {
        pinCoordinate = item.placemark.coordinate
        pinName = item.name ?? searchText
        region.center = item.placemark.coordinate
        searchResults = []
        searchText = item.name ?? ""
    }

    func reverseGeocode(_ coordinate: CLLocationCoordinate2D) {
        CLGeocoder().reverseGeocodeLocation(
            CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        ) { placemarks, _ in
            pinName = placemarks?.first?.name ?? coordinateText()
        }
    }

    func coordinateText() -> String {
        guard let pin = pinCoordinate else { return "" }
        return String(format: "%.4f, %.4f", pin.latitude, pin.longitude)
    }
}

// MARK: - Tappable Map View
// UIViewRepresentable wrapping MKMapView with tap gesture and draggable pin.
// Used inside DestinationPickerView.

struct TappableMapViewA: UIViewRepresentable {

    @Binding var region: MKCoordinateRegion
    @Binding var pinCoordinate: CLLocationCoordinate2D?
    var onTap: (CLLocationCoordinate2D) -> Void

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
            mapView.setRegion(MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ), animated: true)
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

    class Coordinator: NSObject, MKMapViewDelegate {
        @Binding var region: MKCoordinateRegion
        @Binding var pinCoordinate: CLLocationCoordinate2D?
        var onTap: (CLLocationCoordinate2D) -> Void

        init(region: Binding<MKCoordinateRegion>,
             pinCoordinate: Binding<CLLocationCoordinate2D?>,
             onTap: @escaping (CLLocationCoordinate2D) -> Void) {
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
            view.markerTintColor = .red
            view.isDraggable = true
            view.canShowCallout = false
            return view
        }

        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView,
                     didChange newState: MKAnnotationView.DragState,
                     fromOldState oldState: MKAnnotationView.DragState) {
            if newState == .ending, let coordinate = view.annotation?.coordinate {
                pinCoordinate = coordinate
                onTap(coordinate)
            }
        }
    }
}

// MARK: - Search Bar
// Simple search input with clear button. Used in DestinationPickerView.

struct SearchBarA: View {
    @Binding var text: String
    var onSearch: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundColor(.secondary)
            TextField("search".localized, text: $text)
                .onSubmit { onSearch() }
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// MARK: - Delete Swipe Action

struct DeleteSwipeActionA: View {

    var action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            Label("delete".localized, systemImage: "trash")
        }
        .tint(.red)
    }
}

// MARK: - Trip History Row
struct TripHistoryRowA: View {

    var trip: Trip
    var dateRange: String
    var duration: String
    var distance: String
    var alertSent: Bool
    var onOpenDetails: () -> Void
    var onRepeatTrip: () -> Void

    var body: some View {
        Button(action: onOpenDetails) {
            VStack(alignment: .leading, spacing: 14) {

                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(trip.tripName)
                            .font(.body.bold())

                        Text(dateRange)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text(alertSent ? "alert_sent".localized : "no_alert".localized)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(alertSent ? Color.red.opacity(0.15) : Color.green.opacity(0.15))
                        .clipShape(Capsule())
                }

                Divider()

                HStack(spacing: 0) {
                    historyStat(icon: "clock.fill", text: duration)

                    Divider().frame(height: 34)

                    historyStat(icon: "car.fill", text: distance)

                    Divider().frame(height: 34)

                    historyStat(
                        icon: "person.3.fill",
                        text: trip.hasGroup
                        ? String(format: "people_count".localized, trip.groupSize)
                        : "solo".localized
                    )
                }

                Divider()

                HStack {
                    Label("trip_details".localized, systemImage: "calendar")
                        .font(.subheadline)
                        .foregroundColor(.primary)

                    Spacer()

                    Button(action: onRepeatTrip) {
                        Label("repeat_trip".localized, systemImage: "arrow.clockwise")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color(.systemGray5))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(.primary)
                }
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .cornerRadius(22)
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(Color(.systemGray5), lineWidth: 0.8)
            )
        }
        .buttonStyle(.plain)
    }

    func historyStat(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.subheadline)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Toast Notification

struct ToastNotificationA: View {

    var message: String
    var icon: String = "wifi.slash"

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline)

            Text(message)
                .font(.subheadline)
                .fontWeight(.medium)

            Spacer()
        }
        .foregroundColor(.primary)
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(14)
        .shadow(radius: 6)
        .padding(.horizontal)
    }
}


// MARK: - Plate Number Input

struct PlateNumberInputA: View {

    @Binding var numbers: String
    let index: Int
    var focusedIndex: FocusState<Int?>.Binding

    var body: some View {
        TextField("", text: digitBinding)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .font(.title3)
            .frame(width: 40, height: 40)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .focused(focusedIndex, equals: index)
    }

    private var digitBinding: Binding<String> {
        Binding(
            get: {
                let chars = Array(numbers)
                return index < chars.count ? String(chars[index]) : ""
            },
            set: { newValue in
                let digit = newValue.filter { $0.isNumber }.prefix(1)
                guard let first = digit.first else { return }

                var chars = Array(numbers)
                while chars.count < 4 {
                    chars.append(" ")
                }

                chars[index] = first
                numbers = String(chars).replacingOccurrences(of: " ", with: "")

                if index < 3 {
                    focusedIndex.wrappedValue = index + 1
                } else {
                    focusedIndex.wrappedValue = nil
                }
            }
        )
    }
}

// MARK: - Plate Letter Input

struct PlateLetterPickerA: View {

    @Binding var selectedLetters: String

    let index: Int
    let letters: [(ar: String, en: String)]
    let isArabic: Bool

    var body: some View {

        Menu {

            ForEach(letters, id: \.ar) { letter in

                Button {

                    updateLetter(
                        isArabic ? letter.ar : letter.en
                    )

                } label: {

                    Text(
                        isArabic
                        ? "\(letter.ar) - \(letter.en)"
                        : "\(letter.en) - \(letter.ar)"
                    )
                }
            }

        } label: {

            ZStack {

                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))

                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(.systemGray4))

                Text(currentLetter)
                    .font(.title3)
                    .foregroundColor(.primary)
            }
            .frame(width: 90, height: 40)
        }
    }

    private var currentLetter: String {

        guard selectedLetters.count > index else { return "-" }

        return String(Array(selectedLetters)[index])
    }

    private func updateLetter(_ value: String) {

        var chars = Array(selectedLetters)

        while chars.count < 3 {
            chars.append(" ")
        }

        chars[index] = Character(value)

        selectedLetters = String(chars)
            .replacingOccurrences(of: " ", with: "")
    }
}
