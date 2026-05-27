//
//   NetworkStatusBanner.swift
//  Desert
//
//  Created by Samar A on 10/12/1447 AH.
//

import SwiftUI

struct NetworkStatusBanner: View {
    
    enum Status {
        case connected
        case disconnected
    }
    
    var status: Status
    
    var body: some View {
        
        HStack(spacing: 14) {
            
            ConnectivityIcon(
                style: status == .connected
                ? .connected
                : .disconnected
            )
            
            VStack(alignment: .leading, spacing: 2) {
                
                Text(title)
                    .font(AppTypography.headline)
                    .foregroundStyle(Color.Primary)
                
                if let subtitle {
                    Text(subtitle)
                        .font(AppTypography.body)
                        .foregroundStyle(Color.lableSec)
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppSpacing.lg)
        .frame(maxWidth: .infinity)
        .frame(height: 68)
        .background(Color.Background)
        .clipShape(Capsule())
        .shadow(
            color: .black.opacity(0.06),
            radius: 10,
            y: 1
        )
    }
}

private extension NetworkStatusBanner {
    
    var title: String {
        
        switch status {
        case .connected:
            return "network.connected.title".localized
            
        case .disconnected:
            return "network.disconnected.title".localized
        }
    }
    
    var subtitle: String? {
        
        switch status {
        case .connected:
            return nil
            
        case .disconnected:
            return "network.disconnected.message".localized
        }
    }
}

#Preview {
    
    VStack(spacing: 24) {
        
        NetworkStatusBanner(status: .disconnected)
        
        NetworkStatusBanner(status: .connected)
    }
    .padding()
    .background(Color.Background)
}
