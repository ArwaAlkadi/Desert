//
//  AppTypography.swift
//  Desert
//
//  Created by Samar A on 03/12/1447 AH.
//

import SwiftUI

enum AppTypography {

    private static var isEnglish: Bool {

           Locale.current.language.languageCode?.identifier == "en"

       }
       private static func arabicFontName(for weight: Font.Weight) -> String {

           switch weight {

           case .bold:

               return "thmanyah sans-Bold"

           case .semibold, .medium:

               return "thmanyah sans-Medium"

           case .light:

               return "thmanyah sans-Light"

           case .black, .heavy:

               return "thmanyahsans-Black"

           default:

               return "thmanyahsans-Regular"

           }

       }

       private static func font(

           _ style: Font.TextStyle,

           weight: Font.Weight = .regular

       ) -> Font {

           if isEnglish {

               return .system(style, design: .default)

                   .weight(weight)

           } else {

               return .custom(

                   arabicFontName(for: weight),

                   size: UIFont.preferredFont(

                       forTextStyle: uiTextStyle(style)

                   ).pointSize,

                   relativeTo: style

               )

           }

       }

    private static func uiTextStyle(_ style: Font.TextStyle) -> UIFont.TextStyle {

        switch style {
        case .largeTitle: return .largeTitle
        case .title: return .title1
        case .title2: return .title2
        case .title3: return .title3
        case .headline: return .headline
        case .callout: return .callout
        case .subheadline: return .subheadline
        case .footnote: return .footnote
        case .caption: return .caption1
        case .caption2: return .caption2
        default: return .body
        }
    }

    static let largeTitle = font(.largeTitle, weight: .bold)
    static let title1 = font(.title, weight: .bold)
    static let title2 = font(.title2, weight: .bold)
    static let title3 = font(.title3, weight: .bold)

    static let headline = font(.headline, weight: .semibold)
    static let body = font(.body)
    static let callout = font(.callout)
    static let subheadline = font(.subheadline)

    static let footnote = font(.footnote)
    static let footnoteSemibold = font(.footnote, weight: .semibold)

    static let caption = font(.caption)
    static let caption2 = font(.caption2)
    static let caption2Semibold = font(.caption2, weight: .semibold)
}

