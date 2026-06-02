//
//  TripTrackTemplate.swift
//  Desert
//
//  Created by Samar A on 11/12/1447 AH.
//

// هنا اضفت زر الفيديو واضفت متغيرات ناقصة .. ازرار الفيديو تحتاج ديزاين

import SwiftUI
import MapKit

struct TripTrackTemplate<MapContent: View>: View {

    var isReplaying: Bool
    var mapContent: () -> MapContent

    var onBack: () -> Void
    var onReset: () -> Void
    var onToggleReplay: () -> Void

    var body: some View {
        ZStack(alignment: .top) {

            mapContent()
                .ignoresSafeArea()

            HeaderView(
                titleKey: "history.tripTrack",
                leadingButton: .back,
                action: onBack
            )
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, 68)
            .padding(.bottom, AppSpacing.sm)
            .background(
                LinearGradient(
                    colors: [
                        Color.Background.opacity(0.95),
                        Color.Background.opacity(0.75),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea(edges: .top)
            )

            VStack {
                Spacer()

                HStack(spacing: 16) {

                    Button {
                        onReset()
                    } label: {
                        Image(systemName: "backward.end.fill")
                            .foregroundColor(Color.Primary)
                            .frame(width: 52, height: 52)
                            .background(Color.white.opacity(0.95))
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 4)
                    }

                    Button {
                        onToggleReplay()
                    } label: {
                        Image(systemName: isReplaying ? "stop.fill" : "play.fill")
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Color.Primary)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.16), radius: 12, x: 0, y: 5)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .environment(\.layoutDirection, .leftToRight)
    }
}

#Preview {
    TripTrackTemplate(
        isReplaying: false,
        mapContent: {
            Image("tripMap")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        },
        onBack: {},
        onReset: {},
        onToggleReplay: {}
    )
}
