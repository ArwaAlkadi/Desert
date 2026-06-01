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

    @State private var showDeleteButton = false
    @State private var dragOffset: CGFloat = 0

    private let deleteRevealWidth: CGFloat = 72
    private let deleteTriggerWidth: CGFloat = 170
    private let maxSwipeWidth: CGFloat = 190

    var body: some View {

        ZStack(alignment: .trailing) {

            if isEditable {
                deleteButton
            }

            rowContent
                .offset(x: isEditable ? dragOffset : 0)
                .gesture(isEditable ? swipeGesture : nil)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 68)
    }
}

private extension ContactRow {

    var deleteButton: some View {
        Button {
            deleteAction?()
        } label: {
            Text("common.delete".localized)
                .font(AppTypography.caption)
                .foregroundStyle(.white)
                .frame(
                    width: max(abs(dragOffset), deleteRevealWidth),
                    height: 52
                )
                .background(Color.Destructive)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        }
        .buttonStyle(.plain)
        .opacity(dragOffset < 0 || showDeleteButton ? 1 : 0)
    }

    var rowContent: some View {
        HStack(spacing: AppSpacing.sm) {

            AvatarCircle(initial: initial)

            VStack(alignment: .leading, spacing: AppSpacing.sx) {
                Text(titleKey.localized)
                    .font(AppTypography.body)
                    .foregroundStyle(Color.Primary)

                Text(captionKey.localized)
                    .font(AppTypography.footnote)
                    .foregroundStyle(Color.Disabled)
            }

            Spacer(minLength: AppSpacing.sx)

            if isEditable {
                trashButton
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .frame(maxWidth: .infinity)
        .frame(height: 68)
    }

    var trashButton: some View {
        Button {
            withAnimation(.spring()) {
                showDeleteButton.toggle()
                dragOffset = showDeleteButton ? -deleteRevealWidth : 0
            }
        } label: {
            Image(systemName: "trash")
                .font(.system(size: 18))
                .foregroundStyle(Color.Disabled.opacity(0.5))
                .frame(width: 18, height: 21)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
    }

    var swipeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                let startOffset = showDeleteButton ? -deleteRevealWidth : 0
                let newOffset = startOffset + value.translation.width

                dragOffset = min(0, max(newOffset, -maxSwipeWidth))
            }
            .onEnded { value in
                let startOffset = showDeleteButton ? -deleteRevealWidth : 0
                let finalOffset = startOffset + value.translation.width

                if finalOffset <= -deleteTriggerWidth {
                    withAnimation(.spring()) {
                        showDeleteButton = true
                        dragOffset = -maxSwipeWidth
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        deleteAction?()
                    }
                    return
                }

                withAnimation(.spring()) {
                    if finalOffset < -40 {
                        showDeleteButton = true
                        dragOffset = -deleteRevealWidth
                    } else {
                        showDeleteButton = false
                        dragOffset = 0
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
