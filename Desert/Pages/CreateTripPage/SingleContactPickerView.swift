//
//  SingleContactPickerView.swift
//  Desert
//
//  Wraps CNContactPickerViewController for single-contact selection.
//  Used for emergency contacts — one contact at a time.
//

import SwiftUI
import ContactsUI

struct SingleContactPickerView: UIViewControllerRepresentable {

    // MARK: - Input

    var onSelect: (CNContact) -> Void

    // MARK: - UIViewControllerRepresentable

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onSelect: onSelect) }

    // MARK: - Coordinator

    class Coordinator: NSObject, CNContactPickerDelegate {

        var onSelect: (CNContact) -> Void

        init(onSelect: @escaping (CNContact) -> Void) {
            self.onSelect = onSelect
        }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            onSelect(contact)
        }
    }
}
