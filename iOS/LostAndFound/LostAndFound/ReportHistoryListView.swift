//
//  ReportHistoryListView.swift
//  LostAndFound
//
//  Created by Craig Bakke on 12/07/25.
//

import SwiftUI

struct ReportHistoryListView: View {
    @ObservedObject var appState: AppState
    
    let currentUserEmail: String
    
    @State private var searchText: String = ""
    @State private var selectedCategory: ReportCategory?
    @FocusState private var isSearchFieldFocused: Bool
    @State private var reports: [Report] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private let reportService = ReportService()
    
    init(
        appState: AppState,
        currentUserEmail: String
    ) {
        self.appState = appState
        self.currentUserEmail = currentUserEmail
    }
    
    private var filteredReports: [Report] {
        reports
            .filter { report in
                let matchesCategory = selectedCategory == nil || report.category == selectedCategory
                
                guard !searchText.isEmpty else {
                    return matchesCategory
                }
                
                let normalizedQuery = searchText.lowercased()
                let searchableFields = [
                    report.title,
                    report.description ?? "",
                    report.locationBuilding
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
            
            let horizontalPadding = screenWidth * 0.055
            let verticalSpacing = max(screenHeight * 0.02, 16)
            let searchBarHeight = max(screenHeight * 0.06, 48)
            let filterControlHeight = max(screenHeight * 0.05, 44)
            
            ScrollView {
                VStack(alignment: .leading, spacing: verticalSpacing) {
                    searchField(height: searchBarHeight)
                    categoryFilter(height: filterControlHeight)
                    
                    if isLoading {
                        loadingView
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else if let errorMessage = errorMessage {
                        errorView(message: errorMessage)
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else if filteredReports.isEmpty {
                        emptyState
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        LazyVStack(spacing: verticalSpacing) {
                            ForEach(filteredReports) { report in
                                NavigationLink(value: report) {
                                    ReportHistoryCard(
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
                .padding(.bottom, verticalSpacing * 2)
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
        .navigationTitle("Report History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .toolbarBackground(ColorPalette.backgroundPrimary, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationDestination(for: Report.self) { report in
            ReportHistoryDetailView(report: report, appState: appState)
        }
        .task {
            await loadReports()
        }
        .refreshable {
            await loadReports()
        }
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
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(ColorPalette.labelPrimary.opacity(0.4))
            
            Text(reports.isEmpty ? "No reports yet" : "No matching reports")
                .font(.custom("IBMPlexSans", size: 20))
                .foregroundColor(ColorPalette.labelPrimary)
            
            Text(reports.isEmpty ? "Your submitted reports will appear here." : "Try adjusting your search or category filters.")
                .font(.custom("IBMPlexSans", size: 16))
                .foregroundColor(ColorPalette.labelPrimary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity)
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(.circular)
            
            Text("Loading your reports...")
                .font(.custom("IBMPlexSans", size: 18))
                .foregroundColor(ColorPalette.labelPrimary.opacity(0.7))
        }
        .padding(.vertical, 48)
        .frame(maxWidth: .infinity)
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.red.opacity(0.7))
            
            Text("Error Loading Reports")
                .font(.custom("IBMPlexSans", size: 20))
                .foregroundColor(ColorPalette.labelPrimary)
            
            Text(message)
                .font(.custom("IBMPlexSans", size: 16))
                .foregroundColor(ColorPalette.labelPrimary.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            Button {
                Task {
                    await loadReports()
                }
            } label: {
                Text("Try Again")
                    .font(.custom("IBMPlexSans", size: 16))
                    .foregroundColor(ColorPalette.witRichBlack)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [ColorPalette.witGold, ColorPalette.witGradient2],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity)
    }
    
    private func dismissKeyboard() {
        isSearchFieldFocused = false
    }
    
    private func loadReports() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedReports = try await reportService.fetchUserReports(userEmail: currentUserEmail)
            reports = fetchedReports
        } catch {
            errorMessage = error.localizedDescription
            #if DEBUG
            print("Error fetching reports: \(error)")
            #endif
        }
        
        isLoading = false
    }
}

private struct ReportHistoryCard: View {
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
                    .foregroundColor(ColorPalette.labelPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                Text(report.category.displayName)
                    .font(.custom("IBMPlexSans", size: badgeFontSize))
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
            
            // Type and Status Pills
            HStack(spacing: 8) {
                // Type pill
                Text(report.type == .lost ? "Lost" : "Found")
                    .font(.custom("IBMPlexSans", size: badgeFontSize))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(report.type == .lost ? Color.blue : Color.orange)
                    .clipShape(Capsule())
                
                // Status pill
                Text(statusDisplayText(for: report.status))
                    .font(.custom("IBMPlexSans", size: badgeFontSize))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(statusColor(for: report.status))
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

#Preview {
    NavigationStack {
        ReportHistoryListView(
            appState: AppState(),
            currentUserEmail: "user@wit.edu"
        )
    }
}

