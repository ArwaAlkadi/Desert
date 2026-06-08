//
//  DateTimePickerSheet.swift
//  Desert
//
//  Created by Samar A on 20/12/1447 AH.
//

import SwiftUI

struct DateTimePickerSheet: View {

    @Binding var selectedDate: Date

    var body: some View {

        VStack(spacing: AppSpacing.md) {

            DatePicker(
                "",
                selection: Binding(
                    get: { selectedDate },
                    set: { newDate in
                        selectedDate = merge(date: newDate, time: selectedDate)
                    }
                ),
                in: Calendar.current.startOfDay(for: Date())...,
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
            .labelsHidden()
            .tint(Color.Secondary02)

            AppDivider()

            HStack {

                Text("activeTrip.time".localized)
                    .font(AppTypography.headline)
                    .foregroundStyle(Color.Primary)

                Spacer()

                DatePicker(
                    "",
                    selection: Binding(
                        get: { selectedDate },
                        set: { newTime in
                            selectedDate = merge(date: selectedDate, time: newTime)
                        }
                    ),
                    displayedComponents: [.hourAndMinute]
                )
                .labelsHidden()
                .tint(Color.Secondary02)
            }
        }
        .padding(AppSpacing.lg)
        .background(Color.white)
    }

    private func merge(date: Date, time: Date) -> Date {

        let calendar = Calendar.current

        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)

        var components = DateComponents()
        components.year = dateComponents.year
        components.month = dateComponents.month
        components.day = dateComponents.day
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute

        return calendar.date(from: components) ?? selectedDate
    }
}

#Preview {

    DateTimePickerSheet(
        selectedDate: .constant(Date())
    )
}
