//
//  HistoryTripDetailsTemplate.swift
//  Desert
//
//  Created by Samar A on 11/12/1447 AH.
//


import SwiftUI

struct HistoryTripDetailsTemplate: View {

    var tripName: String
    var alertSent: Bool
    var startTime: Date
    var returnTime: Date
    var destination: String
    var isGroup: Bool
    var groupCount: Int
    var carDetails: String
    var plateNumber: String
    var distance: String
    var emergencyContacts: [(initial: String, name: String, phone: String)]
    var groupContacts: [(initial: String, name: String, phone: String)]
    var onBack: () -> Void = {}
    var onDelete: () -> Void = {}
    var onRepeatTrip: () -> Void = {}
    var onExpandMap: () -> Void = {}
    var hasActiveTrip: Bool

    @State private var showDeleteAlert = false

    var body: some View {
        VStack(spacing: 0) {
            HeaderView(
                trailingButton: .trash
            ) {
                onBack()
            } trailingAction: {
                showDeleteAlert = true
            }
            .padding(.top, 0)
            .padding(.bottom, AppSpacing.xl)
            .padding(.horizontal, AppSpacing.md)


            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    tripHeaderSection
                    tripMapSection
                    tripSummarySection
                    emergencyContactsSection
                    groupContactsSection
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AppSpacing.md)
                .padding(.bottom, 90)

            }
        }
        .padding(.top, AppSpacing.sm)
        .background(Color.Background)
        .safeAreaInset(edge: .bottom) {
            CTAButton(
                title: "history.repeatTrip".localized,
                style: .secondary
            ) {
                guard !hasActiveTrip else { return }
                onRepeatTrip()
            }
            .disabled(hasActiveTrip)
            .opacity(hasActiveTrip ? 0.6 : 1)
            .padding(.horizontal, AppSpacing.xxl)
            .padding(.top, AppSpacing.lg)
            .padding(.bottom, AppSpacing.sm)
            .background(Color.Background)
        }
        .alert("history.delete.title".localized, isPresented: $showDeleteAlert) {
            Button("common.cancel".localized, role: .cancel) { }
            Button("common.delete".localized, role: .destructive) {
                onDelete()
            }
        }
    }
}








private extension HistoryTripDetailsTemplate {

    var tripHeaderSection: some View {
        HStack {
            Text(tripName)
                .font(AppTypography.title3)
                .foregroundStyle(Color.Lableblack)

            Spacer()

            StatusBadge(
                titleKey: alertSent ? "history.status.alert" : "history.status.noAlert",
                style: alertSent ? .destructive : .positive,
                size: .large
            )
        }
    }

    var tripMapSection: some View {
        ZStack(alignment: .topTrailing) {
            Image("tripMap")
                .resizable()
                .scaledToFill()
                .frame(height: 160)
                .frame(maxWidth: .infinity)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))

            Button {
                onExpandMap()
            } label: {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.Primary)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.md)
            }
            .buttonStyle(.plain)
        }
    }

    var tripSummarySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("history.tripSummary".localized)
                .font(AppTypography.headline)
                .foregroundStyle(Color.Lableblack)

            TripSummaryCard(rows: [
                ("summary.startTime", formatDate(startTime)),
                ("summary.returnTime", formatDate(returnTime)),
                ("summary.destination", destination),
                (
                    "summary.numberOfIndividuals",
                    isGroup
                        ? String.localizedStringWithFormat(
                            NSLocalizedString("people.count", tableName: "PluralStrings", comment: ""),
                            groupCount
                          )
                        : "solo".localized
                ),
                ("summary.carDetails", carDetails),
                ("summary.plateNumber", plateNumber),
                ("summary.distance", distance)
            ])
        }
    }

    var emergencyContactsSection: some View {
        contactsSection(
            titleKey: "summary.emergencyContacts",
            count: emergencyContacts.count,
            contacts: emergencyContacts
        )
    }

    @ViewBuilder
    var groupContactsSection: some View {
        if isGroup && !groupContacts.isEmpty {
            contactsSection(
                titleKey: "history.groupContacts",
                count: groupContacts.count,
                contacts: groupContacts
            )
        }
    }

    func contactsSection(
        titleKey: String,
        count: Int,
        contacts: [(initial: String, name: String, phone: String)]
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                Text(titleKey.localized)
                    .font(AppTypography.headline)
                    .foregroundStyle(Color.Lableblack)

                Text("(\(count))")
                    .font(AppTypography.caption2)
                    .foregroundStyle(Color.Lableblack)

                Spacer()
            }
            .padding(.horizontal, AppSpacing.sm)

            VStack(spacing: 0) {
                ForEach(Array(contacts.enumerated()), id: \.offset) { index, contact in
                    ContactRow(
                        initial: contact.initial,
                        titleKey: contact.name,
                        captionKey: contact.phone,
                        isEditable: false
                    )
                    .frame(minHeight: 70)
                    
                    if index != contacts.count - 1 {
                        AppDivider()
                            .padding(.horizontal, AppSpacing.md)
                    }
                }
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        }
    }

    func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "d MMMM, h:mma"
        return f.string(from: date)
    }
}

#Preview {
    HistoryTripDetailsTemplate(
        tripName: "27 May Trip",
        alertSent: false,
        startTime: Date(),
        returnTime: Date().addingTimeInterval(3600 * 8),
        destination: "Al Thumamah",
        isGroup: true,
        groupCount: 3,
        carDetails: "White Toyota",
        plateNumber: "ABC 1234",
        distance: "45 KM",
        emergencyContacts: [
            (initial: "A", name: "Ahmed", phone: "+966501234567")
        ],
        groupContacts: [
            (initial: "F", name: "Faisal", phone: "+966507654321")
        ], hasActiveTrip: true
    )
}
