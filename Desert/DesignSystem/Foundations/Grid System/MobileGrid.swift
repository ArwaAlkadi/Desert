//
//  MobileGrid.swift
//  Desert
//
//  Created by Samar A on 10/12/1447 AH.
//

import SwiftUI

enum MobileGrid {
    
    static let columns: Int = 5
    static let horizontalMargin: CGFloat = 16
    static let gutter: CGFloat = 20
    
    
    // Vertical Spacing
    
    static let sectionSpacing: CGFloat = 24
    static let contentSpacing: CGFloat = 16
    static let cardSpacing: CGFloat = 12
    
    // Components
    
    static let buttonHeight: CGFloat = 52
    static let textFieldHeight: CGFloat = 52
    static let cardRadius: CGFloat = 20
    
}


struct GridOverlay: View {

    var body: some View {

        GeometryReader { geo in

            let totalGutter =
                CGFloat(MobileGrid.columns - 1) * MobileGrid.gutter

            let totalMargins =
                MobileGrid.horizontalMargin * 2

            let columnWidth =
                (geo.size.width - totalMargins - totalGutter)
                / CGFloat(MobileGrid.columns)

            HStack(spacing: MobileGrid.gutter) {

                ForEach(0..<MobileGrid.columns, id: \.self) { _ in

                    Color.red.opacity(0.08)
                        .frame(width: columnWidth)
                }
            }
            .padding(.horizontal, MobileGrid.horizontalMargin)
            .ignoresSafeArea()
        }
        .allowsHitTesting(false)
    }
}
