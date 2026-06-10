//
//  MultiContactPickerView.swift
//  Desert
//
//  Wraps CNContactPickerViewController for multi-contact selection.
//  Used for group members — multiple contacts at once.
//

import SwiftUI
import ContactsUI

struct MultiContactPickerView: UIViewControllerRepresentable {

    // MARK: - Input

    var onSelect: ([CNContact]) -> Void

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

        var onSelect: ([CNContact]) -> Void

        init(onSelect: @escaping ([CNContact]) -> Void) {
            self.onSelect = onSelect
        }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
            onSelect(contacts)
        }
    }
}
