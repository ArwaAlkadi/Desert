//
//  NavigationHelper.swift
//  Desert
//

import SwiftUI

// MARK: - App Page

/// The two root tabs in the app.
enum AppPage {
    case map
    case history
}

// MARK: - onTripStarted Environment Key

/// Passes a "navigate to map" callback down the view hierarchy via the SwiftUI environment.
/// Allows deeply nested views (e.g. `TripSummaryView`) to trigger root-level navigation.
struct OnTripStartedKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

extension EnvironmentValues {
    var onTripStarted: () -> Void {
        get { self[OnTripStartedKey.self] }
        set { self[OnTripStartedKey.self] = newValue }
    }
}

// MARK: - Swipe Back Fix

/// Re-enables the interactive pop gesture after SwiftUI disables it in some navigation setups.
extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    /// Allows swipe-back only when there is more than one view controller in the stack.
    public func gestureRecognizerShouldBegin(
        _ gestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        viewControllers.count > 1
    }
}

// MARK: - Swipe Back Disabler

/// Disables the interactive pop gesture for views that shouldn't be swiped away.
/// Add to the view hierarchy via `.background(NavigationGestureDisabler())`.
struct NavigationGestureDisabler: UIViewControllerRepresentable {

    func makeUIViewController(context: Context) -> UIViewController {
        DisablerViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    class DisablerViewController: UIViewController {

        /// Disables swipe-back when this view appears.
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        }

        /// Re-enables swipe-back when leaving so it works normally in parent views.
        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        }
    }
}
