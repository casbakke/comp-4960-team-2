//
//  FoundItemsListView.swift
//  LostAndFound
//
//  Created by Craig Bakke on 12/01/25.
//

import SwiftUI

struct FoundItemsListView: View {
    @State private var searchText: String = ""
    @State private var selectedCategory: ReportCategory?
    @FocusState private var isSearchFieldFocused: Bool
    
    private let reports = Report.sampleFoundReports
    
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
                .padding(.bottom, safeBottom + verticalSpacing)
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
}

private struct ReportSummaryCard: View {
    let report: Report
    let titleFontSize: CGFloat
    let detailFontSize: CGFloat
    let badgeFontSize: CGFloat
    
    private var formattedCreatedAt: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: report.createdAt)
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
                
                Text(formattedCreatedAt)
                    .font(.custom("IBMPlexSans", size: detailFontSize * 0.95))
                    .foregroundColor(ColorPalette.labelPrimary.opacity(0.7))
            }
            
            Divider()
            
            HStack {
                Label(report.createdByName, systemImage: "person.crop.circle")
                    .font(.custom("IBMPlexSans", size: detailFontSize))
                    .foregroundColor(ColorPalette.labelPrimary.opacity(0.85))
                
                Spacer()
                
                Text(report.status.rawValue.capitalized)
                    .font(.custom("IBMPlexSans", size: badgeFontSize))
                    .fontWeight(.semibold)
                    .foregroundColor(ColorPalette.labelPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(ColorPalette.actionButtonBackground)
                    .clipShape(Capsule())
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ColorPalette.backgroundPrimary)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 6)
    }
}

#Preview {
    NavigationStack {
        FoundItemsListView()
    }
}


