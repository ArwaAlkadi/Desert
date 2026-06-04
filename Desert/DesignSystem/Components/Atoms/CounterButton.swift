//
//  CounterButton.swift
//  Desert
//
//  Created by Samar A on 07/12/1447 AH.
//

import SwiftUI

struct CounterButton: View {

    enum Style {
        case add
        case remove
    }

    var style: Style
    var action: () -> Void

    var body: some View {

        Button(action: action) {

            Image(systemName: iconName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(backgroundColor)
                .clipShape(Circle())
        }
        .frame(minWidth: 44, minHeight: 44)
    }
}

private extension CounterButton {

    var iconName: String {
        style == .add ? "plus" : "minus"
    }

    var backgroundColor: Color {
        style == .add ? Color.Positive : Color.Destructive
    }
}

#Preview {
    VStack(spacing: 24) {
        CounterButton(style: .add) { }
        CounterButton(style: .remove) { }
    }
    .padding()
}
