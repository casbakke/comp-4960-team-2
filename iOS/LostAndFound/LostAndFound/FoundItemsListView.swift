//
//  FoundItemsListView.swift
//  LostAndFound
//
//  Created by Craig Bakke on 12/01/25.
//

import SwiftUI

struct FoundItemsListView: View {
    @ObservedObject var appState: AppState
    
    let currentUserName: String
    let currentUserEmail: String
    
    @State private var searchText: String = ""
    @State private var selectedCategory: ReportCategory?
    @FocusState private var isSearchFieldFocused: Bool
    
    private let reports = Report.sampleFoundReports
    
    init(
        appState: AppState,
        currentUserName: String,
        currentUserEmail: String
    ) {
        self.appState = appState
        self.currentUserName = currentUserName
        self.currentUserEmail = currentUserEmail
    }
    
    private var filteredReports: [Report] {
        reports
            .filter { $0.type == .found && $0.status == .approved }
            .filter { report in
                let matchesCategory = selectedCategory == nil || report.category == selectedCategory
                
                guard !searchText.isEmpty else {
                    return matchesCategory
                }
                
                let normalizedQuery = searchText.lowercased()
                let searchableFields = [
                    report.title,
                    report.description ?? "",
                    report.locationBuilding,
                    report.createdByName
                ].map { $0.lowercased() }
                
                let matchesQuery = searchableFields.contains { $0.contains(normalizedQuery) }
                
                return matchesCategory && matchesQuery
            }
            .sorted(by: { $0.createdAt > $1.createdAt })
    }
    
    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let screenHeight = geometry.size.height
            let safeBottom = geometry.safeAreaInsets.bottom
            
            let horizontalPadding = screenWidth * 0.055
            let verticalSpacing = max(screenHeight * 0.02, 16)
            let searchBarHeight = max(screenHeight * 0.06, 48)
            let filterControlHeight = max(screenHeight * 0.05, 44)
            
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(alignment: .leading, spacing: verticalSpacing) {
                        infoBanner
                        searchField(height: searchBarHeight)
                        categoryFilter(height: filterControlHeight)
                        
                        if filteredReports.isEmpty {
                            emptyState
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            LazyVStack(spacing: verticalSpacing) {
                                ForEach(filteredReports) { report in
                                    NavigationLink(value: report) {
                                        ReportSummaryCard(
                                            report: report,
                                            titleFontSize: max(screenWidth * 0.05, 18),
                                            detailFontSize: max(screenWidth * 0.037, 14),
                                            badgeFontSize: max(screenWidth * 0.032, 12)
                                        )
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, verticalSpacing)
                    .padding(.bottom, safeBottom + verticalSpacing * 4 + 84)
                }
                .background(ColorPalette.backgroundPrimary.ignoresSafeArea())
                .scrollDismissesKeyboard(.interactively)
                .simultaneousGesture(
                    TapGesture().onEnded {
                        if isSearchFieldFocused {
                            dismissKeyboard()
                        }
                    }
                )
                
                if !isSearchFieldFocused {
                    NavigationLink {
                        LostReportFormView(
                            currentUserName: currentUserName,
                            currentUserEmail: currentUserEmail
                        )
                    } label: {
                        submitReportButtonLabel
                    }
                    .buttonStyle(SubmitReportButtonStyle())
                    .padding(.horizontal, horizontalPadding)
                    .padding(.bottom, 0)
                }
            }
        }
        .navigationTitle("Found Items")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .toolbarBackground(ColorPalette.backgroundPrimary, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationDestination(for: Report.self) { report in
            FoundItemDetailView(report: report)
        }
    }
    
    private var infoBanner: some View {
        Text("Before you report your lost item, check the list to see if it has already been reported as found.")
            .font(.custom("IBMPlexSans", size: 20))
            .foregroundColor(ColorPalette.labelPrimary)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ColorPalette.actionButtonBackground)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.08), radius: 5, x: 0, y: 2)
    }
    
    private func searchField(height: CGFloat) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(ColorPalette.labelPrimary.opacity(0.6))
            
            TextField("Search", text: $searchText)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .focused($isSearchFieldFocused)
                .font(.custom("IBMPlexSans", size: max(height * 0.4, 16)))
                .foregroundColor(ColorPalette.labelPrimary)
                .submitLabel(.done)
                .onSubmit {
                    searchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                    dismissKeyboard()
                }
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(ColorPalette.labelPrimary.opacity(0.6))
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .background(ColorPalette.actionButtonBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
    }
    
    private func categoryFilter(height: CGFloat) -> some View {
        Menu {
            Button("All Categories") {
                selectedCategory = nil
            }
            Divider()
            ForEach(ReportCategory.allCases) { category in
                Button(category.displayName) {
                    selectedCategory = category
                }
            }
        } label: {
            HStack {
                Text(selectedCategory?.displayName ?? "Filter by Category")
                    .font(.custom("IBMPlexSans", size: max(height * 0.4, 15)))
                    .fontWeight(.medium)
                    .foregroundColor(ColorPalette.labelPrimary)
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .font(.system(size: max(height * 0.35, 14), weight: .semibold))
                    .foregroundColor(ColorPalette.labelPrimary.opacity(0.7))
            }
            .padding(.horizontal, 16)
            .frame(height: height)
            .frame(maxWidth: .infinity)
            .background(ColorPalette.actionButtonBackground)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 48))
                .foregroundColor(ColorPalette.labelPrimary.opacity(0.4))
            
            Text("No matching items")
                .font(.custom("IBMPlexSans", size: 20))
                .fontWeight(.semibold)
                .foregroundColor(ColorPalette.labelPrimary)
            
            Text("Try adjusting your search or category filters.")
                .font(.custom("IBMPlexSans", size: 16))
                .foregroundColor(ColorPalette.labelPrimary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity)
    }
    
    private func dismissKeyboard() {
        isSearchFieldFocused = false
    }
    
    private var submitReportButtonLabel: some View {
        Text("Submit a report")
            .font(.custom("IBMPlexSans", size: 18))
            .foregroundColor(ColorPalette.witRichBlack)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
    }
}

