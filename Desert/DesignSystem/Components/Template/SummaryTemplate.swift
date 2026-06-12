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
    var onTermsTapped: () -> Void = {}

    @Binding var isLoading: Bool

    var body: some View {
        CreateTripStepTemplate(
            titleKey: "summary.title",
            currentStep: 3,
            buttonTitleKey: isLoading
                ? "summary.creatingTrip"
                : "summary.startNewTrip",
            isLoading: isLoading,
            leadingButton: .back,
            showsProgressBar: false,
            isInputFocused: false,
            onBack: {
                onBack()
            },
            onNext: {
                guard isConnected && !isLoading else { return }
                isLoading = true
                onStartTrip()
            }
        ) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    tripNameSection
                    emergencyContactsSection
                    groupContactSection
                    warningCard
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 0)
                .padding(.bottom, AppSpacing.xxl)
                .padding(.horizontal, AppSpacing.md)
            }
        }
    }
}








private extension SummaryTemplate {

    var tripNameSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(tripName)
                .font(AppTypography.headline)
                .foregroundStyle(Color.Lableblack)

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
                    ? String.localizedStringWithFormat(
                        NSLocalizedString("people.count", tableName: "PluralStrings", comment: ""),
                        groupCount
                      )
                    : "solo".localized
            )
        ])
    }

    var emergencyContactsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sx) {
            Text("summary.emergencyContacts".localized)
                .font(AppTypography.headline)
                .foregroundStyle(Color.Lableblack)

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
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("summary.groupContactOptional".localized)
                    .font(AppTypography.headline)
                    .foregroundStyle(Color.Lableblack)

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
        
        (
            Text("summary.warningPrefix".localized)
                .foregroundStyle(Color.Positive)
            +
            Text(" ")
            +
            Text("summary.termsAndConditions".localized)
                .foregroundStyle(Color.Positive)
                .underline()
            +
            Text("summary.warningSuffix".localized)
                .foregroundStyle(Color.Positive)
        )
        .font(AppTypography.caption2)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.PositiveBg)
        .clipShape(
            RoundedRectangle(cornerRadius: AppRadius.md)
        )
        .onTapGesture {
            onTermsTapped()
        }
    }
    

    func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: Locale.current.language.languageCode?.identifier == "ar" ? "ar_SA" : "en_US")
        f.dateFormat = "d MMMM, h:mma"
        return f.string(from: date)
    }
}

#Preview {
    SummaryTemplate(
        tripName: "Weekend Camp",
        startTime: Date(),
        returnTime: Date().addingTimeInterval(3600 * 8),
        destination: "Al Thumamah",
        carDetails: "White Toyota",
        plateNumber: "ABC 1234",
        isGroup: true,
        groupCount: 3,
        emergencyContacts: [
            Contact(name: "Om Saqr", phone: "+966 5X XXX XXXX"),
            Contact(name: "Fajer", phone: "+966 5X XXX XXXX")
        ],
        groupContacts: [
            Contact(name: "Saqr", phone: "+966 5X XXX XXXX")
        ],
        isConnected: true,
        onBack: {},
        onStartTrip: {},
        isLoading: .constant(false)
    )
}
