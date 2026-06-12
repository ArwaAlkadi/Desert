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
    var isConnected: Bool = false
    
    var emergencyContacts: [Contact] = []
    
    var onUpdateReturnTime: (Date) -> Void = { _ in }
    var onEndTrip: () -> Void = {}
    
    @State private var isExpanded = false
    @State private var selectedReturnTime = Date()
    @State private var draftReturnTime = Date()
    @State private var showDatePicker = false
    @State private var showTimePicker = false
    @State private var showUploadStatus = false
    
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
        .frame(maxWidth: 360, alignment: .center)
        .frame(maxWidth: .infinity, alignment: .center)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 4)
        .onAppear {
            selectedReturnTime = returnTime
            draftReturnTime = returnTime
        }
        .onChange(of: returnTime) { _, newValue in
            selectedReturnTime = newValue
            draftReturnTime = newValue
        }
        .onChange(of: isUploaded) { _, newValue in
            if newValue {
                showUploadStatus = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showUploadStatus = false
                }
            }
        }
        .sheet(isPresented: $showDatePicker) {
            DateTimePickerSheet(
                selectedDate: $draftReturnTime,
                mode: .date
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color.white)
        }
    }
}





private extension ActiveTripCard {
    
    var headerSection: some View {
        HStack(alignment: .top) {
            
            headerTitle
            
            Spacer()
            
            headerActions
        }
    }
    
    var headerTitle: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(tripName)
                .font(AppTypography.body)
                .foregroundStyle(Color.Lableblack)
                .multilineTextAlignment(.leading)
            
            Text(daysLeft)
                .font(AppTypography.title1)
                .foregroundStyle(Color.Lableblack)
                .multilineTextAlignment(.leading)
        }
    }
    
    
    var headerActions: some View {
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
    
    var returnTimeSection: some View {
        VStack(alignment: AppLanguage.horizontalAlignment, spacing: AppSpacing.sm) {
            
            HStack {
                Text("activeTrip.returnTime".localized)
                    .font(AppTypography.headline)
                    .foregroundStyle(Color.Lableblack)
                
                Spacer()
                
                if showUploadStatus {
                    uploadStatus
                }
            }
            
            HStack(spacing: AppSpacing.sm) {
                dateChip
                timeChip
                
                if hasReturnTimeChanges {
                    updateButton
                }
            }
        }
        .padding(AppSpacing.md)
        //        .background(Color.Primary.opacity(0.06))
        //        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }
    
    var dateChip: some View {
        Button {
            showDatePicker = true
        } label: {
            chipText(formatDate(displayedReturnTime))
        }
        .buttonStyle(.plain)
    }
    
    
    var timeChip: some View {
        Button {
            showTimePicker = true
        } label: {
            chipText(formatTime(displayedReturnTime))
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showTimePicker) {
            DatePicker(
                "",
                selection: $draftReturnTime,
                displayedComponents: [.hourAndMinute]
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .frame(width: 240, height: 120)
            .padding(8)
            .presentationCompactAdaptation(.popover)
        }
    }
    func chipText(_ text: String) -> some View {
        Text(text)
            .font(AppTypography.caption)
            .foregroundStyle(Color.white)
            .lineLimit(1)
            .minimumScaleFactor(0.9)
            .frame(maxWidth: .infinity)
            .frame(height: 32)
            .padding(.horizontal, 8)
            .background(Color.Primary)
            .clipShape(Capsule())
    }
    
    var updateButton: some View {
        Button {
            guard draftReturnTime > Date() else { return }
            selectedReturnTime = draftReturnTime
            showUploadStatus = true
            onUpdateReturnTime(draftReturnTime)
        } label: {
            Image(systemName: "checkmark")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 32)
                .background(draftReturnTime > Date() ? Color.Secondary02 : Color.Disabled)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(draftReturnTime <= Date())
        .transition(.scale.combined(with: .opacity))
    }
    
    var uploadStatus: some View {
        HStack(spacing: 5) {
            if isUploaded {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.Positive)
            } else {
                ProgressView()
                    .scaleEffect(0.6)
                    .tint(Color.lableSec)
            }
            
            Text(isUploaded ? "activeTrip.uploaded".localized : "activeTrip.uploading".localized)
                .font(AppTypography.caption2)
                .foregroundStyle(isUploaded ? Color.Positive : Color.lableSec)
        }
    }
    
    var emergencyContactsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                if AppLanguage.isArabic {
                    Spacer()
                }
                
                Text(
                    "activeTrip.emergencyContacts".localized
                    + " (\(formatNumber(emergencyContacts.count)))"
                )
                .font(AppTypography.headline)
                .foregroundStyle(Color.Lableblack)
                
                if !AppLanguage.isArabic {
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity)
            .environment(\.layoutDirection, .leftToRight)
            
            VStack(spacing: 0) {
                ForEach(Array(emergencyContacts.enumerated()), id: \.offset) { index, contact in
                    ContactRow(
                        initial: String(contact.name.prefix(1)),
                        titleKey: contact.name,
                        captionKey: contact.phone,
                        isEditable: false
                    )
                    .frame(minHeight: 70)
                    
                    if index < emergencyContacts.count - 1 {
                               Divider()
                                   .padding(.horizontal, AppSpacing.md)
                        }
                }
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    var endTripButton: some View {
        Button {
            onEndTrip()
        } label: {
            Text("activeTrip.endTrip".localized)
                .font(AppTypography.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    isConnected ? Color.Disabled : Color.Primary
                )
                .clipShape(
                    RoundedRectangle(cornerRadius: AppRadius.xxl)
                )
        }
        .padding(.horizontal, AppSpacing.md)
        .disabled(isConnected)
        .buttonStyle(.plain)
    }
    
    // Helpers
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: AppLanguage.isArabic ? "ar" : "en_US")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "d MMM yyyy"
        
        let value = formatter.string(from: date)
        return AppLanguage.isArabic ? localizeDigits(value) : value
    }
    
    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: AppLanguage.isArabic ? "ar" : "en_US")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "h:mm a"
        
        let value = formatter.string(from: date)
        return AppLanguage.isArabic ? localizeDigits(value) : value
    }
    
    func localizeDigits(_ text: String) -> String {
        guard AppLanguage.isArabic else { return text }
        
        let westernDigits = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
        let arabicDigits = ["٠", "١", "٢", "٣", "٤", "٥", "٦", "٧", "٨", "٩"]
        
        var result = text
        
        for index in westernDigits.indices {
            result = result.replacingOccurrences(
                of: westernDigits[index],
                with: arabicDigits[index]
            )
        }
        
        return result
    }
    
    func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: AppLanguage.isArabic ? "ar_SA" : "en_US")
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
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
