//
//  TripSummaryCard.swift
//  Desert
//
//  Created by Samar A on 11/12/1447 AH.
//

import SwiftUI

struct TripSummaryCard: View {
    
    let rows: [(titleKey: String, valueKey: String)]
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                summaryRow(titleKey: row.titleKey, valueKey: row.valueKey)
                
                if index != rows.count - 1 {
                    AppDivider()
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }
}
private extension TripSummaryCard {
    
    
    func summaryRow(titleKey: String, valueKey: String) -> some View {
        HStack(spacing: 12) {
            Text(titleKey.localized)
                .font(AppTypography.body)
                .foregroundStyle(Color.Primary)
                .lineLimit(1)
            
            Spacer(minLength: 8)
            
            Text(valueKey.localized)
                .font(AppTypography.body)
                .foregroundStyle(Color.lableSec)
                .lineLimit(1)
        }
        .frame(height: 37)
    }
}

#Preview {
    
    VStack(spacing: 24) {
        
        TripSummaryCard(rows: [
            ("Start Time", "1 Jun, 04:30PM"),
            ("Return Time", "1 Jun, 09:00PM"),
            ("Destination", "Al Thumamah"),
            ("Car Details", "White Toyota Land Cruiser"),
            ("Plate Number", "1234 | RSX"),
            ("Selected Distance", "78 km"),
            ("No. of individuals", "3 People")
        ])
        
        TripSummaryCard(rows: [
            ("Start Time", "24 May, 09:15AM"),
            ("Return Time", "24 May, 05:30PM"),
            ("Destination", "Rub' al Khali"),
            ("No. of individuals", "5 People"),
            ("Car Details", "Black Nissan Patrol"),
            ("Plate Number", "5678 | ABD"),
            ("Distance", "240 km")
        ])
    }
    .padding()
    .background(Color.Background)
}
