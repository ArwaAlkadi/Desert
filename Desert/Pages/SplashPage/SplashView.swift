//
//  SplashView.swift
//  Desert
//
//  Entry screen shown on first app launch.
//  Automatically transitions to Onboarding or Home after 2 seconds.
//

import SwiftUI

struct SplashView: View {

    // MARK: - Input

    @Binding var showSplash: Bool

    // MARK: - Private

    private let vm = SplashViewModel()

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "location.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
                Text("app_name".localized)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
        }
        .onAppear {
            vm.startTimer { showSplash = false }
        }
    }
}

// MARK: - Preview

#Preview {
    SplashView(showSplash: .constant(true))
}
