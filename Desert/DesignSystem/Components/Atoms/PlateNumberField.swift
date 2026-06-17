//
//  PlateNumberField.swift
//  Desert
//
//  Created by Samar A on 07/12/1447 AH.
//


import SwiftUI
import UIKit

struct PlateNumberFields: View {
    
    @Binding var digits: [String]
    @State private var focusedIndex: Int? = nil
    
    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            ForEach(0..<4, id: \.self) { index in
                BackspaceDetectingTextField(
                    text: binding(for: index),
                    placeholder: "-",
                    index: index,
                    focusedIndex: $focusedIndex,
                    onBackspaceWhenEmpty: {
                        if index > 0 {
                            digits[index - 1] = ""
                            focusedIndex = index - 1
                        }
                    }
                )
                .font(AppTypography.body)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.sm)
                        .stroke(Color.Grey100, lineWidth: 1)
                )
            }
        }
        .environment(\.layoutDirection, .leftToRight)
        .onAppear {
            if digits.count != 4 {
                digits = ["", "", "", ""]
            }
        }
    }
    
    private func binding(for index: Int) -> Binding<String> {
        Binding(
            get: { digits[index] },
            set: { newValue in
                digits[index] = String(newValue.filter { $0.isNumber }.prefix(1))
            }
        )
    }
}

private struct BackspaceDetectingTextField: UIViewRepresentable {
    
    @Binding var text: String
    
    var placeholder: String
    var index: Int
    @Binding var focusedIndex: Int?
    var onBackspaceWhenEmpty: () -> Void
    
    func makeUIView(context: Context) -> BackspaceTextField {
        let textField = BackspaceTextField()
        textField.delegate = context.coordinator
        textField.placeholder = placeholder
        textField.textAlignment = .center
        textField.semanticContentAttribute = .forceLeftToRight
        textField.keyboardType = .numberPad
        textField.onBackspaceWhenEmpty = onBackspaceWhenEmpty
        return textField
    }
    
    func updateUIView(_ uiView: BackspaceTextField, context: Context) {
        context.coordinator.parent = self
        
        if uiView.text != text {
            uiView.text = text
        }
        
        uiView.onBackspaceWhenEmpty = onBackspaceWhenEmpty
        
        if focusedIndex == index, !uiView.isFirstResponder {
            uiView.becomeFirstResponder()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: BackspaceDetectingTextField
        
        init(_ parent: BackspaceDetectingTextField) {
            self.parent = parent
        }
        
        func textFieldDidBeginEditing(_ textField: UITextField) {
            parent.focusedIndex = parent.index
        }
        
        func textField(
            _ textField: UITextField,
            shouldChangeCharactersIn range: NSRange,
            replacementString string: String
        ) -> Bool {
            
            if string.isEmpty {
                if parent.text.isEmpty {
                    parent.onBackspaceWhenEmpty()
                } else {
                    parent.text = ""
                }
                return false
            }
            
            guard let digit = string.filter({ $0.isNumber }).last else {
                return false
            }
            
            parent.text = String(digit)
            
            if parent.index < 3 {
                parent.focusedIndex = parent.index + 1
            }
            
            return false
        }
    }
}

private final class BackspaceTextField: UITextField {
    
    var onBackspaceWhenEmpty: (() -> Void)?
    
    override func deleteBackward() {
        if text?.isEmpty ?? true {
            onBackspaceWhenEmpty?()
            return
        }
        
        super.deleteBackward()
    }
}

#Preview {
    PlateNumberFields(
        digits: .constant(["4", "3", "", ""])
    )
    .padding()
}
