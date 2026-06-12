//
//  DateRangeRow.swift
//  Desert
//
//  Created by Samar A on 07/12/1447 AH.
//

import SwiftUI

struct DateRangeRow: View {

    var startLabelKey: String
    @Binding var startDate: Date

    var endLabelKey: String
    @Binding var returnTime: Date

    var isEndRequired: Bool = false

    var displayedComponents: DatePickerComponents = [.date, .hourAndMinute]
    var compactStyle: Bool = false

    @State private var showDatePicker = false


    var body: some View {

        HStack(alignment: .center) {

            // Start date — not tappable
            LabelValueItem(
                labelKey: startLabelKey,
                value: startDate.formattedDateTime,
                isDisabled: true
            )
            .frame(maxWidth: .infinity)

            Rectangle()
                .fill(Color.Grey100)
                .frame(width: 1)
                .frame(maxHeight: .infinity)
            // End date — tappable
            Button {
                showDatePicker = true
            } label: {
                LabelValueItem(
                    labelKey: endLabelKey,
                    value: returnTime.formattedDateTime,
                    isRequired: isEndRequired
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(Color.white)
        .cornerRadius(AppRadius.md)
        
        
        .sheet(isPresented: $showDatePicker) {
            DateTimePickerSheet(selectedDate: $returnTime)
                .environment(\.calendar, Calendar(identifier: .gregorian))
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }
        
    }


private struct LabelValueItem: View {

    var labelKey: String
    var value: String
    var isRequired: Bool = false
    var isDisabled: Bool = false

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: AppSpacing.sm
        ) {

            HStack(spacing: 4) {

                Text(labelKey.localized)
                    .font(AppTypography.footnote)
                    .foregroundStyle(Color.Disabled)

                if isRequired {

                    Text("*")
                        .font(AppTypography.footnote)
                        .foregroundStyle(Color.Destructive)
                }
            }

            Text(value)
                .font(AppTypography.footnote)
                .foregroundStyle(isDisabled ? Color.Disabled : Color.Primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private extension Date {

    var formattedDateTime: String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: AppLanguage.isArabic ? "ar_SA" : "en_US")
        formatter.dateFormat = AppLanguage.isArabic
            ? "d MMM yyyy، h:mm a"
            : "d MMM yyyy, h:mm a"

        return formatter.string(from: self)
    }
}

#Preview {

    DateRangeRow(
        startLabelKey: "date.start",
        startDate: .constant(Date()),
        endLabelKey: "date.end",
        returnTime: .constant(Date().addingTimeInterval(3600)),
        isEndRequired: true
    )
    .padding()
}
