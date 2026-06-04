//
//  Divider.swift
//  Desert
//
//  Created by Samar A on 05/12/1447 AH.
//
import SwiftUI

struct AppDivider: View {

    var body: some View {

        Capsule()
            .fill(Color.Grey100)
            .frame(maxWidth: .infinity)
            .frame(height: 1)
    }
}

#Preview {

    AppDivider()
        .padding()
}
