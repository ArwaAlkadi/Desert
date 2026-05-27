//
//  VehicleDetailsTemplate.swift
//  Desert
//
//  Created by Samar A on 08/12/1447 AH.
//

//استبدلت الستيت بالفيو مودلز

import SwiftUI

struct VehicleDetailsTemplate: View {

    @ObservedObject var vm: TripsViewModel

    var body: some View {

        ScrollView(showsIndicators: false) {

            VStack(spacing: AppSpacing.lg) {
                carModelSection
                carColorSection
                fourWheelDriveSection
                plateInfoSection
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, AppSpacing.sm)
            .padding(.bottom, AppSpacing.xxl)
            .padding(.horizontal, AppSpacing.lg)
        }
        .background(Color.Background)
    }
}

// MARK: - Sections

private extension VehicleDetailsTemplate {

    var carModelSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {

            Text("vehicle.carModel".localized)
                .font(AppTypography.headline)
                .foregroundStyle(Color.Primary)

            AppTextField(
                placeholderKey: "vehicle.carModel.placeholder",
                text: $vm.carModel,
                state: vm.showStep1Errors && !vm.carModelIsValid ? .error : .normal
            )
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))

            if vm.showStep1Errors && !vm.carModelIsValid {
                ErrorMessageRow(messageKey: "car_model_required")
            }
        }
    }

    var carColorSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {

            Text("vehicle.carColor".localized)
                .font(AppTypography.headline)
                .foregroundStyle(Color.Primary)

            ColorPickerRow(
                placeholderKey: "vehicle.color.placeholder",
                selectedColorKey: $vm.selectedColor
            )

            if vm.showStep1Errors && !vm.selectedColorIsValid {
                ErrorMessageRow(messageKey: "car_color_required")
            }
        }
    }

    var fourWheelDriveSection: some View {
        InquiryRow(
            titleKey: "vehicle.isFourWheelDrive",
            isOn: $vm.isFourWheelDrive
        )
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }

    var plateInfoSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {

            Text("vehicle.plateInfo".localized)
                .font(AppTypography.headline)
                .foregroundStyle(Color.Primary)

            PlateInfoRow(
                firstLetter: $vm.firstPlateLetter,
                secondLetter: $vm.secondPlateLetter,
                thirdLetter: $vm.thirdPlateLetter,
                digits: $vm.plateDigits
            )
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))

            if vm.showStep1Errors && (!vm.plateLettersIsValid || !vm.plateNumbersIsValid) {
                ErrorMessageRow(messageKey: "plate_required")
            }
        }
    }
}

#Preview {
    VehicleDetailsTemplate(vm: TripsViewModel())
}
