//
//  FoundItemDetailView.swift
//  LostAndFound
//
//  Created by Craig Bakke on 12/01/25.
//

import Foundation
import SwiftUI
import MapKit
#if canImport(UIKit)
import UIKit
#endif

struct FoundItemDetailView: View {
    let report: Report
    
    @State private var mapCameraPosition: MapCameraPosition
    private let mapAnnotations: [ReportLocationAnnotation]
    @State private var isReporterInfoVisible = false
    
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
        .overlay {
            if isReporterInfoVisible {
                ZStack {
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isReporterInfoVisible = false
                            }
                        }
                    
                    reporterInfoModal
                        .padding(.horizontal, 24)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isReporterInfoVisible)
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
            
            reportedDateBlock(
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
                .foregroundColor(ColorPalette.labelPrimary)
            
            Text(value)
                .font(.custom("IBMPlexSans", size: bodyFontSize))
                .foregroundColor(ColorPalette.labelPrimary.opacity(0.9))
        }
    }
    
    private func reportedDateBlock(
        labelFontSize: CGFloat,
        bodyFontSize: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Reported on")
                .font(.custom("IBMPlexSans", size: labelFontSize))
                .foregroundColor(ColorPalette.labelPrimary)
            
            Text("\(reportedOnDateString) at \(reportedOnTimeString)")
                .font(.custom("IBMPlexSans", size: bodyFontSize))
                .foregroundColor(ColorPalette.labelPrimary.opacity(0.9))
        }
    }
    
    private var actionButton: some View {
        Button {
            isReporterInfoVisible = true
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
    
    private var reporterInfoModal: some View {
        VStack(alignment: .leading, spacing: 28) {
            Text("Reported By:")
                .font(.custom("IBMPlexSans", size: 24))
                .foregroundColor(ColorPalette.labelPrimary)
            
            VStack(alignment: .leading, spacing: 18) {
                reporterInfoRow(title: "Name", copyValue: report.createdByName) {
                    Text(report.createdByName)
                        .font(.custom("IBMPlexSans", size: 18))
                        .foregroundColor(ColorPalette.labelPrimary)
                }
                
                reporterInfoRow(title: "Email", copyValue: report.createdByEmail) {
                    Text(report.createdByEmail)
                        .font(.custom("IBMPlexSans", size: 18))
                        .foregroundColor(ColorPalette.labelPrimary)
                }
                
                reporterInfoRow(title: "Phone", copyValue: report.createdByPhone) {
                    if let telURL = reporterPhoneURL {
                        Link(formattedReporterPhone, destination: telURL)
                            .font(.custom("IBMPlexSans", size: 18))
                            .foregroundColor(ColorPalette.witGradient2)
                    } else {
                        Text(formattedReporterPhone)
                            .font(.custom("IBMPlexSans", size: 18))
                            .foregroundColor(ColorPalette.labelPrimary)
                    }
                }
            }
            
            Button {
                isReporterInfoVisible = false
            } label: {
                Text("Done")
                    .font(.custom("IBMPlexSans", size: 18))
                    .foregroundColor(ColorPalette.witRichBlack)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(ColorPalette.witGold)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(28)
        .frame(maxWidth: 420, alignment: .leading)
        .background(ColorPalette.actionButtonBackground)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 12)
    }
    
    private func reporterInfoRow(
        title: String,
        copyValue: String,
        @ViewBuilder valueContent: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.custom("IBMPlexSans", size: 16))
                .foregroundColor(ColorPalette.labelPrimary.opacity(0.8))
            
            HStack(alignment: .center, spacing: 12) {
                valueContent()
                
                Spacer()
                
                Button {
                    copyToClipboard(copyValue)
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(ColorPalette.labelPrimary.opacity(0.85))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Copy \(title)")
            }
        }
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
    
    private var reportedOnDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: report.createdAt)
    }
    
    private var reportedOnTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: report.createdAt)
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

private extension FoundItemDetailView {
    var reporterPhoneDigitsOnly: String {
        report.createdByPhone.filter(\.isNumber)
    }
    
    var formattedReporterPhone: String {
        let digits = reporterPhoneDigitsOnly
        guard digits.count == 10 else { return report.createdByPhone }
        
        let area = digits.prefix(3)
        let middleStart = digits.index(digits.startIndex, offsetBy: 3)
        let middleEnd = digits.index(middleStart, offsetBy: 3)
        let middle = digits[middleStart..<middleEnd]
        let last = digits.suffix(4)
        
        return "(\(area)) \(middle)-\(last)"
    }
    
    var reporterPhoneURL: URL? {
        let digits = reporterPhoneDigitsOnly
        guard digits.count == 10 else { return nil }
        return URL(string: "tel://\(digits)")
    }
    
    func copyToClipboard(_ text: String) {
#if canImport(UIKit)
        UIPasteboard.general.string = text
#endif
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


