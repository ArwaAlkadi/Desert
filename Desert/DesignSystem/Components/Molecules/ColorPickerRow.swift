//
//  ColorPickerRow.swift
//  Desert
//
//  Created by Samar A on 08/12/1447 AH.
//


// هنا اضفت الالوان بحيث تكون مع الكومبونت مرة وحدة بنفس طريقة لوحة السيارة

import SwiftUI

struct ColorPickerRow: View {

    var placeholderKey: String

    @Binding var selectedColorKey: String

    private let options: [String] = [
        "vehicle.color.black",
        "vehicle.color.white",
        "vehicle.color.grey",
        "vehicle.color.red",
        "vehicle.color.orange",
        "vehicle.color.yellow",
        "vehicle.color.blue",
        "vehicle.color.green"
    ]

    var body: some View {

        Menu {

            ForEach(options, id: \.self) { colorKey in

                Button(colorKey.localized) {
                    selectedColorKey = colorKey
                }
            }

        } label: {

            HStack {

                Text(selectedColorKey.isEmpty ? placeholderKey.localized : selectedColorKey.localized)
                    .font(AppTypography.body)
                    .foregroundStyle(textColor)

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.Primary)
            }
            .padding(.horizontal, AppSpacing.md)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        }
        .buttonStyle(.plain)
    }
}

private extension ColorPickerRow {

    var textColor: Color {

        selectedColorKey.isEmpty
        ? Color.Disabled
        : Color.Primary
    }
}

#Preview {

    ColorPickerRow(
        placeholderKey: "vehicle.color.placeholder",
        selectedColorKey: .constant("")
    )
    .padding()
}
