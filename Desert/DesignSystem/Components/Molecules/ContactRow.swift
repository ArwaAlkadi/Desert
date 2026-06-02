//
//  ContactRow.swift
//  Desert
//
//  Created by Samar A on 07/12/1447 AH.
//

import SwiftUI

struct ContactRow: View {

    var initial: String
    var titleKey: String
    var captionKey: String
    var isEditable: Bool = true

    var deleteAction: (() -> Void)? = nil

    @State private var offsetX: CGFloat = 0
    @State private var showDeleteConfirmation = false

    private let deleteWidth: CGFloat = 72
    private let fullSwipeDeleteWidth: CGFloat = 150

    var body: some View {

        ZStack(alignment: .trailing) {
            if isEditable {
                deleteButton
            }

            rowContent
                .offset(x: offsetX)
                .gesture(isEditable ? swipeGesture : nil)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 68)
        .clipped()
        .confirmationDialog(
            "contact.delete.title".localized,
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("common.delete".localized, role: .destructive) {
                deleteAction?()
                offsetX = 0
            }

            Button("common.cancel".localized, role: .cancel) {
                withAnimation(.spring()) {
                    offsetX = 0
                }
            }
        } message: {
            Text("contact.delete.message".localized)
        }
    }
}

private extension ContactRow {

    var deleteButton: some View {
        Button(role: .destructive) {
            showDeleteConfirmation = true
        } label: {
            Text("common.delete".localized)
                .font(AppTypography.caption2)
                .foregroundStyle(.white)
                .frame(width: deleteWidth, height: 68)
                .background(Color.Destructive)
        }
        .buttonStyle(.plain)
        .opacity(offsetX < 0 ? 1 : 0)
    }

    var rowContent: some View {
        HStack(spacing: 10) {

            AvatarCircle(initial: initial)

            VStack(alignment: .leading, spacing: AppSpacing.sx) {
                Text(titleKey.localized)
                    .font(AppTypography.body)
                    .foregroundStyle(Color.Primary)

                Text(captionKey.localized)
                    .font(AppTypography.footnote)
                    .foregroundStyle(Color.Disabled)
            }

            Spacer(minLength: 2)

            if isEditable {
                Button {
                    withAnimation(.spring()) {
                        offsetX = -deleteWidth
                    }
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color.Disabled.opacity(0.6))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .frame(maxWidth: .infinity)
        .frame(height: 68)
        .background(Color.white)
    }

    var swipeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                let newOffset = value.translation.width

                if newOffset < 0 {
                    offsetX = max(newOffset, -fullSwipeDeleteWidth)
                }
            }
            .onEnded { value in
                if value.translation.width <= -fullSwipeDeleteWidth {
                    withAnimation(.spring()) {
                        offsetX = -fullSwipeDeleteWidth
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        showDeleteConfirmation = true
                    }
                    return
                }

                withAnimation(.spring()) {
                    if value.translation.width < -35 {
                        offsetX = -deleteWidth
                    } else {
                        offsetX = 0
                    }
                }
            }
    }
}

#Preview {

    VStack(spacing: 24) {

        VStack(spacing: 0) {

            ContactRow(
                initial: "A",
                titleKey: "Abeer",
                captionKey: "+966 50 123 4567",
                isEditable: true
            ) {
                print("Deleted")
            }

            AppDivider()

            ContactRow(
                initial: "F",
                titleKey: "Fajer",
                captionKey: "+966 55 987 6543",
                isEditable: true
            ) {
                print("Deleted")
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))

        VStack(spacing: 0) {

            ContactRow(
                initial: "D",
                titleKey: "Dad",
                captionKey: "+966 54 111 2222",
                isEditable: false
            )

            AppDivider()

            ContactRow(
                initial: "O",
                titleKey: "Omar",
                captionKey: "+966 56 333 4444",
                isEditable: false
            )
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }
    .padding()
    .background(Color.Background)
}
