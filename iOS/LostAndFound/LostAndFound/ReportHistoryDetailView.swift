//
//  ReportHistoryDetailView.swift
//  LostAndFound
//
//  Created by Craig Bakke on 12/07/25.
//

import Foundation
import SwiftUI
import MapKit
#if canImport(UIKit)
import UIKit
#endif

struct ReportHistoryDetailView: View {
    let report: Report
    @ObservedObject var appState: AppState
    
    @State private var mapCameraPosition: MapCameraPosition
    private let mapAnnotations: [ReportLocationAnnotation]
    @State private var isResolvingReport = false
    @State private var showResolvedAlert = false
    @State private var resolveError: String?
    @Environment(\.dismiss) private var dismiss
    
    private let reportService = ReportService()
    
    init(report: Report, appState: AppState) {
        self.report = report
        self.appState = appState
        
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
    
    private var canResolve: Bool {
        return report.status == .pending || report.status == .approved
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
            let badgeFontSize = max(geometry.size.width * 0.032, 12)
            
            ZStack(alignment: .bottom) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: verticalSpacing) {
                        // Type and Status Pills
                        HStack(spacing: 10) {
                            // Type pill
                            Text(report.type == .lost ? "Lost" : "Found")
                                .font(.custom("IBMPlexSans", size: badgeFontSize * 1.1))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(report.type == .lost ? Color.blue : Color.orange)
                                .clipShape(Capsule())
                            
                            // Status pill
                            Text(statusDisplayText(for: report.status))
                                .font(.custom("IBMPlexSans", size: badgeFontSize * 1.1))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(statusColor(for: report.status))
                                .clipShape(Capsule())
                        }
                        
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
                    .padding(.bottom, canResolve ? 100 : verticalSpacing * 2)
                }
                .background(ColorPalette.backgroundPrimary.ignoresSafeArea())
                
                if canResolve {
                    actionButton
                        .padding(.horizontal, horizontalPadding)
                }
            }
        }
        .navigationTitle(report.type == .lost ? "Lost item" : "Found item")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .alert("Report Resolved", isPresented: $showResolvedAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("This report has been marked as resolved.")
        }
        .alert("Error", isPresented: .constant(resolveError != nil)) {
            Button("OK") {
                resolveError = nil
            }
        } message: {
            if let error = resolveError {
                Text(error)
            }
        }
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
                title: "Item location",
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
            Task {
                await resolveReport()
            }
        } label: {
            if isResolvingReport {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: ColorPalette.witRichBlack))
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
            } else {
                Text("Mark as Resolved")
                    .font(.custom("IBMPlexSans", size: 18))
                    .foregroundColor(ColorPalette.witRichBlack)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
            }
        }
        .disabled(isResolvingReport)
        .background(LinearGradient(
            colors: [ColorPalette.witGold, ColorPalette.witGradient2],
            startPoint: .leading,
            endPoint: .trailing
        ))
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
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
    
    private func resolveReport() async {
        isResolvingReport = true
        resolveError = nil
        
        do {
            try await reportService.resolveReport(reportId: report.id)
            showResolvedAlert = true
        } catch {
            resolveError = error.localizedDescription
            #if DEBUG
            print("Error resolving report: \(error)")
            #endif
        }
        
        isResolvingReport = false
    }
    
    private func statusDisplayText(for status: ReportStatus) -> String {
        switch status {
        case .pending:
            return "Pending"
        case .approved:
            return "Approved"
        case .rejected:
            return "Rejected"
        case .resolved:
            return "Resolved"
        }
    }
    
    private func statusColor(for status: ReportStatus) -> Color {
        switch status {
        case .pending:
            return Color.yellow.opacity(0.8)
        case .approved:
            return Color.green.opacity(0.7)
        case .rejected:
            return Color.red.opacity(0.8)
        case .resolved:
            return Color.green.opacity(0.9)
        }
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
        ReportHistoryDetailView(
            report: Report(
                id: UUID(),
                category: .electronics,
                createdByName: "Jordan Clark",
                createdByEmail: "jclark@wit.edu",
                createdByPhone: "6175551200",
                createdAt: Date().addingTimeInterval(-60 * 60 * 2),
                description: "Silver 13\" HP Pavilion with sticker near the trackpad.",
                title: "HP Pavilion Laptop",
                imageUrl: URL(string: "https://www.cnet.com/a/img/resize/bb8a2aa9c31f8ec08d82228a51eabf05f00e54d2/hub/2025/03/10/d190e21d-9634-440d-8f33-396c8cb3da6a/m4-macbook-air-15-11.jpg?auto=webp&height=500"),
                locationBuilding: "Wentworth Library",
                locationCoordinates: ReportCoordinates(latitude: 42.3378, longitude: -71.0953),
                reviewedAt: Date().addingTimeInterval(-60 * 35),
                reviewedBy: "carter@wit.edu",
                status: .approved,
                type: .lost
            ),
            appState: AppState()
        )
    }
}

