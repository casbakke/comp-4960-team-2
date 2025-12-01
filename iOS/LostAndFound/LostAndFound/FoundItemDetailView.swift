//
//  FoundItemDetailView.swift
//  LostAndFound
//
//  Created by Craig Bakke on 12/01/25.
//

import Foundation
import SwiftUI
import MapKit

struct FoundItemDetailView: View {
    let report: Report
    
    @State private var mapCameraPosition: MapCameraPosition
    private let mapAnnotations: [ReportLocationAnnotation]
    
    init(report: Report) {
        self.report = report
        
        if let coordinate = report.locationCoordinates?.clLocationCoordinate2D {
            let region = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003)
            )
            _mapCameraPosition = State(initialValue: .region(region))
            mapAnnotations = [ReportLocationAnnotation(coordinate: coordinate)]
        } else {
            _mapCameraPosition = State(initialValue: .automatic)
            mapAnnotations = []
        }
    }
    
    private var validImageURL: URL? {
        guard let url = report.imageUrl else { return nil }
        let trimmed = url.absoluteString.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : url
    }
    
    var body: some View {
        GeometryReader { geometry in
            let horizontalPadding = geometry.size.width * 0.065
            let verticalSpacing = max(geometry.size.height * 0.02, 16)
            let contentWidth = geometry.size.width - (horizontalPadding * 2)
            let mediaHeight = contentWidth * 0.75
            let cardCornerRadius = max(geometry.size.width * 0.045, 18)
            let labelFontSize = max(geometry.size.width * 0.048, 18)
            let bodyFontSize = max(geometry.size.width * 0.040, 15)
            let safeBottom = geometry.safeAreaInsets.bottom
            
            ZStack(alignment: .bottom) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: verticalSpacing) { 
                        if let imageURL = validImageURL {
                            mediaSection(
                                maxWidth: contentWidth,
                                height: mediaHeight,
                                cornerRadius: cardCornerRadius,
                                imageURL: imageURL
                            )
                        }
                        
                        detailsSection(
                            cardCornerRadius: cardCornerRadius,
                            labelFontSize: labelFontSize,
                            bodyFontSize: bodyFontSize,
                            mapHeight: mediaHeight * 0.65
                        )
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, verticalSpacing)
                    .padding(.bottom, 100)
                }
                .background(ColorPalette.backgroundPrimary.ignoresSafeArea())
                
                actionButton
                    .padding(.horizontal, horizontalPadding)
            }
        }
        .navigationTitle("Found item")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }
    
    @ViewBuilder
    private func mediaSection(
        maxWidth: CGFloat,
        height: CGFloat,
        cornerRadius: CGFloat,
        imageURL: URL
    ) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(ColorPalette.actionButtonBackground)
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
            
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    placeholderContent(title: "Image unavailable")
                case .empty:
                    placeholderContent(title: "Loading image…")
                @unknown default:
                    placeholderContent(title: "Image unavailable")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
        .frame(width: maxWidth, height: height)
    }
    
    private func detailsSection(
        cardCornerRadius: CGFloat,
        labelFontSize: CGFloat,
        bodyFontSize: CGFloat,
        mapHeight: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(report.title)
                .font(.custom("IBMPlexSans", size: labelFontSize * 1.2))
                .fontWeight(.bold)
                .foregroundColor(ColorPalette.labelPrimary)
            
            detailBlock(
                title: "Category",
                value: report.category.displayName,
                labelFontSize: labelFontSize,
                bodyFontSize: bodyFontSize
            )
            
            detailBlock(
                title: "Description",
                value: report.description?.trimmedDescription ?? "No description provided.",
                labelFontSize: labelFontSize,
                bodyFontSize: bodyFontSize
            )
            
            detailBlock(
                title: "Last known location",
                value: report.locationBuilding,
                labelFontSize: labelFontSize,
                bodyFontSize: bodyFontSize
            )
            
            if !mapAnnotations.isEmpty {
                Map(position: $mapCameraPosition, interactionModes: []) {
                    ForEach(mapAnnotations) { annotation in
                        Annotation("", coordinate: annotation.coordinate) {
                            Button {
                                openInMaps(coordinate: annotation.coordinate)
                            } label: {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(ColorPalette.witGold, ColorPalette.witGradient1)
                                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(height: mapHeight)
                .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius * 0.6, style: .continuous))
                .overlay(alignment: .bottomLeading) {
                    Text(coordinateDisplayString)
                        .font(.custom("IBMPlexSans", size: bodyFontSize * 0.9))
                        .foregroundColor(ColorPalette.labelPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(ColorPalette.backgroundPrimary.opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .padding(12)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ColorPalette.actionButtonBackground)
        .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
    }
    
    private func detailBlock(
        title: String,
        value: String,
        labelFontSize: CGFloat,
        bodyFontSize: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.custom("IBMPlexSans", size: labelFontSize))
                .fontWeight(.semibold)
                .foregroundColor(ColorPalette.labelPrimary)
            
            Text(value)
                .font(.custom("IBMPlexSans", size: bodyFontSize))
                .foregroundColor(ColorPalette.labelPrimary.opacity(0.9))
        }
    }
    
    private var actionButton: some View {
        Button {
            // TODO: Hook up to claim workflow
        } label: {
            Text("This item is mine")
                .font(.custom("IBMPlexSans", size: 18))
                .foregroundColor(ColorPalette.witRichBlack)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(LinearGradient(
                    colors: [ColorPalette.witGold, ColorPalette.witGradient2],
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
    
    private func placeholderContent(title: String, subtitle: String? = nil) -> some View {
        VStack(spacing: 6) {
            Text(title)
            
            if let subtitle = subtitle {
                Text(subtitle)
            }
        }
        .font(.custom("IBMPlexSans", size: 14))
        .foregroundColor(ColorPalette.labelPrimary.opacity(0.7))
        .multilineTextAlignment(.center)
    }
    
    private var coordinateDisplayString: String {
        guard let coordinate = report.locationCoordinates else {
            return ""
        }
        
        return String(
            format: "Lat %.4f, Lon %.4f",
            coordinate.latitude,
            coordinate.longitude
        )
    }
    
    private func openInMaps(coordinate: CLLocationCoordinate2D) {
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = report.locationBuilding
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDefault
        ])
    }
}

private struct ReportLocationAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

private extension ReportCoordinates {
    var clLocationCoordinate2D: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

private extension String {
    var trimmedDescription: String {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "No description provided." : trimmed
    }
}

#Preview {
    NavigationStack {
        FoundItemDetailView(report: Report.sampleFoundReports[0])
    }
}


