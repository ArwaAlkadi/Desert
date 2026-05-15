//
//  TripHistoryInDetailsView.swift
//  Desert
//

import SwiftUI
import MapKit
import SwiftData

struct TripHistoryInDetailsView: View {

    var trip: Trip

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @StateObject private var vm = TripHistoryViewModel()

    @State private var showRepeatTrip = false
    @State private var showFullMap = false
    @State private var showDeleteAlert = false

    var localTrack: [CLLocationCoordinate2D] {
        trip.gpsTrack.map {
            CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lng)
        }
    }

    var destinationLocation: CLLocationCoordinate2D? {
        guard trip.destinationLat != 0 else { return nil }

        return CLLocationCoordinate2D(
            latitude: trip.destinationLat,
            longitude: trip.destinationLng
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                HStack {
                    Text(trip.tripName)
                        .font(.title)
                        .fontWeight(.bold)

                    Spacer()

                    Text(trip.alertSent ? "alert_sent".localized : "no_alert".localized)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(trip.alertSent ? Color.red.opacity(0.15) : Color.green.opacity(0.15))
                        .clipShape(Capsule())
                }
                .padding(.horizontal)

                ZStack(alignment: .topLeading) {
                    TripMapView(
                        localTrack: localTrack,
                        lastUploadedLocation: nil,
                        destinationLocation: destinationLocation,
                        userLocation: nil,
                        showUserLocation: false,
                        showCenterButton: false
                    )
                    .frame(height: 220)
                    .cornerRadius(16)
                    .allowsHitTesting(false)

                    Button(action: {
                        showFullMap = true
                    }) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .padding(10)
                            .background(Color(UIColor.systemBackground))
                            .clipShape(Circle())
                    }
                    .padding(10)
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 12) {
                    Text("trip_details".localized)
                        .font(.headline)
                        .padding(.horizontal)

                    VStack(spacing: 0) {
                        SummaryRow(label: "start_time", value: formatDate(trip.startTime))
                        Divider()

                        SummaryRow(label: "return_time", value: formatDate(trip.returnTime))
                        Divider()

                        SummaryRow(label: "destination", value: trip.destination)
                        Divider()

                        SummaryRow(
                            label: "individuals",
                            value: trip.hasGroup
                            ? String(format: "people_count".localized, trip.groupSize)
                            : "solo".localized
                        )
                        Divider()

                        SummaryRow(
                            label: "car_details",
                            value: "\(trip.carColor) \(trip.carName)"
                        )
                        Divider()

                        SummaryRow(
                            label: "plate_number",
                            value: "\(trip.plateNumbers) | \(trip.plateLetters)"
                        )
                        Divider()

                        SummaryRow(
                            label: "distance",
                            value: "\(trip.gpsTrack.count * 250 / 1000) KM"
                        )
                    }
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(18)
                    .padding(.horizontal)
                }

                if !trip.emergencyContacts.isEmpty {
                    contactSection(
                        title: "emergency_contacts".localized,
                        count: trip.emergencyContacts.count,
                        contacts: trip.emergencyContacts
                    )
                }

                if trip.hasGroup && !trip.groupContacts.isEmpty {
                    contactSection(
                        title: "group_contacts_optional".localized,
                        count: trip.groupContacts.count,
                        contacts: trip.groupContacts
                    )
                }

                Button(action: {
                    showRepeatTrip = true
                }) {
                    Text("repeat_trip".localized)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.primary)
                        .foregroundColor(Color(UIColor.systemBackground))
                        .cornerRadius(22)
                }
                .padding(.horizontal, 40)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
            .padding(.top, 24)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding(10)
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    showDeleteAlert = true
                }) {
                    Image(systemName: "trash")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding(10)
                }
            }
        }
        .alert("delete".localized, isPresented: $showDeleteAlert) {
            Button("cancel".localized, role: .cancel) { }

            Button("delete".localized, role: .destructive) {
                // Routed through TripHistoryViewModel — not SwiftData directly
                vm.deleteTrip(trip, context: context)
                dismiss()
            }
        } message: {
            Text("delete_trips_message".localized)
        }
        .navigationDestination(isPresented: $showRepeatTrip) {
            CreateTripView(
                showParentSheet: $showRepeatTrip,
                tripToRepeat: trip,
                onTripStarted: {
                    showRepeatTrip = false
                },
                onCancel: {
                    showRepeatTrip = false
                }
            )
        }
        .fullScreenCover(isPresented: $showFullMap) {
            ZStack(alignment: .topLeading) {
                ReplayMapView(
                    localTrack: localTrack,
                    destinationLocation: destinationLocation
                )

                Button(action: {
                    showFullMap = false
                }) {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding(12)
                        .background(Color(UIColor.systemBackground))
                        .clipShape(Circle())
                }
                .padding()
            }
        }
    }

    func contactSection(title: String, count: Int, contacts: [Contact]) -> some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack {
                Text(title)
                    .font(.headline)

                Spacer()

                Text("(\(count) Contact selected)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)

            VStack(spacing: 0) {
                ForEach(contacts, id: \.name) { contact in
                    ContactRow(contact: contact)

                    if contact.name != contacts.last?.name {
                        Divider()
                            .padding(.leading, 60)
                    }
                }
            }
            .background(Color(UIColor.systemBackground))
            .cornerRadius(18)
            .padding(.horizontal)
        }
    }

    func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "d MMMM, h:mma"
        return f.string(from: date)
    }
}
