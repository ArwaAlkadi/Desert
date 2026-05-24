//
//  WelcomeView.swift
//  Desert
//
//  Shown at the bottom of the map when no active trip exists.
//  Prompts the user to start a new trip.
//

import SwiftUI

struct WelcomeCard: View {

    var onStartTrip: () -> Void

    var body: some View {
        VStack(spacing: 16) {

            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.primary)
                        .frame(width: 44, height: 44)
                    Image(systemName: "location.fill")
                        .foregroundColor(Color(UIColor.systemBackground))
                        .font(.system(size: 18))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("welcome_title".localized)
                        .font(.headline)
                    Text("welcome_subtitle".localized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            Button(action: {
                guard !TripSessionManager.shared.hasActiveTrip else { return }
                onStartTrip()
            }) {
                Text("start_new_trip".localized)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.primary)
                    .foregroundColor(Color(UIColor.systemBackground))
                    .cornerRadius(14)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -4)
    }
}
