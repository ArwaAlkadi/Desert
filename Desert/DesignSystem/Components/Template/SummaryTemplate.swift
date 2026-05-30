//
//  SummaryTemplate.swift
//  Desert
//
//  Created by Samar A on 10/12/1447 AH.
//

import SwiftUI

struct SummaryTemplate: View {

    var tripName: String
    var startTime: Date
    var returnTime: Date
    var destination: String
    var carDetails: String
    var plateNumber: String
    var isGroup: Bool
    var groupCount: Int
    var emergencyContacts: [Contact]
    var groupContacts: [Contact]
    var isConnected: Bool = true
    var onBack: () -> Void = {}
    var onStartTrip: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            HeaderView(
                titleKey: "summary.title",
                leadingButton: .back,
                action: { onBack() }
            )
            .padding(.top, 0)
            .padding(.bottom, 28)
            .padding(.horizontal, 75)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    tripNameSection
                        .padding(.horizontal, AppSpacing.xxl)

                    emergencyContactsSection
                        .padding(.horizontal, AppSpacing.xxl)

                    groupContactSection
                        .padding(.horizontal, AppSpacing.xxl)

                    warningCard
                        .padding(.horizontal, AppSpacing.xxl)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.sm)
                .padding(.bottom, 120)
            }
        }
        .background(Color.Background)
        .environment(\.layoutDirection, .leftToRight)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                CTAButton(
                    title: "summary.startNewTrip".localized,
                    style: isConnected ? .primary : .disabled
                ) {
                    onStartTrip()
                }
                .disabled(true) //موقتا لين نحل المشكلة
                .padding(.horizontal, AppSpacing.xxl)
                .padding(.top, AppSpacing.lg)
                .padding(.bottom, AppSpacing.sm)
            }
            .background(Color.Background)
        }
    }
}








private extension SummaryTemplate {

    var tripNameSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(tripName)
                .font(AppTypography.headline)
                .foregroundStyle(Color.Primary)

            tripSummaryCard
        }
    }

    var tripSummaryCard: some View {
        TripSummaryCard(rows: [
            ("summary.startTime", formatDate(startTime)),
            ("summary.returnTime", formatDate(returnTime)),
            ("summary.destination", destination.isEmpty ? "—" : destination),
            ("summary.carDetails", carDetails.isEmpty ? "—" : carDetails),
            ("summary.plateNumber", plateNumber.isEmpty ? "—" : plateNumber),
            (
                "summary.numberOfIndividuals",
                isGroup
                    ? String(format: "people_count".localized, groupCount)
                    : "solo".localized
            )
        ])
    }

    var emergencyContactsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("summary.emergencyContacts".localized)
                .font(AppTypography.headline)
                .foregroundStyle(Color.Primary)

            VStack(spacing: 0) {
                ForEach(emergencyContacts, id: \.name) { contact in
                    ContactRow(
                        initial: String(contact.name.prefix(1)),
                        titleKey: contact.name,
                        captionKey: contact.phone,
                        isEditable: false
                    )
                    .frame(height: 70)

                    if contact.name != emergencyContacts.last?.name {
                        AppDivider()
                            .padding(.horizontal, AppSpacing.md)
                    }
                }
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        }
    }

    @ViewBuilder
    var groupContactSection: some View {
        if isGroup && !groupContacts.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("summary.groupContactOptional".localized)
                    .font(AppTypography.headline)
                    .foregroundStyle(Color.Primary)

                VStack(spacing: 0) {
                    ForEach(groupContacts, id: \.name) { contact in
                        ContactRow(
                            initial: String(contact.name.prefix(1)),
                            titleKey: contact.name,
                            captionKey: contact.phone,
                            isEditable: false
                        )
                        .frame(height: 70)

                        if contact.name != groupContacts.last?.name {
                            AppDivider()
                                .padding(.horizontal, AppSpacing.md)
                        }
                    }
                }
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
            }
        }
    }

    var warningCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.Secondary02)
                .padding(.top, 2)

            Text("summary.warningMessage".localized)
                .font(AppTypography.caption)
                .foregroundStyle(Color.Primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.Secondary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "d MMMM, h:mma"
        return f.string(from: date)
    }
}

#Preview {
    SummaryTemplate(
        tripName: "27 May Trip",
        startTime: Date(),
        returnTime: Date().addingTimeInterval(3600 * 8),
        destination: "Al Thumamah",
        carDetails: "White Toyota",
        plateNumber: "ABC 1234",
        isGroup: true,
        groupCount: 3,
        emergencyContacts: [],
        groupContacts: []
    )
}
