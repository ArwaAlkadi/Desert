//
//  TextFieldState.swift
//  Desert
//
//  Created by Samar A on 07/12/1447 AH.
//

import SwiftUI

enum AppTextFieldState {
    case normal
    case focused
    case filled
    case error
    case disabled
}

enum PhoneError {
    case required
    case invalid

    var messageKey: String {
        switch self {
        case .required: return "phone_required"
        case .invalid:  return "phone_invalid"
        }
    }
}

struct AppTextField: View {

    var placeholderKey: String

    @Binding var text: String

    var state: AppTextFieldState = .normal

    @Environment(\.layoutDirection)
    private var layoutDirection

    @FocusState
    private var isFocused: Bool

    var body: some View {

        VStack(spacing: AppSpacing.sm) {

            HStack {

                TextField(
                    placeholderKey.localized,
                    text: $text
                )
                .font(AppTypography.body)
                .foregroundStyle(textColor)
                .focused($isFocused)
                .disabled(state == .disabled)
                .multilineTextAlignment(textAlignment)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: layoutDirection == .rightToLeft ? .trailing : .leading)

                trailingIcon
            }
            .padding(.horizontal, AppSpacing.md)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
        }
    }
}

private extension AppTextField {

    var textAlignment: TextAlignment {

        layoutDirection == .rightToLeft
        ? .trailing
        : .leading
    }

    var textColor: Color {

        state == .disabled
        ? Color.Disabled
        : Color.Primary
    }

    var dividerColor: Color {

        switch state {

        case .focused:
            return Color.Secondary

        case .error:
            return Color.Destructive

        case .disabled:
            return Color.Disabled

        default:
            return Color.Grey100
        }
    }

    var resolvedState: AppTextFieldState {
        if state == .error {
            return .error
        }
        if state == .disabled {
            return .disabled
        }
        if isFocused && !text.isEmpty {
            return .filled
        }
        if isFocused {
            return .focused
        }
        return .normal
    }

    @ViewBuilder
    var trailingIcon: some View {

        switch resolvedState {

        case .filled:

            Button {

                text = ""

            } label: {

                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(Color.Primary)
            }

        case .error:

            EmptyView()

        default:

            EmptyView()
        }
    }
}

#Preview {

    VStack(spacing: 20) {

        AppTextField(
            placeholderKey: "textfield.value",
            text: .constant(""),
            state: .normal
        )

        AppTextField(
            placeholderKey: "textfield.value",
            text: .constant("Value"),
            state: .focused
        )

        AppTextField(
            placeholderKey: "textfield.value",
            text: .constant("Value"),
            state: .filled
        )

        AppTextField(
            placeholderKey: "textfield.value",
            text: .constant("Value"),
            state: .error
        )

        AppTextField(
            placeholderKey: "textfield.value",
            text: .constant("Value"),
            state: .disabled
        )
        
        
    }
    .padding()
}
