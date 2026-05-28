//
//  SummaryTemplate.swift
//  Desert
//
//  Created by Samar A on 10/12/1447 AH.
//

import SwiftUI

struct SummaryTemplate: View {

    // Trip info — display only, no editing
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

    // State
    var isConnected: Bool = true
    var onBack: () -> Void = {}
    var onStartTrip: () -> Void = {}

    var body: some View {

        VStack(spacing: 0) {

            HeaderView(titleKey: "summary.title") {
                onBack()
            }
            .padding(.top, 0)
            .padding(.bottom, 28)
            .padding(.horizontal, AppSpacing.lg)

            ScrollView(showsIndicators: false) {

                VStack(alignment: .leading, spacing: 26) {
                    tripNameSection
                    emergencyContactsSection
                    groupContactSection
                    warningCard
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, AppSpacing.sm)
                .padding(.bottom, AppSpacing.xxl)
                .padding(.horizontal, AppSpacing.xxl)
            }
        }
        .background(Color.Background)
        .environment(\.layoutDirection, .leftToRight)
        .safeAreaInset(edge: .bottom) {
            CTAButton(
                title: "summary.startNewTrip".localized,
                style: isConnected ? .primary : .disabled
            ) {
                onStartTrip()
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.lg)
            .padding(.bottom, AppSpacing.sm)
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
        VStack(spacing: 0) {
            summaryRow(titleKey: "summary.startTime", value: formatDate(startTime))
            summaryDivider
            summaryRow(titleKey: "summary.returnTime", value: formatDate(returnTime))
            summaryDivider
            summaryRow(titleKey: "summary.destination", value: destination.isEmpty ? "—" : destination)
            summaryDivider
            summaryRow(titleKey: "summary.carDetails", value: carDetails.isEmpty ? "—" : carDetails)
            summaryDivider
            summaryRow(titleKey: "summary.plateNumber", value: plateNumber.isEmpty ? "—" : plateNumber)
            summaryDivider
            summaryRow(
                titleKey: "summary.numberOfIndividuals",
                value: isGroup
                    ? String(format: "people_count".localized, groupCount)
                    : "solo".localized
            )
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    var emergencyContactsSection: some View {
        VStack(alignment: .leading, spacing: 10) {

            Text("summary.emergencyContacts".localized)
                .font(AppTypography.headline)
                .foregroundStyle(Color.Primary)

            VStack(spacing: 0) {
                ForEach(emergencyContacts, id: \.name) { contact in
                    contactRow(name: contact.name, phone: contact.phone)

                    if contact.name != emergencyContacts.last?.name {
                        summaryDivider
                            .padding(.leading, 64)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 22))
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
                        contactRow(name: contact.name, phone: contact.phone)

                        if contact.name != groupContacts.last?.name {
                            summaryDivider
                                .padding(.leading, 64)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 22))
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

    var summaryDivider: some View {
        Divider()
            .background(Color.gray.opacity(0.25))
    }

    func summaryRow(titleKey: String, value: String) -> some View {
        HStack(spacing: 12) {
            Text(titleKey.localized)
                .font(AppTypography.body)
                .foregroundStyle(Color.Primary)
                .lineLimit(1)

            Spacer(minLength: 8)

            Text(value)
                .font(AppTypography.body)
                .foregroundStyle(Color.lableSec)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(height: 34)
    }

    func contactRow(name: String, phone: String) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.Secondary)
                .frame(width: 48, height: 48)
                .overlay {
                    Text(String(name.prefix(1)))
                        .font(AppTypography.body)
                        .foregroundStyle(Color.Primary)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(AppTypography.body)
                    .foregroundStyle(Color.Primary)

                Text(phone)
                    .font(AppTypography.caption)
                    .foregroundStyle(Color.lableSec)
            }

            Spacer(minLength: 0)
        }
        .frame(height: 58)
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
