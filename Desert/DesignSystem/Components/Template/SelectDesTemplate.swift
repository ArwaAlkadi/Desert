//
//  SelectDestinationTemplate.swift
//  Desert
//
//  Created by Samar A on 12/12/1447 AH.
//

// هنا غيرت فيه كان ينقصه متغيرات.. وبرضو سويت نتايج البحث  DONEعالسريع بدون ديزاين عدلي عدليها من فيقما ميار سوتها

import SwiftUI
import MapKit

struct SelectDestinationTemplate<MapContent: View>: View {
    
    @Binding var searchText: String
    var searchResults: [(item: MKMapItem, subtitle: String?)]
    var canConfirm: Bool
    var mapContent: () -> MapContent
    
    var onBack: () -> Void
    var onSearch: () -> Void
    var onSelectResult: (MKMapItem) -> Void
    var onConfirm: () -> Void
    
    var body: some View {
        ZStack(alignment: .top) {
            
            mapContent()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                SearchBar(
                    style: .withBackButton,
                    placeholderKey: "search.destination",
                    text: $searchText,
                    backAction: onBack,
                    searchAction: onSearch
                )
                .frame(width: 340)
                .padding(.top, AppSpacing.sm)
                .zIndex(1)
                
                if !searchResults.isEmpty {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            ForEach(Array(searchResults.enumerated()), id: \.offset) { index, result in
                                Button {
                                    onSelectResult(result.item)
                                } label: {
                                    HStack(spacing: AppSpacing.sx) {
                                        Circle()
                                            .fill(Color.Secondary)
                                            .frame(width: 50, height: 50)
                                            .overlay {
                                                Image(systemName: "mappin")
                                                    .font(.system(size: 18, weight: .medium))
                                                    .foregroundStyle(Color.Primary)
                                            }

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(result.item.name ?? "")
                                                .font(AppTypography.body)
                                                .foregroundStyle(Color.Primary)
                                                .lineLimit(1)

                                            if let subtitle = result.subtitle {
                                                Text(subtitle)
                                                    .font(AppTypography.caption)
                                                    .foregroundStyle(Color.lableSec)
                                                    .lineLimit(1)
                                            }
                                        }

                                        Spacer()
                                    }
                                    .padding(.horizontal, AppSpacing.md)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .frame(height: 82)
                                }
                                .buttonStyle(.plain)

                                if index < searchResults.count - 1 {
                                    Divider()
                                        .padding(.horizontal, AppSpacing.lg)
                                }
                            }
                        }
                    }
                    .frame(maxHeight: min(CGFloat(searchResults.count) * 82, 370))
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl))
                    .frame(width: 325)
                    .padding(.top, AppSpacing.sm)
                    .frame(maxWidth: .infinity, alignment: .top)
                    .padding(.leading,34)                    .zIndex(0)
                }
            }
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .environment(\.layoutDirection, .leftToRight)
        .safeAreaInset(edge: .bottom) {
            CTAButton(
                title: "common.select".localized,
                style: canConfirm ? .primary : .disabled
            ) {
                onConfirm()
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.bottom, AppSpacing.lg)
        }
        
    }
}
#Preview {
    SelectDestinationTemplate(
        searchText: .constant("Riyadh"),
        searchResults: [
            (
                item: {
                    let item = MKMapItem(
                        placemark: MKPlacemark(
                            coordinate: CLLocationCoordinate2D(
                                latitude: 24.774265,
                                longitude: 46.738586
                            )
                        )
                    )
                    item.name = "Marina Mall"
                    return item
                }(),
                subtitle: "Riyadh, Saudi Arabia"
            ),
            (
                item: {
                    let item = MKMapItem(
                        placemark: MKPlacemark(
                            coordinate: CLLocationCoordinate2D(
                                latitude: 24.713552,
                                longitude: 46.675297
                            )
                        )
                    )
                    item.name = "Boulevard City"
                    return item
                }(),
                subtitle: "Riyadh, Saudi Arabia"
            ),
            (
                item: {
                    let item = MKMapItem(
                        placemark: MKPlacemark(
                            coordinate: CLLocationCoordinate2D(
                                latitude: 24.714961,
                                longitude: 46.675243
                            )
                        )
                    )
                    item.name = "Kingdom Centre"
                    return item
                }(),
                subtitle: "Riyadh, Saudi Arabia"
            )
        ],
        canConfirm: true,
        mapContent: {
            Image("tripMap")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        },
        onBack: {},
        onSearch: {},
        onSelectResult: { _ in },
        onConfirm: {}
    )
}
