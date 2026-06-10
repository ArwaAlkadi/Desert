//
//  KeyboardHelpers.swift
//  Desert
//

import SwiftUI
import UIKit

extension View {

    /// Dismisses the keyboard by resigning the first responder.
    func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}
