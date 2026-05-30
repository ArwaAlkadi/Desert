//
//  ActiveTripCard.swift
//  Desert
//
//  Created by Samar A on 12/12/1447 AH.
//

import SwiftUI

struct ActiveTripCard: View {
    
    enum ActivePicker {
        case date
        case time
    }
    
    var tripName: String = "Desert Trip"
    var daysLeft: String = "4 days left"
    var isUploaded: Bool = true
    var returnTime: Date = Date()
    var isOverdue: Bool = false

    
    var emergencyContacts: [Contact] = []
    
    var onUpdateReturnTime: (Date) -> Void = { _ in }
    var onEndTrip: () -> Void = {}
    
    @State private var isExpanded = false
    @State private var selectedReturnTime = Date()
    @State private var draftReturnTime = Date()
    @State private var activePicker: ActivePicker? = nil

    private var hasReturnTimeChanges: Bool {
        abs(draftReturnTime.timeIntervalSince(selectedReturnTime)) > 1
    }

    private var displayedReturnTime: Date {
        hasReturnTimeChanges ? draftReturnTime : selectedReturnTime
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            
            headerSection
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        isExpanded.toggle()
                    }
                }
            
            if isExpanded {
                returnTimeSection
                emergencyContactsSection
                endTripButton
            }
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.lg)
        .frame(maxWidth: UIScreen.main.bounds.width - 32, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 4)
        .onAppear {
            selectedReturnTime = returnTime
            draftReturnTime = returnTime
        }
        .onChange(of: returnTime) { _, newValue in
            selectedReturnTime = newValue
            draftReturnTime = newValue
        }
    }
}





private extension ActiveTripCard {
    
    var headerSection: some View {
        HStack(alignment: .top) {
            
            VStack(alignment: .leading, spacing: 6) {
                Text(tripName)
                    .font(AppTypography.body)
                    .foregroundStyle(Color.Primary)
                
                Text(daysLeft)
                    .font(AppTypography.title1)
                    .foregroundStyle(Color.Primary)
            }
            
            Spacer()
            
            HStack(spacing: AppSpacing.sm) {
                StatusBadge(
                    titleKey: isOverdue ? "activeTrip.overdue" : "activeTrip.active",
                    style: isOverdue ? .destructive : .positive,
                    size: .small
                )
                
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.lableSec)
            }
        }
    }
    
    var returnTimeSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            
            HStack {
                Text("activeTrip.returnTime".localized)
                    .font(AppTypography.caption)
                    .foregroundStyle(Color.lableSec)
                
                Spacer()
                
                uploadStatus
            }
            
            HStack(spacing: AppSpacing.sm) {
                dateChip
                timeChip
            }

            if hasReturnTimeChanges {
                updateButton
            }
        }
        .padding(AppSpacing.md)
        .background(Color.Grey100.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }
    
    var dateChip: some View {
        Button {
            draftReturnTime = selectedReturnTime
            activePicker = .date
        } label: {
            chipText(formatDate(displayedReturnTime))
        }
        .buttonStyle(.plain)
        .popover(isPresented: Binding(
            get: { activePicker == .date },
            set: { if !$0 { activePicker = nil } }
        )) {
            datePickerPopover
                .presentationCompactAdaptation(.popover)
        }
    }
    
    var timeChip: some View {
        Button {
            draftReturnTime = selectedReturnTime
            activePicker = .time
        } label: {
            chipText(formatTime(displayedReturnTime))
        }
        .buttonStyle(.plain)
        .popover(isPresented: Binding(
            get: { activePicker == .time },
            set: { if !$0 { activePicker = nil } }
        )) {
            timePickerPopover
                .presentationCompactAdaptation(.popover)
        }
    }
    
    func chipText(_ text: String) -> some View {
        Text(text)
            .font(AppTypography.caption)
            .foregroundStyle(Color.Primary)
            .lineLimit(1)
            .minimumScaleFactor(0.9)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .padding(.horizontal, 8)
            .background(Color.white)
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(Color.Grey100, lineWidth: 1)
            }
    }

    var updateButton: some View {
        Button {
            selectedReturnTime = draftReturnTime
            onUpdateReturnTime(draftReturnTime)
        } label: {
            Text("activeTrip.updateTime".localized)
                .font(AppTypography.caption)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(Color.Secondary02)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    var datePickerPopover: some View {
        VStack(spacing: AppSpacing.md) {
            
            DatePicker(
                "",
                selection: $draftReturnTime,
                in: Date()...,
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
            .labelsHidden()
            .tint(Color.Secondary02)
            .frame(width: 320, height: 330)
            
        }
        .padding(AppSpacing.md)
        .background(Color.white)
    }
    
    var timePickerPopover: some View {
        VStack(spacing: AppSpacing.md) {
            
            DatePicker(
                "",
                selection: $draftReturnTime,
                displayedComponents: [.hourAndMinute]
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .frame(width: 260, height: 140)
            
        }
        .padding(AppSpacing.md)
        .background(Color.white)
    }
    
    
    var uploadStatus: some View {
        HStack(spacing: 5) {
            Image(systemName: isUploaded ? "checkmark.circle.fill" : "arrow.up.circle")
                .font(.system(size: 12))
                .foregroundStyle(isUploaded ? Color.green : Color.lableSec)
            
            Text(isUploaded ? "activeTrip.uploaded".localized : "activeTrip.uploading".localized)
                .font(AppTypography.caption2)
                .foregroundStyle(isUploaded ? Color.green : Color.lableSec)
        }
    }
    
    var emergencyContactsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text(String(format: "activeTrip.emergencyContactsCount".localized, emergencyContacts.count))
                .font(AppTypography.headline)
                .foregroundStyle(Color.Primary)

            VStack(spacing: 0) {
                ForEach(Array(emergencyContacts.enumerated()), id: \.offset) { index, contact in
                    ContactRow(
                        initial: String(contact.name.prefix(1)),
                        titleKey: contact.name,
                        captionKey: contact.phone,
                        isEditable: false
                    )
                    .frame(height: 70)

                }
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        }
    }
    
    
    var endTripButton: some View {
        Button {
            onEndTrip()
        } label: {
            Text("activeTrip.endTrip".localized)
                .font(AppTypography.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 51)
                .background(Color.Primary)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.xxl))
        }
        .buttonStyle(.plain)
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: date)
    }
    
    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

#Preview {
        ActiveTripCard(
            emergencyContacts: [
                Contact(name: "Om Saqr", phone: "+966 5X XXX XXXX"),
                Contact(name: "Saqr", phone: "+966 5X XXX XXXX")
            ]
        )
        .padding(.horizontal, AppSpacing.lg)
        .padding(.bottom, 100)
    }
