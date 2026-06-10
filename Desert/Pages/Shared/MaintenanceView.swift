//
//  MaintenanceView.swift
//  Desert
//
//  Full-screen placeholder shown when maintenance mode is enabled in Firebase.
//

import SwiftUI

struct MaintenanceView: View {

    // MARK: - Input

    var title: String
    var message: String

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "wrench.and.screwdriver")
                .font(.system(size: 80))
                .foregroundColor(.secondary)

            Text(title)
                .font(.title2)
                .fontWeight(.bold)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemGroupedBackground))
    }
}