private struct ReportSummaryCard: View {
    let report: Report
    let titleFontSize: CGFloat
    let detailFontSize: CGFloat
    let badgeFontSize: CGFloat
    
    private let imagePreviewMaxWidth: CGFloat = 260
    private let imagePreviewHeight: CGFloat = 160
    
    private var relativeCreatedAt: String {
        let interval = max(0, Date().timeIntervalSince(report.createdAt))
        let minute: TimeInterval = 60
        let hour = 60 * minute
        let day = 24 * hour
        let week = 7 * day
        
        switch interval {
        case ..<minute:
            return "Just now"
        case ..<hour:
            let minutes = Int(interval / minute)
            return "\(minutes)m ago"
        case ..<day:
            let hours = Int(interval / hour)
            return "\(hours)h ago"
        case ..<week:
            let days = Int(interval / day)
            return "\(days)d ago"
        default:
            let weeks = Int(interval / week)
            return "\(weeks)w ago"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                Text(report.title)
                    .font(.custom("IBMPlexSans", size: titleFontSize))
                    .fontWeight(.semibold)
                    .foregroundColor(ColorPalette.labelPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                Text(report.category.displayName)
                    .font(.custom("IBMPlexSans", size: badgeFontSize))
                    .fontWeight(.bold)
                    .foregroundColor(ColorPalette.labelPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        LinearGradient(
                            colors: [ColorPalette.witGradient1, ColorPalette.witGradient2, ColorPalette.witGradient3],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
            }
            
            if let imageUrl = report.imageUrl {
                AsyncImage(url: imageUrl) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        Image(systemName: "photo")
                            .font(.system(size: 40))
                            .foregroundColor(ColorPalette.labelPrimary.opacity(0.4))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(ColorPalette.actionButtonBackground)
                    @unknown default:
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 32))
                            .foregroundColor(ColorPalette.labelPrimary.opacity(0.6))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(ColorPalette.actionButtonBackground)
                    }
                }
                .frame(width: imagePreviewMaxWidth, height: imagePreviewHeight)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(ColorPalette.actionButtonBackground, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
            }
            
            if let description = report.description, !description.isEmpty {
                Text(description)
                    .font(.custom("IBMPlexSans", size: detailFontSize))
                    .foregroundColor(ColorPalette.labelPrimary.opacity(0.8))
                    .lineLimit(3)
            }
            
            HStack(spacing: 12) {
                Label(report.locationBuilding, systemImage: "mappin.and.ellipse")
                    .font(.custom("IBMPlexSans", size: detailFontSize))
                    .foregroundColor(ColorPalette.labelPrimary)
                    .lineLimit(1)
                
                Spacer()
                
                Text(relativeCreatedAt)
                    .font(.custom("IBMPlexSans", size: detailFontSize * 0.95))
                    .foregroundColor(ColorPalette.labelPrimary.opacity(0.7))
            }
            
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ColorPalette.backgroundPrimary)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 6)
    }
}

private struct SubmitReportButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                LinearGradient(
                    colors: configuration.isPressed 
                        ? [ColorPalette.witGradient1, ColorPalette.witGradient2]
                        : [ColorPalette.witGold, ColorPalette.witGradient2],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    NavigationStack {
        FoundItemsListView(
            appState: AppState(),
            currentUserName: "John Doe",
            currentUserEmail: "john.doe@wit.edu"
        )
    }
}


