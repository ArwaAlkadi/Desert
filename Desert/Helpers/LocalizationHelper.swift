//
//  LocalizationHelper.swift
//  Desert
//

import SwiftUI

// MARK: - String Localization

extension String {

    /// Returns the localized version of the string using `Localizable.strings`.
    var localized: String {
        NSLocalizedString(self, comment: "")
    }
}
